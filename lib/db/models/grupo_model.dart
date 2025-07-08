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

/// Modelo composto para grupos com informações do usuário
class GrupoComInfo {
  final Grupo grupo;
  final String papelUsuario; // Papel do usuário no grupo (admin, moderador, membro)
  final int totalMembros; // Total de membros no grupo
  final DateTime dataEntrada; // Data que o usuário entrou no grupo

  GrupoComInfo({
    required this.grupo,
    required this.papelUsuario,
    required this.totalMembros,
    required this.dataEntrada,
  });

  factory GrupoComInfo.fromMap(Map<String, dynamic> map) {
    return GrupoComInfo(
      grupo: Grupo.fromMap({
        'id': map['grupo_id'],
        'nome': map['grupo_nome'],
        'descricao': map['grupo_descricao'],
        'cor_tema': map['grupo_cor_tema'],
        'criador_id': map['grupo_criador_id'],
        'publico': map['grupo_publico'],
        'max_membros': map['grupo_max_membros'],
        'data_criacao': map['grupo_data_criacao'],
        'data_atualizacao': map['grupo_data_atualizacao'],
      }),
      papelUsuario: map['papel_usuario'],
      totalMembros: map['total_membros'],
      dataEntrada: map['data_entrada'],
    );
  }

  @override
  String toString() {
    return 'GrupoComInfo(grupo: ${grupo.nome}, papel: $papelUsuario, membros: $totalMembros)';
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

  /// Verifica se o usuário já possui um grupo com o mesmo nome
  Future<bool> hasGroupWithSameName(String criadorId, String nome) async {
    final result = await _connection.execute(
      Sql.named('SELECT COUNT(*) FROM grupos WHERE criador_id = @criador_id AND nome = @nome;'),
      parameters: {'criador_id': criadorId, 'nome': nome},
    );
    return (result.first[0] as int) > 0;
  }

  /// Retorna todos os grupos criados por um usuário específico
  Future<List<Grupo>> getGruposByCriador(String criadorId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM grupos WHERE criador_id = @criador_id ORDER BY data_criacao DESC;'),
      parameters: {'criador_id': criadorId},
    );
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

  /// Atualiza as informações de um grupo existente.
  Future<void> updateGrupo(Grupo grupo) async {
    final query = '''
      UPDATE grupos
      SET nome = @nome, descricao = @descricao, cor_tema = @cor_tema, 
          criador_id = @criador_id, publico = @publico, max_membros = @max_membros, 
          data_atualizacao = CURRENT_TIMESTAMP
      WHERE id = @id;
    ''';
    await _connection.execute(Sql.named(query), parameters: grupo.toMap());
    print('Grupo "${grupo.nome}" atualizado.');
  }

  /// Deleta um grupo pelo seu ID.
  Future<void> deleteGrupo(String id) async {
    await _connection.execute(
      Sql.named('DELETE FROM grupos WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Grupo com ID $id deletado.');
  }

  /// Retorna todos os grupos que um usuário participa com informações detalhadas
  Future<List<GrupoComInfo>> getGruposDoUsuario(String usuarioId, {String? filtrarPorPapel}) async {
    String whereClause = 'WHERE ug.usuario_id = @usuario_id AND ug.ativo = true';
    Map<String, dynamic> params = {'usuario_id': usuarioId};
    
    if (filtrarPorPapel != null) {
      whereClause += ' AND ug.papel = @papel';
      params['papel'] = filtrarPorPapel;
    }

    final query = '''
      SELECT 
        g.id as grupo_id,
        g.nome as grupo_nome,
        g.descricao as grupo_descricao,
        g.cor_tema as grupo_cor_tema,
        g.criador_id as grupo_criador_id,
        g.publico as grupo_publico,
        g.max_membros as grupo_max_membros,
        g.data_criacao as grupo_data_criacao,
        g.data_atualizacao as grupo_data_atualizacao,
        ug.papel as papel_usuario,
        ug.data_entrada as data_entrada,
        (
          SELECT COUNT(*) 
          FROM usuarios_grupos ug2 
          WHERE ug2.grupo_id = g.id AND ug2.ativo = true
        ) as total_membros
      FROM grupos g
      INNER JOIN usuarios_grupos ug ON g.id = ug.grupo_id
      $whereClause
      ORDER BY ug.data_entrada DESC;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: params,
    );

    return result.map((row) => GrupoComInfo.fromMap({
      'grupo_id': row[0],
      'grupo_nome': row[1],
      'grupo_descricao': row[2],
      'grupo_cor_tema': row[3],
      'grupo_criador_id': row[4],
      'grupo_publico': row[5],
      'grupo_max_membros': row[6],
      'grupo_data_criacao': row[7],
      'grupo_data_atualizacao': row[8],
      'papel_usuario': row[9],
      'data_entrada': row[10],
      'total_membros': row[11],
    })).toList();
  }

  /// Busca grupos por nome (para o usuário específico)
  Future<List<GrupoComInfo>> buscarGruposDoUsuario(String usuarioId, String termoBusca) async {
    final query = '''
      SELECT 
        g.id as grupo_id,
        g.nome as grupo_nome,
        g.descricao as grupo_descricao,
        g.cor_tema as grupo_cor_tema,
        g.criador_id as grupo_criador_id,
        g.publico as grupo_publico,
        g.max_membros as grupo_max_membros,
        g.data_criacao as grupo_data_criacao,
        g.data_atualizacao as grupo_data_atualizacao,
        ug.papel as papel_usuario,
        ug.data_entrada as data_entrada,
        (
          SELECT COUNT(*) 
          FROM usuarios_grupos ug2 
          WHERE ug2.grupo_id = g.id AND ug2.ativo = true
        ) as total_membros
      FROM grupos g
      INNER JOIN usuarios_grupos ug ON g.id = ug.grupo_id
      WHERE ug.usuario_id = @usuario_id 
        AND ug.ativo = true
        AND (LOWER(g.nome) LIKE LOWER(@termo) OR LOWER(g.descricao) LIKE LOWER(@termo))
      ORDER BY g.nome ASC;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {
        'usuario_id': usuarioId,
        'termo': '%$termoBusca%',
      },
    );

    return result.map((row) => GrupoComInfo.fromMap({
      'grupo_id': row[0],
      'grupo_nome': row[1],
      'grupo_descricao': row[2],
      'grupo_cor_tema': row[3],
      'grupo_criador_id': row[4],
      'grupo_publico': row[5],
      'grupo_max_membros': row[6],
      'grupo_data_criacao': row[7],
      'grupo_data_atualizacao': row[8],
      'papel_usuario': row[9],
      'data_entrada': row[10],
      'total_membros': row[11],
    })).toList();
  }

  /// Retorna estatísticas dos grupos do usuário
  Future<Map<String, int>> getEstatisticasGruposUsuario(String usuarioId) async {
    final query = '''
      SELECT 
        ug.papel,
        COUNT(*) as quantidade
      FROM usuarios_grupos ug
      WHERE ug.usuario_id = @usuario_id AND ug.ativo = true
      GROUP BY ug.papel;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'usuario_id': usuarioId},
    );

    final estatisticas = <String, int>{
      'admin': 0,
      'moderador': 0,
      'membro': 0,
      'total': 0,
    };

    for (final row in result) {
      final papel = row[0] as String;
      final quantidade = row[1] as int;
      estatisticas[papel] = quantidade;
      estatisticas['total'] = estatisticas['total']! + quantidade;
    }

    return estatisticas;
  }

  /// Verifica se um usuário tem permissão para editar um grupo
  Future<bool> temPermissaoEditarGrupo(String usuarioId, String grupoId) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT papel FROM usuarios_grupos 
        WHERE usuario_id = @usuario_id 
          AND grupo_id = @grupo_id 
          AND ativo = true;
      '''),
      parameters: {'usuario_id': usuarioId, 'grupo_id': grupoId},
    );

