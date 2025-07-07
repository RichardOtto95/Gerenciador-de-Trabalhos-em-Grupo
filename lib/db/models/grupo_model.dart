import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'grupos'.
class Grupo {
  final String id;
  String nome;
  String? descricao; // Pode ser nulo
  String corTema;
  String criadorId; // Chave estrangeira para usuarios(id)
  bool publico;
  int maxMembros;
  DateTime dataCriacao;
  DateTime dataAtualizacao; // Campo adicionado: data_atualizacao

  Grupo({
    String? id,
    required this.nome,
    this.descricao,
    this.corTema = '#007bff', // Valor padrão conforme o script SQL
    required this.criadorId,
    this.publico = false, // Valor padrão conforme o script SQL
    this.maxMembros = 50, // Valor padrão conforme o script SQL
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now(),
       dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto Grupo.
  factory Grupo.fromMap(Map<String, dynamic> map) {
    return Grupo(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      corTema: map['cor_tema'],
      criadorId: map['criador_id'],
      publico: map['publico'],
      maxMembros: map['max_membros'],
      dataCriacao: (map['data_criacao'] as DateTime),
      dataAtualizacao: (map['data_atualizacao'] as DateTime),
    );
  }

  /// Converte um objeto Grupo em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'cor_tema': corTema,
      'criador_id': criadorId,
      'publico': publico,
      'max_membros': maxMembros,
      'data_criacao': dataCriacao,
      'data_atualizacao': dataAtualizacao,
    };
  }

  @override
  String toString() {
    return 'Grupo(id: $id, nome: $nome, criadorId: $criadorId, publico: $publico)';
  }
}

/// Repositório para operações CRUD na tabela 'grupos'.
class GrupoRepository {
  final Connection _connection;

  GrupoRepository() : _connection = DatabaseHelper().connection;

  /// Cria um novo grupo no banco de dados.
  Future<void> createGrupo(Grupo grupo) async {
    final query = '''
      INSERT INTO grupos (id, nome, descricao, cor_tema, criador_id, publico, max_membros, data_criacao, data_atualizacao)
      VALUES (@id, @nome, @descricao, @cor_tema, @criador_id, @publico, @max_membros, @data_criacao, @data_atualizacao);
    ''';
    await _connection.execute(Sql.named(query), parameters: grupo.toMap());
    print('Grupo "${grupo.nome}" criado.');
  }

  /// Retorna todos os grupos do banco de dados.
  Future<List<Grupo>> getAllGrupos() async {
    final result = await _connection.execute('SELECT * FROM grupos;');
    return result
        .map(
          (row) => Grupo.fromMap({
            'id': row[0],
            'nome': row[1],
            'descricao': row[2],
            'cor_tema': row[3],
            'criador_id': row[4],
            'publico': row[5],
            'max_membros': row[6],
            'data_criacao': row[7],
            'data_atualizacao': row[8],
          }),
        )
        .toList();
  }

  /// Retorna um grupo pelo seu ID.
  Future<Grupo?> getGrupoById(String id) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM grupos WHERE id = @id;'),
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Grupo.fromMap({
        'id': row[0],
        'nome': row[1],
        'descricao': row[2],
        'cor_tema': row[3],
        'criador_id': row[4],
        'publico': row[5],
        'max_membros': row[6],
        'data_criacao': row[7],
        'data_atualizacao': row[8],
      });
    }
    return null;
  }

  /// Atualiza as informações de um grupo existente.
  Future<void> updateGrupo(Grupo grupo) async {
    final query = '''
      UPDATE grupos
      SET nome = @nome, descricao = @descricao, cor_tema = @cor_tema, 
          criador_id = @criador_id, publico = @publico, max_membros = @max_membros, 
          data_atualizacao = CURRENT_TIMESTAMP
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: grupo.toMap());
    print('Grupo "${grupo.nome}" atualizado.');
  }

  /// Deleta um grupo pelo seu ID.
  Future<void> deleteGrupo(String id) async {
    await _connection.execute(
      'DELETE FROM grupos WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Grupo com ID $id deletado.');
  }
}
