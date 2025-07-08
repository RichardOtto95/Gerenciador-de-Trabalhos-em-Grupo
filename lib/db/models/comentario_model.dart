import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

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

  /// Converte um objeto Comentario em um Map para atualização (apenas campos editáveis)
  Map<String, dynamic> toMapForUpdate() {
    return {
      'id': id,
      'conteudo': conteudo,
    };
  }

  @override
  String toString() {
    return 'Comentario(id: $id, autorId: $autorId, tarefaId: $tarefaId, conteudo: "${conteudo.substring(0, conteudo.length > 20 ? 20 : conteudo.length)}...", editado: $editado)';
  }
}

/// Classe auxiliar para comentários com informações do autor
class ComentarioComAutor {
  final Comentario comentario;
  final Usuario autor;

  ComentarioComAutor({
    required this.comentario,
    required this.autor,
  });

  String get id => comentario.id;
  String get tarefaId => comentario.tarefaId;
  String get autorId => comentario.autorId;
  String get conteudo => comentario.conteudo;
  String? get comentarioPaiId => comentario.comentarioPaiId;
  DateTime get dataCriacao => comentario.dataCriacao;
  DateTime get dataAtualizacao => comentario.dataAtualizacao;
  bool get editado => comentario.editado;
  String get nomeAutor => autor.nome;
  
  // Útil para verificar se é uma resposta
  bool get isResposta => comentarioPaiId != null;
}

/// Classe para representar comentários com suas respostas organizadas hierarquicamente
class ComentarioHierarquico {
  final ComentarioComAutor comentario;
  final List<ComentarioHierarquico> respostas;

  ComentarioHierarquico({
    required this.comentario,
    this.respostas = const [],
  });

  // Getters para facilitar acesso
  String get id => comentario.id;
  String get tarefaId => comentario.tarefaId;
  String get autorId => comentario.autorId;
  String get conteudo => comentario.conteudo;
  String? get comentarioPaiId => comentario.comentarioPaiId;
  DateTime get dataCriacao => comentario.dataCriacao;
  DateTime get dataAtualizacao => comentario.dataAtualizacao;
  bool get editado => comentario.editado;
  String get nomeAutor => comentario.nomeAutor;
  bool get isResposta => comentario.isResposta;
  
  // Contador total de respostas (incluindo respostas das respostas)
  int get totalRespostas {
    int total = respostas.length;
    for (var resposta in respostas) {
      total += resposta.totalRespostas;
    }
    return total;
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
    await _connection.execute(Sql.named(query), parameters: comentario.toMap());
    print(
      'Comentário criado por ${comentario.autorId} na tarefa ${comentario.tarefaId}.',
    );
  }

  /// Retorna todos os comentários para uma tarefa específica.
  Future<List<Comentario>> getComentariosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM comentarios WHERE tarefa_id = @tarefa_id ORDER BY data_criacao ASC;'),
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
      Sql.named('SELECT * FROM comentarios WHERE id = @id;'),
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
    await _connection.execute(Sql.named(query), parameters: comentario.toMapForUpdate());
    print('Comentário com ID ${comentario.id} atualizado.');
  }

  /// Deleta um comentário pelo seu ID.
  Future<void> deleteComentario(String id) async {
    await _connection.execute(
      Sql.named('DELETE FROM comentarios WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Comentário com ID $id deletado.');
  }

  /// Retorna todos os comentários de uma tarefa com informações do autor
  Future<List<ComentarioComAutor>> getComentariosComAutorByTarefa(String tarefaId) async {
    final query = '''
      SELECT c.id, c.tarefa_id, c.autor_id, c.conteudo, c.comentario_pai_id, 
             c.data_criacao, c.data_atualizacao, c.editado,
             u.id as usuario_id, u.nome, u.email, u.senha_hash, u.foto_perfil, 
             u.bio, u.ativo, u.data_criacao as usuario_data_criacao, 
             u.data_atualizacao as usuario_data_atualizacao, u.ultimo_login
      FROM comentarios c
      INNER JOIN usuarios u ON c.autor_id = u.id
      WHERE c.tarefa_id = @tarefa_id
      ORDER BY c.data_criacao ASC;
    ''';
    
    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'tarefa_id': tarefaId},
    );
    
    return result.map((row) {
      final comentario = Comentario.fromMap({
        'id': row[0],
        'tarefa_id': row[1],
        'autor_id': row[2],
        'conteudo': row[3],
        'comentario_pai_id': row[4],
        'data_criacao': row[5],
        'data_atualizacao': row[6],
        'editado': row[7],
      });
      
      final autor = Usuario.fromMap({
        'id': row[8],
        'nome': row[9],
        'email': row[10],
        'senha_hash': row[11],
        'foto_perfil': row[12],
        'bio': row[13],
        'ativo': row[14],
        'data_criacao': row[15],
        'data_atualizacao': row[16],
        'ultimo_login': row[17],
      });
      
      return ComentarioComAutor(comentario: comentario, autor: autor);
    }).toList();
  }

  /// Organiza comentários em hierarquia (comentários principais com suas respostas)
  List<ComentarioHierarquico> organizarComentariosHierarquicos(List<ComentarioComAutor> comentarios) {
    // Separar comentários principais das respostas
    final comentariosPrincipais = comentarios.where((c) => c.comentarioPaiId == null).toList();
    final respostas = comentarios.where((c) => c.comentarioPaiId != null).toList();
    
    // Criar mapa para busca rápida de respostas por comentário pai
    final Map<String, List<ComentarioComAutor>> respostasPorPai = {};
    for (var resposta in respostas) {
      final paiId = resposta.comentarioPaiId!;
      if (!respostasPorPai.containsKey(paiId)) {
        respostasPorPai[paiId] = [];
      }
      respostasPorPai[paiId]!.add(resposta);
    }
    
    // Função recursiva para construir hierarquia
    List<ComentarioHierarquico> construirHierarquia(List<ComentarioComAutor> comentarios) {
      return comentarios.map((comentario) {
        final respostasDoComentario = respostasPorPai[comentario.id] ?? [];
        final respostasHierarquicas = construirHierarquia(respostasDoComentario);
        
        return ComentarioHierarquico(
          comentario: comentario,
          respostas: respostasHierarquicas,
        );
      }).toList();
    }
    
    return construirHierarquia(comentariosPrincipais);
  }
}