    if (result.isNotEmpty) {
      final papel = result.first[0] as String;
      return papel == 'admin' || papel == 'moderador';
    }
    return false;
  }

  /// Atualiza as informações básicas de um grupo (nome e descrição)
  Future<void> atualizarInformacoesBasicas(String grupoId, String nome, String? descricao) async {
    final query = '''
      UPDATE grupos
      SET nome = @nome, descricao = @descricao, data_atualizacao = CURRENT_TIMESTAMP
      WHERE id = @id;
    ''';

    await _connection.execute(
      Sql.named(query),
      parameters: {
        'id': grupoId,
        'nome': nome,
        'descricao': descricao,
      },
    );
    print('Informações básicas do grupo $grupoId atualizadas.');
  }

  /// Atualiza configurações específicas do grupo
  Future<void> atualizarConfiguracoes(String grupoId, {
    String? corTema,
    bool? publico,
    int? maxMembros,
  }) async {
    final List<String> updates = [];
    final Map<String, dynamic> params = {'id': grupoId};

    if (corTema != null) {
      updates.add('cor_tema = @cor_tema');
      params['cor_tema'] = corTema;
    }

    if (publico != null) {
      updates.add('publico = @publico');
      params['publico'] = publico;
    }

    if (maxMembros != null) {
      updates.add('max_membros = @max_membros');
      params['max_membros'] = maxMembros;
    }

    if (updates.isNotEmpty) {
      final query = '''
        UPDATE grupos
        SET ${updates.join(', ')}, data_atualizacao = CURRENT_TIMESTAMP
        WHERE id = @id;
      ''';

      await _connection.execute(
        Sql.named(query),
        parameters: params,
      );
      print('Configurações do grupo $grupoId atualizadas.');
    }
  }

  /// Verifica se o nome do grupo já existe (para edição)
  Future<bool> hasGroupWithSameNameForEdit(String criadorId, String nome, String grupoId) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT COUNT(*) FROM grupos 
        WHERE criador_id = @criador_id 
          AND nome = @nome 
          AND id != @grupo_id;
      '''),
      parameters: {
        'criador_id': criadorId,
        'nome': nome,
        'grupo_id': grupoId,
      },
    );
    return (result.first[0] as int) > 0;
  }
}
