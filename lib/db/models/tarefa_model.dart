import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'tarefas'.
class Tarefa {
  final String id;
  String titulo;
  String? descricao;
  String grupoId; // Chave estrangeira para grupos(id)
  String criadorId; // Chave estrangeira para usuarios(id)
  int statusId; // Chave estrangeira para status_tarefa(id)
  int prioridade; // 1=baixa, 2=normal, 3=alta, 4=urgente
  DateTime? dataInicio; // Tipo DATE no SQL, mapeado para DateTime em Dart
  DateTime? dataVencimento; // Tipo DATE no SQL, mapeado para DateTime em Dart
  double? estimativaHoras; // NUMERIC(5,2)
  double horasTrabalhadas; // NUMERIC(5,2)
  int progresso; // Percentual de conclusão (0-100)
  DateTime dataCriacao;
  DateTime dataAtualizacao; // Campo adicionado: data_atualizacao
  DateTime? dataConclusao;

  Tarefa({
    String? id,
    required this.titulo,
    this.descricao,
    required this.grupoId,
    required this.criadorId,
    required this.statusId,
    this.prioridade = 2, // Valor padrão conforme o script SQL
    this.dataInicio,
    this.dataVencimento,
    this.estimativaHoras,
    this.horasTrabalhadas = 0.0, // Valor padrão conforme o script SQL
    this.progresso = 0, // Valor padrão conforme o script SQL
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    this.dataConclusao,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now(),
       dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto Tarefa.
  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['id'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      grupoId: map['grupo_id'],
      criadorId: map['criador_id'],
      statusId: map['status_id'],
      prioridade: map['prioridade'],
      dataInicio: (map['data_inicio'] as DateTime?),
      dataVencimento: (map['data_vencimento'] as DateTime?),
      estimativaHoras: (map['estimativa_horas'] as double?),
      horasTrabalhadas: (map['horas_trabalhadas'] as double),
      progresso: map['progresso'],
      dataCriacao: (map['data_criacao'] as DateTime),
      dataAtualizacao: (map['data_atualizacao'] as DateTime),
      dataConclusao: (map['data_conclusao'] as DateTime?),
    );
  }

  /// Converte um objeto Tarefa em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'grupo_id': grupoId,
      'criador_id': criadorId,
      'status_id': statusId,
      'prioridade': prioridade,
      'data_inicio': dataInicio,
      'data_vencimento': dataVencimento,
      'estimativa_horas': estimativaHoras,
      'horas_trabalhadas': horasTrabalhadas,
      'progresso': progresso,
      'data_criacao': dataCriacao,
      'data_atualizacao': dataAtualizacao,
      'data_conclusao': dataConclusao,
    };
  }

  @override
  String toString() {
    return 'Tarefa(id: $id, titulo: $titulo, statusId: $statusId, progresso: $progresso)';
  }
}

/// Repositório para operações CRUD na tabela 'tarefas'.
class TarefaRepository {
  final Connection _connection;

  TarefaRepository() : _connection = DatabaseHelper().connection;

  /// Cria uma nova tarefa no banco de dados.
  Future<void> createTarefa(Tarefa tarefa) async {
    final query = '''
      INSERT INTO tarefas (id, titulo, descricao, grupo_id, criador_id, status_id, prioridade, data_inicio, data_vencimento, estimativa_horas, horas_trabalhadas, progresso, data_criacao, data_atualizacao, data_conclusao)
      VALUES (@id, @titulo, @descricao, @grupo_id, @criador_id, @status_id, @prioridade, @data_inicio, @data_vencimento, @estimativa_horas, @horas_trabalhadas, @progresso, @data_criacao, @data_atualizacao, @data_conclusao);
    ''';
    await _connection.execute(query, parameters: tarefa.toMap());
    print('Tarefa "${tarefa.titulo}" criada.');
  }

  /// Retorna todas as tarefas do banco de dados.
  Future<List<Tarefa>> getAllTarefas() async {
    final result = await _connection.execute('SELECT * FROM tarefas;');
    return result.map((row) {
      return Tarefa.fromMap({
        'id': row[0],
        'titulo': row[1],
        'descricao': row[2],
        'grupo_id': row[3],
        'criador_id': row[4],
        'status_id': row[5],
        'prioridade': row[6],
        'data_inicio': row[7],
        'data_vencimento': row[8],
        'estimativa_horas': row[9],
        'horas_trabalhadas': row[10],
        'progresso': row[11],
        'data_criacao': row[12],
        'data_atualizacao': row[13],
        'data_conclusao': row[14],
      });
    }).toList();
  }

  /// Retorna uma tarefa pelo seu ID.
  Future<Tarefa?> getTarefaById(String id) async {
    final result = await _connection.execute(
      'SELECT * FROM tarefas WHERE id = @id;',
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Tarefa.fromMap({
        'id': row[0],
        'titulo': row[1],
        'descricao': row[2],
        'grupo_id': row[3],
        'criador_id': row[4],
        'status_id': row[5],
        'prioridade': row[6],
        'data_inicio': row[7],
        'data_vencimento': row[8],
        'estimativa_horas': row[9],
        'horas_trabalhadas': row[10],
        'progresso': row[11],
        'data_criacao': row[12],
        'data_atualizacao': row[13],
        'data_conclusao': row[14],
      });
    }
    return null;
  }

  /// Retorna tarefas por grupo e/ou status.
  Future<List<Tarefa>> getTarefasByGrupoAndStatus(
    String grupoId, {
    int? statusId,
  }) async {
    String query = 'SELECT * FROM tarefas WHERE grupo_id = @grupo_id';
    Map<String, dynamic> params = {'grupo_id': grupoId};
    if (statusId != null) {
      query += ' AND status_id = @status_id';
      params['status_id'] = statusId;
    }
    query +=
        ' ORDER BY prioridade DESC, data_vencimento ASC;'; // Exemplo de ordenação

    final result = await _connection.execute(query, parameters: params);
    return result.map((row) {
      return Tarefa.fromMap({
        'id': row[0],
        'titulo': row[1],
        'descricao': row[2],
        'grupo_id': row[3],
        'criador_id': row[4],
        'status_id': row[5],
        'prioridade': row[6],
        'data_inicio': row[7],
        'data_vencimento': row[8],
        'estimativa_horas': row[9],
        'horas_trabalhadas': row[10],
        'progresso': row[11],
        'data_criacao': row[12],
        'data_atualizacao': row[13],
        'data_conclusao': row[14],
      });
    }).toList();
  }

  /// Atualiza as informações de uma tarefa existente.
  Future<void> updateTarefa(Tarefa tarefa) async {
    final query = '''
      UPDATE tarefas
      SET titulo = @titulo, descricao = @descricao, grupo_id = @grupo_id, 
          criador_id = @criador_id, status_id = @status_id, prioridade = @prioridade,
          data_inicio = @data_inicio, data_vencimento = @data_vencimento, 
          estimativa_horas = @estimativa_horas, horas_trabalhadas = @horas_trabalhadas,
          progresso = @progresso, data_atualizacao = CURRENT_TIMESTAMP, data_conclusao = @data_conclusao
      WHERE id = @id;
    ''';
    await _connection.execute(query, parameters: tarefa.toMap());
    print('Tarefa "${tarefa.titulo}" atualizada.');
  }

  /// Deleta uma tarefa pelo seu ID.
  Future<void> deleteTarefa(String id) async {
    await _connection.execute(
      'DELETE FROM tarefas WHERE id = @id;',
      parameters: {'id': id},
    );
    print('Tarefa com ID $id deletada.');
  }
}
