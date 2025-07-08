import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

/// Modelo Dart para a tabela de relacionamento 'usuarios_grupos'.
class UsuarioGrupo {
  final String id;
  String usuarioId;
  String grupoId;
  String papel; // 'admin', 'moderador', 'membro'
  DateTime dataEntrada;
  bool ativo;

  UsuarioGrupo({
    String? id,
    required this.usuarioId,
    required this.grupoId,
    this.papel = 'membro', // Valor padrão conforme o script SQL
    DateTime? dataEntrada,
    this.ativo = true, // Valor padrão conforme o script SQL
  }) : id = id ?? const Uuid().v4(),
       dataEntrada = dataEntrada ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto UsuarioGrupo.
  factory UsuarioGrupo.fromMap(Map<String, dynamic> map) {
    return UsuarioGrupo(
      id: map['id'],
      usuarioId: map['usuario_id'],
      grupoId: map['grupo_id'],
      papel: map['papel'],
      dataEntrada: (map['data_entrada'] as DateTime),
      ativo: map['ativo'],
    );
  }

  /// Converte um objeto UsuarioGrupo em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'grupo_id': grupoId,
      'papel': papel,
      'data_entrada': dataEntrada,
      'ativo': ativo,
    };
  }

  @override
  String toString() {
    return 'UsuarioGrupo(id: $id, usuarioId: $usuarioId, grupoId: $grupoId, papel: $papel, ativo: $ativo)';
  }
}

/// Modelo composto para membros do grupo com informações do usuário
class MembroGrupo {
  final UsuarioGrupo usuarioGrupo;
  final Usuario usuario;

  MembroGrupo({
    required this.usuarioGrupo,
    required this.usuario,
  });

  factory MembroGrupo.fromMap(Map<String, dynamic> map) {
    return MembroGrupo(
      usuarioGrupo: UsuarioGrupo.fromMap({
        'id': map['ug_id'],
        'usuario_id': map['ug_usuario_id'],
        'grupo_id': map['ug_grupo_id'],
        'papel': map['ug_papel'],
        'data_entrada': map['ug_data_entrada'],
        'ativo': map['ug_ativo'],
      }),
      usuario: Usuario.fromMap({
        'id': map['u_id'],
        'nome': map['u_nome'],
        'email': map['u_email'],
        'senha_hash': map['u_senha_hash'],
        'foto_perfil': map['u_foto_perfil'],
        'bio': map['u_bio'],
        'ativo': map['u_ativo'],
        'data_criacao': map['u_data_criacao'],
        'data_atualizacao': map['u_data_atualizacao'],
        'ultimo_login': map['u_ultimo_login'],
      }),
    );
  }

  @override
  String toString() {
    return 'MembroGrupo(usuario: ${usuario.nome}, papel: ${usuarioGrupo.papel})';
  }
}

/// Repositório para operações CRUD na tabela 'usuarios_grupos'.
class UsuarioGrupoRepository {
  final Connection _connection;

  UsuarioGrupoRepository() : _connection = DatabaseHelper().connection;

  /// Adiciona um usuário a um grupo.
  Future<void> createUsuarioGrupo(UsuarioGrupo ug) async {
    final query = '''
      INSERT INTO usuarios_grupos (id, usuario_id, grupo_id, papel, data_entrada, ativo)
      VALUES (@id, @usuario_id, @grupo_id, @papel, @data_entrada, @ativo);
    ''';
    await _connection.execute(Sql.named(query), parameters: ug.toMap());
    print(
      'Usuário ${ug.usuarioId} adicionado ao grupo ${ug.grupoId} como ${ug.papel}.',
    );
  }

