import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'atribuicoes_tarefa'.
class AtribuicaoTarefa {
  final String id;
  String tarefaId;
  String usuarioId;
  String atribuidoPor; // Usuário que fez a atribuição
  DateTime dataAtribuicao;
  bool ativo;

  AtribuicaoTarefa({
    String? id,
    required this.tarefaId,
    required this.usuarioId,
    required this.atribuidoPor,
    DateTime? dataAtribuicao,
    this.ativo = true, // Valor padrão conforme o script SQL
  }) : id = id ?? const Uuid().v4(),
       dataAtribuicao = dataAtribuicao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto AtribuicaoTarefa.
  factory AtribuicaoTarefa.fromMap(Map<String, dynamic> map) {
    return AtribuicaoTarefa(
      id: map['id'],
      tarefaId: map['tarefa_id'],
      usuarioId: map['usuario_id'],
      atribuidoPor: map['atribuido_por'],
      dataAtribuicao: (map['data_atribuicao'] as DateTime),
      ativo: map['ativo'],
    );
  }

  /// Converte um objeto AtribuicaoTarefa em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarefa_id': tarefaId,
      'usuario_id': usuarioId,
      'atribuido_por': atribuidoPor,
      'data_atribuicao': dataAtribuicao,
      'ativo': ativo,
    };
  }

  @override
  String toString() {
    return 'AtribuicaoTarefa(id: $id, tarefaId: $tarefaId, usuarioId: $usuarioId, ativo: $ativo)';
  }
}

/// Repositório para operações CRUD na tabela 'atribuicoes_tarefa'.
class AtribuicaoTarefaRepository {
  final Connection _connection;

  AtribuicaoTarefaRepository() : _connection = DatabaseHelper().connection;

  /// Cria uma nova atribuição de tarefa.
  Future<void> createAtribuicaoTarefa(AtribuicaoTarefa atribuicao) async {
    final query = '''
      INSERT INTO atribuicoes_tarefa (id, tarefa_id, usuario_id, atribuido_por, data_atribuicao, ativo)
      VALUES (@id, @tarefa_id, @usuario_id, @atribuido_por, @data_atribuicao, @ativo);
    ''';
    await _connection.execute(query, parameters: atribuicao.toMap());
    print('Tarefa ${atribuicao.tarefaId} atribuída a ${atribuicao.usuarioId}.');
  }

  /// Retorna todas as atribuições para uma tarefa específica.
  Future<List<AtribuicaoTarefa>> getAtribuicoesByTarefa(
    String tarefaId, {
    bool? ativo,
  }) async {
    String query =
        'SELECT * FROM atribuicoes_tarefa WHERE tarefa_id = @tarefa_id';
    Map<String, dynamic> params = {'tarefa_id': tarefaId};
    if (ativo != null) {
      query += ' AND ativo = @ativo';
      params['ativo'] = ativo;
    }
    final result = await _connection.execute(query, parameters: params);
    return result
        .map(
          (row) => AtribuicaoTarefa.fromMap({
            'id': row[0],
            'tarefa_id': row[1],
            'usuario_id': row[2],
            'atribuido_por': row[3],
            'data_atribuicao': row[4],
            'ativo': row[5],
          }),
        )
        .toList();
  }

  /// Retorna todas as tarefas atribuídas a um usuário específico.
  Future<List<AtribuicaoTarefa>> getAtribuicoesByUsuario(
    String usuarioId, {
    bool? ativo,
  }) async {
    String query =
        'SELECT * FROM atribuicoes_tarefa WHERE usuario_id = @usuario_id';
    Map<String, dynamic> params = {'usuario_id': usuarioId};
    if (ativo != null) {
      query += ' AND ativo = @ativo';
      params['ativo'] = ativo;
    }
    final result = await _connection.execute(query, parameters: params);
    return result
        .map(
          (row) => AtribuicaoTarefa.fromMap({
            'id': row[0],
            'tarefa_id': row[1],
            'usuario_id': row[2],
            'atribuido_por': row[3],
            'data_atribuicao': row[4],
            'ativo': row[5],
          }),
        )
        .toList();
  }

  /// Retorna uma atribuição de tarefa pelo seu ID.
  Future<AtribuicaoTarefa?> getAtribuicaoById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM atribuicoes_tarefa WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return AtribuicaoTarefa.fromMap({
        'id': row[0],
        'tarefa_id': row[1],
        'usuario_id': row[2],
        'atribuido_por': row[3],
        'data_atribuicao': row[4],
        'ativo': row[5],
      });
    }
    return null;
  }

  /// Atualiza o status de ativo de uma atribuição.
  Future<void> updateAtribuicaoTarefa(AtribuicaoTarefa atribuicao) async {
    final query = '''
      UPDATE atribuicoes_tarefa
      SET tarefa_id = @tarefa_id, usuario_id = @usuario_id, atribuido_por = @atribuido_por, ativo = @ativo
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: atribuicao.toMap());
    print('Atribuição com ID ${atribuicao.id} atualizada.');
  }

  /// Deleta uma atribuição de tarefa pelo seu ID.
  Future<void> deleteAtribuicaoTarefa(String id) async {
    await _connection.execute(
      'DELETE FROM atribuicoes_tarefa WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Atribuição com ID $id deletada.');
  }

  /// Desativa uma atribuição específica entre tarefa e usuário.
  Future<void> deactivateAtribuicao(String tarefaId, String usuarioId) async {
    final query = '''
      UPDATE atribuicoes_tarefa
      SET ativo = FALSE
      WHERE tarefa_id = @tarefa_id AND usuario_id = @usuario_id AND ativo = TRUE;
    ''';
    await _connection.execute(
      query,
      parameters: {'tarefa_id': tarefaId, 'usuario_id': usuarioId},
    );
    print(
      'Atribuição para a tarefa $tarefaId e usuário $usuarioId desativada.',
    );
  }
}
