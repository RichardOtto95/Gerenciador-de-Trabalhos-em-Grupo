import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'usuarios'.
class Usuario {
  final String id;
  String nome;
  String email;
  String senhaHash; // Campo adicionado: senha_hash
  String? fotoPerfil;
  String? bio;
  bool ativo; // Campo adicionado: ativo
  DateTime dataCriacao;
  DateTime dataAtualizacao; // Campo adicionado: data_atualizacao
  DateTime? ultimoLogin;

  Usuario({
    String? id,
    required this.nome,
    required this.email,
    required this.senhaHash, // Requerido
    this.fotoPerfil,
    this.bio,
    this.ativo = true, // Valor padrão conforme o script SQL
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    this.ultimoLogin,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now(),
       dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto Usuario.
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      senhaHash: map['senha_hash'],
      fotoPerfil: map['foto_perfil'],
      bio: map['bio'],
      ativo: map['ativo'],
      dataCriacao: (map['data_criacao'] as DateTime),
      dataAtualizacao: (map['data_atualizacao'] as DateTime),
      ultimoLogin: (map['ultimo_login'] as DateTime?),
    );
  }

  /// Converte um objeto Usuario em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'senha_hash': senhaHash,
      'foto_perfil': fotoPerfil,
      'bio': bio,
      'ativo': ativo,
      'data_criacao': dataCriacao,
      'data_atualizacao': dataAtualizacao,
      'ultimo_login': ultimoLogin,
    };
  }

  @override
  String toString() {
    return 'Usuario(id: $id, nome: $nome, email: $email, ativo: $ativo)';
  }
}

/// Repositório para operações CRUD na tabela 'usuarios'.
class UsuarioRepository {
  final Connection _connection;

  UsuarioRepository() : _connection = DatabaseHelper().connection;

  /// Cria um novo usuário no banco de dados.
  Future<void> createUsuario(Usuario usuario) async {
    final query = '''
      INSERT INTO usuarios (id, nome, email, senha_hash, foto_perfil, bio, ativo, data_criacao, data_atualizacao, ultimo_login)
      VALUES (@id, @nome, @email, @senha_hash, @foto_perfil, @bio, @ativo, @data_criacao, @data_atualizacao, @ultimo_login);
    ''';
    await _connection.execute(query, parameters: usuario.toMap());
    print('Usuário "${usuario.nome}" criado.');
  }

  /// Retorna todos os usuários do banco de dados.
  Future<List<Usuario>> getAllUsuarios() async {
    final result = await _connection.execute('SELECT * FROM usuarios;');
    return result.map((row) {
      return Usuario.fromMap({
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
      });
    }).toList();
  }

  /// Retorna um usuário pelo seu ID.
  Future<Usuario?> getUsuarioById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM usuarios WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Usuario.fromMap({
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
      });
    }
    return null;
  }

  /// Retorna um usuário pelo seu email.
  Future<Usuario?> getUsuarioByEmail(String email) async {
    final result = await _connection.execute(
      'SELECT * FROM usuarios WHERE email = @email;',
      parameters: {'email': email},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Usuario.fromMap({
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
      });
    }
    return null;
  }

  /// Atualiza as informações de um usuário existente.
  Future<void> updateUsuario(Usuario usuario) async {
    final query = '''
      UPDATE usuarios
      SET nome = @nome, email = @email, senha_hash = @senha_hash, foto_perfil = @foto_perfil, 
          bio = @bio, ativo = @ativo, data_atualizacao = CURRENT_TIMESTAMP, ultimo_login = @ultimo_login
      WHERE id = @id;
    ''';
    // Note: data_atualizacao é atualizada pelo trigger no banco, mas incluímos para consistência no toMap.
    await _connection.execute(query, parameters: usuario.toMap());
    print('Usuário "${usuario.nome}" atualizado.');
  }

  /// Deleta um usuário pelo seu ID.
  Future<void> deleteUsuario(String id) async {
    await _connection.execute(
      'DELETE FROM usuarios WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Usuário com ID $id deletado.');
  }
}