  /// Retorna todos os usuários de um grupo específico.
  Future<List<UsuarioGrupo>> getUsuariosByGrupo(
    String grupoId, {
    bool ativo = true,
  }) async {
    String whereClause = 'WHERE grupo_id = @grupo_id';
    Map<String, dynamic> params = {'grupo_id': grupoId};
    if (ativo) {
      whereClause += ' AND ativo = @ativo';
      params['ativo'] = ativo;
    }
    final result = await _connection.execute(
      Sql.named('SELECT * FROM usuarios_grupos $whereClause;'),
      parameters: params,
    );
    return result
        .map(
          (row) => UsuarioGrupo.fromMap({
            'id': row[0],
            'usuario_id': row[1],
            'grupo_id': row[2],
            'papel': row[3],
            'data_entrada': row[4],
            'ativo': row[5],
          }),
        )
        .toList();
  }

  /// Retorna todos os grupos aos quais um usuário pertence.
  Future<List<UsuarioGrupo>> getGruposByUsuario(
    String usuarioId, {
    bool? ativo,
  }) async {
    String whereClause = 'WHERE usuario_id = @usuario_id';
    Map<String, dynamic> params = {'usuario_id': usuarioId};
    if (ativo != null) {
      whereClause += ' AND ativo = @ativo';
      params['ativo'] = ativo;
    }
    final result = await _connection.execute(
      Sql.named('SELECT * FROM usuarios_grupos $whereClause;'),
      parameters: params,
    );
    return result
        .map(
          (row) => UsuarioGrupo.fromMap({
            'id': row[0],
            'usuario_id': row[1],
            'grupo_id': row[2],
            'papel': row[3],
            'data_entrada': row[4],
            'ativo': row[5],
          }),
        )
        .toList();
  }

  /// Retorna o relacionamento específico entre um usuário e um grupo.
  Future<UsuarioGrupo?> getUsuarioGrupo(
    String usuarioId,
    String grupoId,
  ) async {
    final result = await _connection.execute(
      Sql.named(
        'SELECT * FROM usuarios_grupos WHERE usuario_id = @usuario_id AND grupo_id = @grupo_id;',
      ),
      parameters: {'usuario_id': usuarioId, 'grupo_id': grupoId},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return UsuarioGrupo.fromMap({
        'id': row[0],
        'usuario_id': row[1],
        'grupo_id': row[2],
        'papel': row[3],
        'data_entrada': row[4],
        'ativo': row[5],
      });
    }
    return null;
  }

  /// Retorna a quantidade de usuarios no grupo
  Future<int> getUsuariosNoGrupo(String id) async {
    final result = await _connection.execute(
      Sql.named('SELECT COUNT(*) AS quantidade FROM usuarios_grupos WHERE grupo_id = @grupo_id;'),
      parameters: {'grupo_id': id},
    );

    return result.first[0] as int;
  }

  /// Atualiza o papel ou o status de atividade de um usuário em um grupo.
  Future<void> updateUsuarioGrupo(UsuarioGrupo ug) async {
    final query = '''
      UPDATE usuarios_grupos
      SET papel = @papel, ativo = @ativo
      WHERE id = @id;
    ''';
    await _connection.execute(Sql.named(query), parameters: ug.toMap());
    print(
      'Papel do usuário ${ug.usuarioId} no grupo ${ug.grupoId} atualizado para ${ug.papel}.',
    );
  }

