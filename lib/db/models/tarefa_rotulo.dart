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
    await _connection.execute(query, parameters: tr.toMap());
    print('Rótulo ${tr.rotuloId} associado à tarefa ${tr.tarefaId}.');
  }

  /// Retorna todos os rótulos associados a uma tarefa.
  Future<List<TarefaRotulo>> getRotulosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      'SELECT * FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id;',
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
      'SELECT * FROM tarefas_rotulos WHERE rotulo_id = @rotulo_id;',
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
      'SELECT * FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id AND rotulo_id = @rotulo_id;',
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
      'DELETE FROM tarefas_rotulos WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Associação TarefaRotulo com ID $id deletada.');
  }

  /// Remove um rótulo específico de uma tarefa.
  Future<void> removeRotuloFromTarefa(String tarefaId, String rotuloId) async {
    await _connection.execute(
      'DELETE FROM tarefas_rotulos WHERE tarefa_id = @tarefa_id AND rotulo_id = @rotulo_id;',
      parameters: {'tarefa_id': tarefaId, 'rotulo_id': rotuloId},
    );
    print('Rótulo $rotuloId removido da tarefa $tarefaId.');
  }
}
