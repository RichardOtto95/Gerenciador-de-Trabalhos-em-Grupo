import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'comentarios'.
class Comentario {
  final String id;
  String tarefaId; // Chave estrangeira para tarefas(id)
  String autorId; // Chave estrangeira para usuarios(id)
  String conteudo;
  String?
  comentarioPaiId; // Para respostas, chave estrangeira para comentarios(id)
  DateTime dataCriacao;
  DateTime dataAtualizacao; // Campo adicionado: data_atualizacao
  bool editado; // Campo adicionado: editado

  Comentario({
    String? id,
    required this.tarefaId,
    required this.autorId,
    required this.conteudo,
    this.comentarioPaiId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    this.editado = false, // Valor padrão conforme o script SQL
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now(),
       dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto Comentario.
  factory Comentario.fromMap(Map<String, dynamic> map) {
    return Comentario(
      id: map['id'],
      tarefaId: map['tarefa_id'],
      autorId: map['autor_id'],
      conteudo: map['conteudo'],
      comentarioPaiId: map['comentario_pai_id'],
      dataCriacao: (map['data_criacao'] as DateTime),
      dataAtualizacao: (map['data_atualizacao'] as DateTime),
      editado: map['editado'],
    );
  }

  /// Converte um objeto Comentario em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarefa_id': tarefaId,
      'autor_id': autorId,
      'conteudo': conteudo,
      'comentario_pai_id': comentarioPaiId,
      'data_criacao': dataCriacao,
      'data_atualizacao': dataAtualizacao,
      'editado': editado,
    };
  }

  @override
  String toString() {
    return 'Comentario(id: $id, autorId: $autorId, tarefaId: $tarefaId, conteudo: "${conteudo.substring(0, conteudo.length > 20 ? 20 : conteudo.length)}...", editado: $editado)';
  }
}

/// Repositório para operações CRUD na tabela 'comentarios'.
class ComentarioRepository {
  final Connection _connection;

  ComentarioRepository() : _connection = DatabaseHelper().connection;

  /// Cria um novo comentário no banco de dados.
  Future<void> createComentario(Comentario comentario) async {
    final query = '''
      INSERT INTO comentarios (id, tarefa_id, autor_id, conteudo, comentario_pai_id, data_criacao, data_atualizacao, editado)
      VALUES (@id, @tarefa_id, @autor_id, @conteudo, @comentario_pai_id, @data_criacao, @data_atualizacao, @editado);
    ''';
    await _connection.execute(query, parameters: comentario.toMap());
    print(
      'Comentário criado por ${comentario.autorId} na tarefa ${comentario.tarefaId}.',
    );
  }

  /// Retorna todos os comentários para uma tarefa específica.
  Future<List<Comentario>> getComentariosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      'SELECT * FROM comentarios WHERE tarefa_id = @tarefa_id ORDER BY data_criacao ASC;',
      parameters: {'tarefa_id': tarefaId},
    );
    return result
        .map(
          (row) => Comentario.fromMap({
            'id': row[0],
            'tarefa_id': row[1],
            'autor_id': row[2],
            'conteudo': row[3],
            'comentario_pai_id': row[4],
            'data_criacao': row[5],
            'data_atualizacao': row[6],
            'editado': row[7],
          }),
        )
        .toList();
  }

  /// Retorna um comentário pelo seu ID.
  Future<Comentario?> getComentarioById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM comentarios WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Comentario.fromMap({
        'id': row[0],
        'tarefa_id': row[1],
        'autor_id': row[2],
        'conteudo': row[3],
        'comentario_pai_id': row[4],
        'data_criacao': row[5],
        'data_atualizacao': row[6],
        'editado': row[7],
      });
    }
    return null;
  }

  /// Atualiza o conteúdo de um comentário existente.
  Future<void> updateComentario(Comentario comentario) async {
    final query = '''
      UPDATE comentarios
      SET conteudo = @conteudo, data_atualizacao = CURRENT_TIMESTAMP, editado = TRUE
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: comentario.toMap());
    print('Comentário com ID ${comentario.id} atualizado.');
  }

  /// Deleta um comentário pelo seu ID.
  Future<void> deleteComentario(String id) async {
    await _connection.execute(
      'DELETE FROM comentarios WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Comentário com ID $id deletado.');
  }
}