  /// Deleta um relacionamento usuário-grupo pelo seu ID.
  Future<void> deleteUsuarioGrupo(String id) async {
    await _connection.execute(
      Sql.named('DELETE FROM usuarios_grupos WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Relacionamento UsuarioGrupo com ID $id deletado.');
  }

  Future<void> deleteGrupo(String grupoId) async {
    await _connection.execute(
      Sql.named('DELETE FROM usuarios_grupos WHERE grupo_id = @grupo_id;'),
      parameters: {'grupo_id': grupoId},
    );
    print('Relacionamentos UsuarioGrupo com group_id $grupoId deletado.');
  }

  /// Remove um usuário de um grupo.
  Future<void> removeUsuarioFromGrupo(String usuarioId, String grupoId) async {
    await _connection.execute(
      Sql.named('DELETE FROM usuarios_grupos WHERE usuario_id = @usuario_id AND grupo_id = @grupo_id;'),
      parameters: {'usuario_id': usuarioId, 'grupo_id': grupoId},
    );
    print('Usuário $usuarioId removido do grupo $grupoId.');
  }

  /// Retorna todos os membros de um grupo com informações detalhadas do usuário
  Future<List<MembroGrupo>> getMembrosComInfo(String grupoId) async {
    final query = '''
      SELECT 
        ug.id as ug_id,
        ug.usuario_id as ug_usuario_id,
        ug.grupo_id as ug_grupo_id,
        ug.papel as ug_papel,
        ug.data_entrada as ug_data_entrada,
        ug.ativo as ug_ativo,
        u.id as u_id,
        u.nome as u_nome,
        u.email as u_email,
        u.senha_hash as u_senha_hash,
        u.foto_perfil as u_foto_perfil,
        u.bio as u_bio,
        u.ativo as u_ativo,
        u.data_criacao as u_data_criacao,
        u.data_atualizacao as u_data_atualizacao,
        u.ultimo_login as u_ultimo_login
      FROM usuarios_grupos ug
      INNER JOIN usuarios u ON ug.usuario_id = u.id
      WHERE ug.grupo_id = @grupo_id AND ug.ativo = true
      ORDER BY ug.papel DESC, ug.data_entrada ASC;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'grupo_id': grupoId},
    );

    return result.map((row) => MembroGrupo.fromMap({
      'ug_id': row[0],
      'ug_usuario_id': row[1],
      'ug_grupo_id': row[2],
      'ug_papel': row[3],
      'ug_data_entrada': row[4],
      'ug_ativo': row[5],
      'u_id': row[6],
      'u_nome': row[7],
      'u_email': row[8],
      'u_senha_hash': row[9],
      'u_foto_perfil': row[10],
      'u_bio': row[11],
      'u_ativo': row[12],
      'u_data_criacao': row[13],
      'u_data_atualizacao': row[14],
      'u_ultimo_login': row[15],
    })).toList();
  }

  /// Busca usuários não membros do grupo para adicionar
  Future<List<Usuario>> buscarUsuariosNaoMembros(String grupoId, String termo) async {
    final query = '''
      SELECT u.id, u.nome, u.email, u.senha_hash, u.foto_perfil, u.bio, u.ativo, u.data_criacao, u.data_atualizacao, u.ultimo_login
      FROM usuarios u
      WHERE u.id NOT IN (
        SELECT ug.usuario_id 
        FROM usuarios_grupos ug 
        WHERE ug.grupo_id = @grupo_id AND ug.ativo = true
      )
      AND u.ativo = true
      AND (LOWER(u.nome) LIKE LOWER(@termo) OR LOWER(u.email) LIKE LOWER(@termo))
      ORDER BY u.nome ASC
      LIMIT 10;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {
        'grupo_id': grupoId,
        'termo': '%$termo%',
      },
    );

    return result.map((row) => Usuario.fromMap({
      'id': row[0],
      'nome': row[1],
      'email': row[2],
      'senha_hash': row[3],
      'foto_perfil': row[4],
      'bio': row[5],
      'ativo': row[6],
      'data_criacao': row[7],
      'data_atualizacao': row[8],
      'ultimo_login': row[9],
    })).toList();
  }

