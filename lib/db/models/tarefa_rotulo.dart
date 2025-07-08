import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela de relacionamento 'tarefas_rotulos'.
class TarefaRotulo {
  final String id;
  String tarefaId;
  String rotuloId;

  TarefaRotulo({String? id, required this.tarefaId, required this.rotuloId})
    : id = id ?? const Uuid().v4();

  /// Converte uma linha do banco de dados (Map) em um objeto TarefaRotulo.
  factory TarefaRotulo.fromMap(Map<String, dynamic> map) {
    return TarefaRotulo(
      id: map['id'],
      tarefaId: map['tarefa_id'],
      rotuloId: map['rotulo_id'],
    );
  }

  /// Converte um objeto TarefaRotulo em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {'id': id, 'tarefa_id': tarefaId, 'rotulo_id': rotuloId};
  }

  @override
  String toString() {
    return 'TarefaRotulo(id: $id, tarefaId: $tarefaId, rotuloId: $rotuloId)';
  }
}

/// Repositório para operações CRUD na tabela 'tarefas_rotulos'.
class TarefaRotuloRepository {
  final Connection _connection;

  TarefaRotuloRepository() : _connection = DatabaseHelper().connection;

  /// Associa um rótulo a uma tarefa.
  Future<void> createTarefaRotulo(TarefaRotulo tr) async {
    final query = '''
      INSERT INTO tarefas_rotulos (id, tarefa_id, rotulo_id)
      VALUES (@id, @tarefa_id, @rotulo_id);
    ''';
    await _connection.execute(Sql.named(query), parameters: tr.toMap());
    print('Rótulo ${tr.rotuloId} associado à tarefa ${tr.tarefaId}.');
  }

  /// Retorna todos os rótulos associados a uma tarefa.
  Future<List<TarefaRotulo>> getRotulosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id;'),
      parameters: {'tarefa_id': tarefaId},
    );
    return result
        .map(
          (row) => TarefaRotulo.fromMap({
            'id': row[0],
            'tarefa_id': row[1],
            'rotulo_id': row[2],
          }),
        )
        .toList();
  }

  /// Retorna todas as tarefas associadas a um rótulo.
  Future<List<TarefaRotulo>> getTarefasByRotulo(String rotuloId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM tarefas_rotulos WHERE rotulo_id = @rotulo_id;'),
      parameters: {'rotulo_id': rotuloId},
    );
    return result
        .map(
          (row) => TarefaRotulo.fromMap({
            'id': row[0],
            'tarefa_id': row[1],
            'rotulo_id': row[2],
          }),
        )
        .toList();
  }

  /// Retorna uma associação específica entre tarefa e rótulo.
  Future<TarefaRotulo?> getTarefaRotulo(
    String tarefaId,
    String rotuloId,
  ) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id AND rotulo_id = @rotulo_id;'),
      parameters: {'tarefa_id': tarefaId, 'rotulo_id': rotuloId},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return TarefaRotulo.fromMap({
        'id': row[0],
        'tarefa_id': row[1],
        'rotulo_id': row[2],
      });
    }
    return null;
  }

  /// Remove uma associação de rótulo de uma tarefa pelo seu ID.
  Future<void> deleteTarefaRotulo(String id) async {
    await _connection.execute(
      Sql.named('DELETE FROM tarefas_rotulos WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Associação TarefaRotulo com ID $id deletada.');
  }

  /// Remove um rótulo específico de uma tarefa.
  Future<void> removeRotuloFromTarefa(String tarefaId, String rotuloId) async {
    await _connection.execute(
      Sql.named('DELETE FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id AND rotulo_id = @rotulo_id;'),
      parameters: {'tarefa_id': tarefaId, 'rotulo_id': rotuloId},
    );
    print('Rótulo $rotuloId removido da tarefa $tarefaId.');
  }

  /// Obtém rótulos completos de uma tarefa (com detalhes do rótulo)
  Future<List<Map<String, dynamic>>> getRotulosCompletosFromTarefa(String tarefaId) async {
    final query = '''
      SELECT 
        r.id,
        r.nome,
        r.descricao,
        r.cor
      FROM rotulos r
      INNER JOIN tarefas_rotulos tr ON r.id = tr.rotulo_id
      WHERE tr.tarefa_id = @tarefa_id
      ORDER BY r.nome;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'tarefa_id': tarefaId},
    );

    return result.map((row) => {
      'id': row[0],
      'nome': row[1],
      'descricao': row[2],
      'cor': row[3],
    }).toList();
  }

  /// Aplica múltiplos rótulos a uma tarefa
  Future<void> aplicarRotulosNaTarefa(String tarefaId, List<String> rotulosIds) async {
    if (rotulosIds.isEmpty) return;

    // Primeiro remove todos os rótulos existentes
    await _connection.execute(
      Sql.named('DELETE FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id;'),
      parameters: {'tarefa_id': tarefaId},
    );

    // Depois adiciona os novos rótulos
    for (final rotuloId in rotulosIds) {
      final tr = TarefaRotulo(tarefaId: tarefaId, rotuloId: rotuloId);
      await createTarefaRotulo(tr);
    }
  }

  /// Verifica se uma tarefa já tem um rótulo específico
  Future<bool> tarefaTemRotulo(String tarefaId, String rotuloId) async {
    final result = await _connection.execute(
      Sql.named('SELECT COUNT(*) FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id AND rotulo_id = @rotulo_id;'),
      parameters: {'tarefa_id': tarefaId, 'rotulo_id': rotuloId},
    );
    return (result.first[0] as int) > 0;
  }

  /// Remove todos os rótulos de uma tarefa
  Future<void> removerTodosRotulosDaTarefa(String tarefaId) async {
    await _connection.execute(
      Sql.named('DELETE FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id;'),
      parameters: {'tarefa_id': tarefaId},
    );
    print('Todos os rótulos removidos da tarefa $tarefaId.');
  }

  /// Remove todas as associações de um rótulo (quando rótulo é deletado)
  Future<void> removerTodasAssociacoesDoRotulo(String rotuloId) async {
    await _connection.execute(
      Sql.named('DELETE FROM tarefas_rotulos WHERE rotulo_id = @rotulo_id;'),
      parameters: {'rotulo_id': rotuloId},
    );
    print('Todas as associações do rótulo $rotuloId foram removidas.');
  }

  /// Obtém contagem de tarefas por rótulo em um grupo
  Future<Map<String, int>> getContagemTarefasPorRotulo(String grupoId) async {
    final query = '''
      SELECT 
        r.id,
        r.nome,
        COUNT(tr.id) as quantidade
      FROM rotulos r
      LEFT JOIN tarefas_rotulos tr ON r.id = tr.rotulo_id
      LEFT JOIN tarefas t ON tr.tarefa_id = t.id
      WHERE r.grupo_id = @grupo_id
      GROUP BY r.id, r.nome
      ORDER BY quantidade DESC, r.nome;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'grupo_id': grupoId},
    );

    final contagem = <String, int>{};
    for (final row in result) {
      final nome = row[1] as String;
      final quantidade = row[2] as int;
      contagem[nome] = quantidade;
    }

    return contagem;
  }
}
