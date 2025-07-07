import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'notificacoes'.
class Notificacao {
  final String id;
  String usuarioId; // Usuário que recebe a notificação
  String
  tipo; // 'tarefa_atribuida', 'tarefa_vencendo', 'comentario_adicionado', etc.
  String titulo;
  String mensagem;
  String?
  entidadeTipo; // Tipo da entidade relacionada (e.g., 'tarefa', 'grupo')
  String? entidadeId; // ID da entidade relacionada
  bool lida;
  DateTime dataCriacao;
  DateTime? dataLeitura;

  Notificacao({
    String? id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.entidadeTipo,
    this.entidadeId,
    this.lida = false, // Valor padrão conforme o script SQL
    DateTime? dataCriacao,
    this.dataLeitura,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto Notificacao.
  factory Notificacao.fromMap(Map<String, dynamic> map) {
    return Notificacao(
      id: map['id'],
      usuarioId: map['usuario_id'],
      tipo: map['tipo'],
      titulo: map['titulo'],
      mensagem: map['mensagem'],
      entidadeTipo: map['entidade_tipo'],
      entidadeId: map['entidade_id'],
      lida: map['lida'],
      dataCriacao: (map['data_criacao'] as DateTime),
      dataLeitura: (map['data_leitura'] as DateTime?),
    );
  }

  /// Converte um objeto Notificacao em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'tipo': tipo,
      'titulo': titulo,
      'mensagem': mensagem,
      'entidade_tipo': entidadeTipo,
      'entidade_id': entidadeId,
      'lida': lida,
      'data_criacao': dataCriacao,
      'data_leitura': dataLeitura,
    };
  }

  @override
  String toString() {
    return 'Notificacao(id: $id, tipo: $tipo, usuarioId: $usuarioId, lida: $lida, titulo: $titulo)';
  }
}

/// Repositório para operações CRUD na tabela 'notificacoes'.
class NotificacaoRepository {
  final Connection _connection;

  NotificacaoRepository() : _connection = DatabaseHelper().connection;

  /// Cria uma nova notificação no banco de dados.
  Future<void> createNotificacao(Notificacao notificacao) async {
    final query = '''
      INSERT INTO notificacoes (id, usuario_id, tipo, titulo, mensagem, entidade_tipo, entidade_id, lida, data_criacao, data_leitura)
      VALUES (@id, @usuario_id, @tipo, @titulo, @mensagem, @entidade_tipo, @entidade_id, @lida, @data_criacao, @data_leitura);
    ''';
    await _connection.execute(query, parameters: notificacao.toMap());
    print('Notificação criada para o usuário ${notificacao.usuarioId}.');
  }

  /// Retorna todas as notificações de um usuário.
  Future<List<Notificacao>> getNotificacoesByUsuario(
    String usuarioId, {
    bool? lida,
  }) async {
    String whereClause = 'WHERE usuario_id = @usuario_id';
    Map<String, dynamic> params = {'usuario_id': usuarioId};
    if (lida != null) {
      whereClause += ' AND lida = @lida';
      params['lida'] = lida;
    }
    final result = await _connection.execute(
      'SELECT * FROM notificacoes $whereClause ORDER BY data_criacao DESC;',
      parameters: params,
    );
    return result
        .map(
          (row) => Notificacao.fromMap({
            'id': row[0],
            'usuario_id': row[1],
            'tipo': row[2],
            'titulo': row[3],
            'mensagem': row[4],
            'entidade_tipo': row[5],
            'entidade_id': row[6],
            'lida': row[7],
            'data_criacao': row[8],
            'data_leitura': row[9],
          }),
        )
        .toList();
  }

  /// Retorna uma notificação pelo seu ID.
  Future<Notificacao?> getNotificacaoById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM notificacoes WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Notificacao.fromMap({
        'id': row[0],
        'usuario_id': row[1],
        'tipo': row[2],
        'titulo': row[3],
        'mensagem': row[4],
        'entidade_tipo': row[5],
        'entidade_id': row[6],
        'lida': row[7],
        'data_criacao': row[8],
        'data_leitura': row[9],
      });
    }
    return null;
  }

  /// Atualiza as informações de uma notificação existente.
  Future<void> updateNotificacao(Notificacao notificacao) async {
    final query = '''
      UPDATE notificacoes
      SET usuario_id = @usuario_id, tipo = @tipo, titulo = @titulo, mensagem = @mensagem, 
          entidade_tipo = @entidade_tipo, entidade_id = @entidade_id, lida = @lida, 
          data_leitura = @data_leitura
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: notificacao.toMap());
    print('Notificação com ID ${notificacao.id} atualizada.');
  }

  /// Marca uma notificação como lida.
  Future<void> markNotificacaoAsRead(String id) async {
    final query = '''
      UPDATE notificacoes
      SET lida = TRUE, data_leitura = CURRENT_TIMESTAMP
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: {'id': id});
    print('Notificação com ID $id marcada como lida.');
  }

  /// Deleta uma notificação pelo seu ID.
  Future<void> deleteNotificacao(String id) async {
    await _connection.execute(
      'DELETE FROM notificacoes WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Notificação com ID $id deletada.');
  }
}
