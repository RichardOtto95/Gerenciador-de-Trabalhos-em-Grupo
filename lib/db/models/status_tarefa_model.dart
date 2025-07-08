import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'status_tarefa'.
class StatusTarefa {
  final int id; // SERIAL PRIMARY KEY
  String nome;
  String? descricao;
  String cor;
  int ordem;
  bool ativo;

  StatusTarefa({
    required this.id,
    required this.nome,
    this.descricao,
    this.cor = '#6c757d', // Valor padrão conforme o script SQL
    this.ordem = 0, // Valor padrão conforme o script SQL
    this.ativo = true, // Valor padrão conforme o script SQL
  });

  /// Converte uma linha do banco de dados (Map) em um objeto StatusTarefa.
  factory StatusTarefa.fromMap(Map<String, dynamic> map) {
    return StatusTarefa(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      cor: map['cor'],
      ordem: map['ordem'],
      ativo: map['ativo'],
    );
  }

  /// Converte um objeto StatusTarefa em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'cor': cor,
      'ordem': ordem,
      'ativo': ativo,
    };
  }

  @override
  String toString() {
    return 'StatusTarefa(id: $id, nome: $nome, cor: $cor, ordem: $ordem)';
  }
}

/// Repositório para operações CRUD na tabela 'status_tarefa'.
class StatusTarefaRepository {
  final Connection _connection;

  StatusTarefaRepository() : _connection = DatabaseHelper().connection;

  /// Cria um novo status de tarefa no banco de dados.
  /// Note: Para 'SERIAL' PRIMARY KEY, o ID pode ser gerado automaticamente pelo banco.
  /// Se você não fornecer 'id' ao criar, o banco o fará.
  Future<void> createStatusTarefa(StatusTarefa statusTarefa) async {
    final query = '''
      INSERT INTO status_tarefa (id, nome, descricao, cor, ordem, ativo)
      VALUES (@id, @nome, @descricao, @cor, @ordem, @ativo);
    ''';
    await _connection.execute(Sql.named(query), parameters: statusTarefa.toMap());
    print('Status de Tarefa "${statusTarefa.nome}" criado.');
  }

  /// Retorna todos os status de tarefa do banco de dados.
  Future<List<StatusTarefa>> getAllStatusTarefas() async {
    final result = await _connection.execute(
      'SELECT * FROM status_tarefa ORDER BY ordem ASC;',
    );
    return result
        .map(
          (row) => StatusTarefa.fromMap({
            'id': row[0],
            'nome': row[1],
            'descricao': row[2],
            'cor': row[3],
            'ordem': row[4],
            'ativo': row[5],
          }),
        )
        .toList();
  }

  /// Retorna um status de tarefa pelo seu ID.
  Future<StatusTarefa?> getStatusTarefaById(int id) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM status_tarefa WHERE id = @id;'),
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return StatusTarefa.fromMap({
        'id': row[0],
        'nome': row[1],
        'descricao': row[2],
        'cor': row[3],
        'ordem': row[4],
        'ativo': row[5],
      });
    }
    return null;
  }

  /// Atualiza as informações de um status de tarefa existente.
  Future<void> updateStatusTarefa(StatusTarefa statusTarefa) async {
    final query = '''
      UPDATE status_tarefa
      SET nome = @nome, descricao = @descricao, cor = @cor, ordem = @ordem, ativo = @ativo
      WHERE id = @id;
    ''';
    await _connection.execute(Sql.named(query), parameters: statusTarefa.toMap());
    print('Status de Tarefa "${statusTarefa.nome}" atualizado.');
  }

  /// Deleta um status de tarefa pelo seu ID.
  Future<void> deleteStatusTarefa(int id) async {
    await _connection.execute(
      Sql.named('DELETE FROM status_tarefa WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Status de Tarefa com ID $id deletado.');
  }
}
