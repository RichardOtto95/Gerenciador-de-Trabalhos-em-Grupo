import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

class Atividade {
  final String id;
  String tipoEntidade; // e.g., 'usuario', 'tarefa', 'grupo'
  String entidadeId; // ID of the entity (user, task, group, etc.)
  String usuarioId; // User who performed the activity
  String acao; // e.g., 'created', 'updated', 'deleted', 'commented'
  String? detalhes;
  String? ipAddress;
  String? userAgent;
  DateTime dataCriacao;
  String? etapa; // For tracking a specific stage of an activity/workflow

  Atividade({
    String? id,
    required this.tipoEntidade,
    required this.entidadeId,
    required this.usuarioId,
    required this.acao,
    this.detalhes,
    this.ipAddress,
    this.userAgent,
    DateTime? dataCriacao,
    this.etapa,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now();

  factory Atividade.fromMap(Map<String, dynamic> map) {
    return Atividade(
      id: map['id'],
      tipoEntidade: map['tipo_entidade'],
      entidadeId: map['entidade_id'],
      usuarioId: map['usuario_id'],
      acao: map['acao'],
      detalhes: map['detalhes'],
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
      dataCriacao: (map['data_criacao'] as DateTime),
      etapa: map['etapa'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo_entidade': tipoEntidade,
      'entidade_id': entidadeId,
      'usuario_id': usuarioId,
      'acao': acao,
      'detalhes': detalhes,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'data_criacao': dataCriacao,
      'etapa': etapa,
    };
  }

  @override
  String toString() {
    return 'Atividade(id: $id, acao: $acao, usuarioId: $usuarioId, entidadeId: $entidadeId)';
  }
}

class AtividadeRepository {
  final Connection _connection;

  AtividadeRepository() : _connection = DatabaseHelper().connection;

  Future<void> createAtividade(Atividade atividade) async {
    final query = '''
      INSERT INTO atividades (id, tipo_entidade, entidade_id, usuario_id, acao, detalhes, ip_address, user_agent, data_criacao, etapa)
      VALUES (@id, @tipo_entidade, @entidade_id, @usuario_id, @acao, @detalhes, @ip_address, @user_agent, @data_criacao, @etapa);
    ''';
    await _connection.execute(query, parameters: atividade.toMap());
    print(
      'Atividade "${atividade.acao}" created for entity ${atividade.entidadeId}.',
    );
  }

  Future<List<Atividade>> getAllAtividades() async {
    final result = await _connection.execute('SELECT * FROM atividades;');
    return result
        .map(
          (row) => Atividade.fromMap({
            'id': row[0],
            'tipo_entidade': row[1],
            'entidade_id': row[2],
            'usuario_id': row[3],
            'acao': row[4],
            'detalhes': row[5],
            'ip_address': row[6],
            'user_agent': row[7],
            'data_criacao': row[8],
            'etapa': row[9],
          }),
        )
        .toList();
  }

  Future<List<Atividade>> getAtividadesByEntidade(
    String entidadeId,
    String tipoEntidade,
  ) async {
    final result = await _connection.execute(
      'SELECT * FROM atividades WHERE entidade_id = @entidade_id AND tipo_entidade = @tipo_entidade;',
      parameters: {'entidade_id': entidadeId, 'tipo_entidade': tipoEntidade},
    );
    return result
        .map(
          (row) => Atividade.fromMap({
            'id': row[0],
            'tipo_entidade': row[1],
            'entidade_id': row[2],
            'usuario_id': row[3],
            'acao': row[4],
            'detalhes': row[5],
            'ip_address': row[6],
            'user_agent': row[7],
            'data_criacao': row[8],
            'etapa': row[9],
          }),
        )
        .toList();
  }

  Future<Atividade?> getAtividadeById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM atividades WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Atividade.fromMap({
        'id': row[0],
        'tipo_entidade': row[1],
        'entidade_id': row[2],
        'usuario_id': row[3],
        'acao': row[4],
        'detalhes': row[5],
        'ip_address': row[6],
        'user_agent': row[7],
        'data_criacao': row[8],
        'etapa': row[9],
      });
    }
    return null;
  }

  // Activities are usually immutable records, so update and delete might not be common.
  // However, if your business logic requires it, you can implement them.
  // For demonstration, I'll provide an update, but delete is often avoided for audit logs.
  Future<void> updateAtividade(Atividade atividade) async {
    final query = '''
      UPDATE atividades
      SET tipo_entidade = @tipo_entidade, entidade_id = @entidade_id, usuario_id = @usuario_id,
          acao = @acao, detalhes = @detalhes, ip_address = @ip_address, user_agent = @user_agent,
          etapa = @etapa
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: atividade.toMap());
    print('Atividade with ID ${atividade.id} updated.');
  }

  // Deleting activities might not be desirable for audit purposes.
  // Implement with caution or restrict permissions.
  Future<void> deleteAtividade(String id) async {
    await _connection.execute(
      'DELETE FROM atividades WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Atividade with ID $id deleted (if permitted).');
  }
}