  /// Verifica se um usuário tem permissão para gerenciar membros do grupo
  Future<bool> temPermissaoGerenciarMembros(String usuarioId, String grupoId) async {
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

  /// Altera o papel de um membro no grupo
  Future<void> alterarPapelMembro(String usuarioId, String grupoId, String novoPapel) async {
    final query = '''
      UPDATE usuarios_grupos 
      SET papel = @novo_papel
      WHERE usuario_id = @usuario_id 
        AND grupo_id = @grupo_id 
        AND ativo = true;
    ''';

    await _connection.execute(
      Sql.named(query),
      parameters: {
        'usuario_id': usuarioId,
        'grupo_id': grupoId,
        'novo_papel': novoPapel,
      },
    );
    print('Papel do usuário $usuarioId no grupo $grupoId alterado para $novoPapel.');
  }

  /// Desativa um membro do grupo (remove sem deletar)
  Future<void> desativarMembro(String usuarioId, String grupoId) async {
    final query = '''
      UPDATE usuarios_grupos 
      SET ativo = false
      WHERE usuario_id = @usuario_id 
        AND grupo_id = @grupo_id;
    ''';

    await _connection.execute(
      Sql.named(query),
      parameters: {
        'usuario_id': usuarioId,
        'grupo_id': grupoId,
      },
    );
    print('Membro $usuarioId desativado do grupo $grupoId.');
  }

  /// Verifica se um usuário já é membro de um grupo
  Future<bool> ehMembroDoGrupo(String usuarioId, String grupoId) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT COUNT(*) FROM usuarios_grupos 
        WHERE usuario_id = @usuario_id 
          AND grupo_id = @grupo_id 
          AND ativo = true;
      '''),
      parameters: {'usuario_id': usuarioId, 'grupo_id': grupoId},
    );

    return (result.first[0] as int) > 0;
  }

  /// Obtém estatísticas de membros do grupo por papel
  Future<Map<String, int>> getEstatisticasMembros(String grupoId) async {
    final query = '''
      SELECT papel, COUNT(*) as quantidade
      FROM usuarios_grupos
      WHERE grupo_id = @grupo_id AND ativo = true
      GROUP BY papel;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'grupo_id': grupoId},
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

  /// Verifica se um usuário pode sair do grupo (não é o único admin)
  Future<bool> podeUsuarioSairDoGrupo(String usuarioId, String grupoId) async {
    // Primeiro, verifica o papel do usuário
    final userRoleResult = await _connection.execute(
      Sql.named('''
        SELECT papel FROM usuarios_grupos 
        WHERE usuario_id = @usuario_id 
          AND grupo_id = @grupo_id 
          AND ativo = true;
      '''),
      parameters: {'usuario_id': usuarioId, 'grupo_id': grupoId},
    );

    if (userRoleResult.isEmpty) {
      return false; // Usuário não é membro do grupo
    }

    final papel = userRoleResult.first[0] as String;
    
    // Se não é admin, pode sair
    if (papel != 'admin') {
      return true;
    }

    // Se é admin, verifica se não é o único admin
    final adminCountResult = await _connection.execute(
      Sql.named('''
        SELECT COUNT(*) FROM usuarios_grupos 
        WHERE grupo_id = @grupo_id 
          AND papel = 'admin' 
          AND ativo = true;
      '''),
      parameters: {'grupo_id': grupoId},
    );

    final adminCount = adminCountResult.first[0] as int;
    return adminCount > 1; // Pode sair se houver mais de um admin
  }

  /// Remove todas as atribuições de tarefas de um usuário em um grupo
  Future<void> removerAtribuicoesTarefasUsuario(String usuarioId, String grupoId) async {
    final query = '''
      DELETE FROM atribuicoes_tarefa 
      WHERE usuario_id = @usuario_id 
        AND tarefa_id IN (
          SELECT id FROM tarefas WHERE grupo_id = @grupo_id
        );
    ''';

    await _connection.execute(
      Sql.named(query),
      parameters: {
        'usuario_id': usuarioId,
        'grupo_id': grupoId,
      },
    );
    print('Atribuições de tarefas do usuário $usuarioId no grupo $grupoId removidas.');
  }

  /// Método para sair do grupo
  Future<void> sairDoGrupo(String usuarioId, String grupoId) async {
    // Remove todas as atribuições de tarefas
    await removerAtribuicoesTarefasUsuario(usuarioId, grupoId);

    // Remove o usuário do grupo
    await desativarMembro(usuarioId, grupoId);

    print('Usuário $usuarioId saiu do grupo $grupoId.');
  }
}
