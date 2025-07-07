import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

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
    final result = await _connection.execute("""
      SELECT COUNT(*) AS quantidade
      FROM usuarios_grupos 
      WHERE grupo_id = '$id';""");

    return result.first[0] as int;
  }

  /// Atualiza o papel ou o status de atividade de um usuário em um grupo.
  Future<void> updateUsuarioGrupo(UsuarioGrupo ug) async {
    final query = '''
      UPDATE usuarios_grupos
      SET papel = @papel, ativo = @ativo
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: ug.toMap());
    print(
      'Papel do usuário ${ug.usuarioId} no grupo ${ug.grupoId} atualizado para ${ug.papel}.',
    );
  }

  /// Deleta um relacionamento usuário-grupo pelo seu ID.
  Future<void> deleteUsuarioGrupo(String id) async {
    await _connection.execute(
      'DELETE FROM usuarios_grupos WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Relacionamento UsuarioGrupo com ID $id deletado.');
  }

  Future<void> deleteGrupo(String grupoId) async {
    await _connection.execute("""
      DELETE FROM usuarios_grupos WHERE grupo_id = '$grupoId'
    """);
    print('Relacionamentos UsuarioGrupo com group_id $grupoId deletado.');
  }

  /// Remove um usuário de um grupo.
  Future<void> removeUsuarioFromGrupo(String usuarioId, String grupoId) async {
    await _connection.execute(
      'DELETE FROM usuarios_grupos WHERE usuario_id = @usuario_id AND grupo_id = @grupo_id;',
      parameters: {'usuario_id': usuarioId, 'grupo_id': grupoId},
    );
    print('Usuário $usuarioId removido do grupo $grupoId.');
  }
}
