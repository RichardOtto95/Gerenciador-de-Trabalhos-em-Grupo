import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'rotulos'.
class Rotulo {
  final String id;
  String nome;
  String? descricao;
  String cor;
  String?
  grupoId; // Chave estrangeira para grupos(id), pode ser nulo (rótulo global)

  Rotulo({
    String? id,
    required this.nome,
    this.descricao,
    this.cor = '#007bff', // Valor padrão conforme o script SQL
    this.grupoId,
  }) : id = id ?? const Uuid().v4();

  /// Converte uma linha do banco de dados (Map) em um objeto Rotulo.
  factory Rotulo.fromMap(Map<String, dynamic> map) {
    return Rotulo(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      cor: map['cor'],
      grupoId: map['grupo_id'],
    );
  }

  /// Converte um objeto Rotulo em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'cor': cor,
      'grupo_id': grupoId,
    };
  }

  @override
  String toString() {
    return 'Rotulo(id: $id, nome: $nome, cor: $cor, grupoId: $grupoId)';
  }
}

/// Repositório para operações CRUD na tabela 'rotulos'.
class RotuloRepository {
  final Connection _connection;

  RotuloRepository() : _connection = DatabaseHelper().connection;

  /// Cria um novo rótulo no banco de dados.
  Future<void> createRotulo(Rotulo rotulo) async {
    final query = '''
      INSERT INTO rotulos (id, nome, descricao, cor, grupo_id)
      VALUES (@id, @nome, @descricao, @cor, @grupo_id);
    ''';
    await _connection.execute(query, parameters: rotulo.toMap());
    print('Rótulo "${rotulo.nome}" criado.');
  }

  /// Retorna todos os rótulos do banco de dados.
  Future<List<Rotulo>> getAllRotulos() async {
    final result = await _connection.execute('SELECT * FROM rotulos;');
    return result
        .map(
          (row) => Rotulo.fromMap({
            'id': row[0],
            'nome': row[1],
            'descricao': row[2],
            'cor': row[3],
            'grupo_id': row[4],
          }),
        )
        .toList();
  }

  /// Retorna um rótulo pelo seu ID.
  Future<Rotulo?> getRotuloById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM rotulos WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Rotulo.fromMap({
        'id': row[0],
        'nome': row[1],
        'descricao': row[2],
        'cor': row[3],
        'grupo_id': row[4],
      });
    }
    return null;
  }

  /// Retorna rótulos por ID de grupo (incluindo rótulos globais se grupoId for nulo).
  Future<List<Rotulo>> getRotulosByGrupoId(String? grupoId) async {
    final query = grupoId == null
        ? 'SELECT * FROM rotulos WHERE grupo_id IS NULL;'
        : 'SELECT * FROM rotulos WHERE grupo_id = @grupo_id;';
    final result = await _connection.execute(
      query,
      parameters: {'grupo_id': grupoId},
    );
    return result
        .map(
          (row) => Rotulo.fromMap({
            'id': row[0],
            'nome': row[1],
            'descricao': row[2],
            'cor': row[3],
            'grupo_id': row[4],
          }),
        )
        .toList();
  }

  /// Atualiza as informações de um rótulo existente.
  Future<void> updateRotulo(Rotulo rotulo) async {
    final query = '''
      UPDATE rotulos
      SET nome = @nome, descricao = @descricao, cor = @cor, grupo_id = @grupo_id
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: rotulo.toMap());
    print('Rótulo "${rotulo.nome}" atualizado.');
  }

  /// Deleta um rótulo pelo seu ID.
  Future<void> deleteRotulo(String id) async {
    await _connection.execute(
      'DELETE FROM rotulos WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Rótulo com ID $id deletado.');
  }
}
