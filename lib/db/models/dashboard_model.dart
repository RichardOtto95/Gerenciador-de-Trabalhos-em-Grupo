import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/atividade_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/db_helper.dart';
import 'package:postgres/postgres.dart';

/// Modelo para estatísticas de tarefas por status
class TaskStats {
  final int pendentes;
  final int emProgresso;
  final int concluidas;
  final int canceladas;
  final int total;

  TaskStats({
    required this.pendentes,
    required this.emProgresso,
    required this.concluidas,
    required this.canceladas,
    required this.total,
  });

  factory TaskStats.fromMap(Map<String, dynamic> map) {
    return TaskStats(
      pendentes: map['pendentes'] ?? 0,
      emProgresso: map['em_progresso'] ?? 0,
      concluidas: map['concluidas'] ?? 0,
      canceladas: map['canceladas'] ?? 0,
      total: map['total'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pendentes': pendentes,
      'em_progresso': emProgresso,
      'concluidas': concluidas,
      'canceladas': canceladas,
      'total': total,
    };
  }
}

/// Modelo para tarefa com informações resumidas para dashboard
class TaskSummary {
  final String id;
  final String titulo;
  final String grupoNome;
  final String statusNome;
  final String? statusCor;
  final int? prioridade;
  final DateTime? dataVencimento;
  final DateTime dataCriacao;
  final bool vencida;

  TaskSummary({
    required this.id,
    required this.titulo,
    required this.grupoNome,
    required this.statusNome,
    this.statusCor,
    this.prioridade,
    this.dataVencimento,
    required this.dataCriacao,
    required this.vencida,
  });

  factory TaskSummary.fromMap(Map<String, dynamic> map) {
    final dataVencimento = map['data_vencimento'] as DateTime?;
    final agora = DateTime.now();
    
    return TaskSummary(
      id: map['id'],
      titulo: map['titulo'],
      grupoNome: map['grupo_nome'],
      statusNome: map['status_nome'],
      statusCor: map['status_cor'],
      prioridade: map['prioridade'],
      dataVencimento: dataVencimento,
      dataCriacao: map['data_criacao'] as DateTime,
      vencida: dataVencimento != null && dataVencimento.isBefore(agora),
    );
  }

  String get prioridadeTexto {
    switch (prioridade) {
      case 1: return 'Baixa';
      case 2: return 'Normal';
      case 3: return 'Alta';
      case 4: return 'Urgente';
      default: return 'Normal';
    }
  }
}

/// Modelo para estatísticas de grupos
class GroupStats {
  final int totalGrupos;
  final int comoAdmin;
  final int comoModerador;
  final int comoMembro;

  GroupStats({
    required this.totalGrupos,
    required this.comoAdmin,
    required this.comoModerador,
    required this.comoMembro,
  });

  factory GroupStats.fromMap(Map<String, dynamic> map) {
    return GroupStats(
      totalGrupos: map['total_grupos'] ?? 0,
      comoAdmin: map['como_admin'] ?? 0,
      comoModerador: map['como_moderador'] ?? 0,
      comoMembro: map['como_membro'] ?? 0,
    );
  }
}

/// Modelo para atividade recente resumida
class RecentActivity {
  final String id;
  final String acao;
  final String tipoEntidade;
  final String entidadeId;
  final String usuarioNome;
  final String? detalhesTexto;
  final DateTime dataAcao;

  RecentActivity({
    required this.id,
    required this.acao,
    required this.tipoEntidade,
    required this.entidadeId,
    required this.usuarioNome,
    this.detalhesTexto,
    required this.dataAcao,
  });

  factory RecentActivity.fromMap(Map<String, dynamic> map) {
    return RecentActivity(
      id: map['id'],
      acao: map['acao'],
      tipoEntidade: map['tipo_entidade'],
      entidadeId: map['entidade_id'],
      usuarioNome: map['usuario_nome'],
      detalhesTexto: map['detalhes_texto'],
      dataAcao: map['data_acao'] as DateTime,
    );
  }

  String get descricao {
    switch (acao) {
      case 'criou':
        switch (tipoEntidade) {
          case 'tarefa': return '$usuarioNome criou uma nova tarefa';
          case 'grupo': return '$usuarioNome criou um novo grupo';
          case 'comentario': return '$usuarioNome adicionou um comentário';
          case 'anexo': return '$usuarioNome anexou um arquivo';
          default: return '$usuarioNome criou $tipoEntidade';
        }
      case 'atualizou':
        switch (tipoEntidade) {
          case 'tarefa': return '$usuarioNome atualizou uma tarefa';
          case 'grupo': return '$usuarioNome atualizou um grupo';
          default: return '$usuarioNome atualizou $tipoEntidade';
        }
      case 'concluiu':
        return '$usuarioNome concluiu uma tarefa';
      case 'atribuiu':
        return '$usuarioNome atribuiu uma tarefa';
      case 'comentou':
        return '$usuarioNome adicionou um comentário';
      default:
        return '$usuarioNome realizou ação: $acao';
    }
  }
}

/// Modelo principal do dashboard que agrega todas as informações
class DashboardData {
  final TaskStats taskStats;
  final GroupStats groupStats;
  final List<TaskSummary> minhasTarefas;
  final List<TaskSummary> proximosVencimentos;
  final List<RecentActivity> atividadeRecente;

  DashboardData({
    required this.taskStats,
    required this.groupStats,
    required this.minhasTarefas,
    required this.proximosVencimentos,
    required this.atividadeRecente,
  });
}

/// Repositório para consultas do dashboard
class DashboardRepository {
  final Connection _connection;

  DashboardRepository() : _connection = DatabaseHelper().connection;

  /// Obtém estatísticas de tarefas para um usuário
  Future<TaskStats> getTaskStats(String usuarioId) async {
    final query = '''
      SELECT 
        COUNT(CASE WHEN st.nome = 'Pendente' THEN 1 END) as pendentes,
        COUNT(CASE WHEN st.nome = 'Em Progresso' THEN 1 END) as em_progresso,
        COUNT(CASE WHEN st.nome = 'Concluída' THEN 1 END) as concluidas,
        COUNT(CASE WHEN st.nome = 'Cancelada' THEN 1 END) as canceladas,
        COUNT(*) as total
      FROM tarefas t
      JOIN atribuicoes_tarefa at ON t.id = at.tarefa_id
      JOIN status_tarefa st ON t.status_id = st.id
      WHERE at.usuario_id = @usuario_id AND at.ativo = true;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'usuario_id': usuarioId},
    );

    if (result.isNotEmpty) {
      final row = result.first;
      return TaskStats(
        pendentes: row[0] as int,
        emProgresso: row[1] as int,
        concluidas: row[2] as int,
        canceladas: row[3] as int,
        total: row[4] as int,
      );
    }

    return TaskStats(
      pendentes: 0,
      emProgresso: 0,
      concluidas: 0,
      canceladas: 0,
      total: 0,
    );
  }

  /// Obtém estatísticas de grupos para um usuário
  Future<GroupStats> getGroupStats(String usuarioId) async {
    final query = '''
      SELECT 
        COUNT(*) as total_grupos,
        COUNT(CASE WHEN papel = 'admin' THEN 1 END) as como_admin,
        COUNT(CASE WHEN papel = 'moderador' THEN 1 END) as como_moderador,
        COUNT(CASE WHEN papel = 'membro' THEN 1 END) as como_membro
      FROM usuarios_grupos
      WHERE usuario_id = @usuario_id AND ativo = true;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'usuario_id': usuarioId},
    );

    if (result.isNotEmpty) {
      final row = result.first;
      return GroupStats(
        totalGrupos: row[0] as int,
        comoAdmin: row[1] as int,
        comoModerador: row[2] as int,
        comoMembro: row[3] as int,
      );
    }

    return GroupStats(
      totalGrupos: 0,
      comoAdmin: 0,
      comoModerador: 0,
      comoMembro: 0,
    );
  }

  /// Obtém tarefas atribuídas ao usuário (limitadas)
  Future<List<TaskSummary>> getMinhasTarefas(String usuarioId, {int limit = 10}) async {
    final query = '''
      SELECT 
        t.id, t.titulo, g.nome as grupo_nome, st.nome as status_nome, 
        st.cor as status_cor, t.prioridade, t.data_vencimento, t.data_criacao
      FROM tarefas t
      JOIN atribuicoes_tarefa at ON t.id = at.tarefa_id
      JOIN grupos g ON t.grupo_id = g.id
      JOIN status_tarefa st ON t.status_id = st.id
      WHERE at.usuario_id = @usuario_id AND at.ativo = true
      ORDER BY t.data_criacao DESC
      LIMIT @limit;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'usuario_id': usuarioId, 'limit': limit},
    );

    return result.map((row) => TaskSummary.fromMap({
      'id': row[0],
      'titulo': row[1],
      'grupo_nome': row[2],
      'status_nome': row[3],
      'status_cor': row[4],
      'prioridade': row[5],
      'data_vencimento': row[6],
      'data_criacao': row[7],
    })).toList();
  }

  /// Obtém próximos vencimentos
  Future<List<TaskSummary>> getProximosVencimentos(String usuarioId, {int limit = 5}) async {
    final query = '''
      SELECT 
        t.id, t.titulo, g.nome as grupo_nome, st.nome as status_nome, 
        st.cor as status_cor, t.prioridade, t.data_vencimento, t.data_criacao
      FROM tarefas t
      JOIN atribuicoes_tarefa at ON t.id = at.tarefa_id
      JOIN grupos g ON t.grupo_id = g.id
      JOIN status_tarefa st ON t.status_id = st.id
      WHERE at.usuario_id = @usuario_id AND at.ativo = true
        AND t.data_vencimento IS NOT NULL
        AND st.nome != 'Concluída' AND st.nome != 'Cancelada'
      ORDER BY t.data_vencimento ASC
      LIMIT @limit;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'usuario_id': usuarioId, 'limit': limit},
    );

    return result.map((row) => TaskSummary.fromMap({
      'id': row[0],
      'titulo': row[1],
      'grupo_nome': row[2],
      'status_nome': row[3],
      'status_cor': row[4],
      'prioridade': row[5],
      'data_vencimento': row[6],
      'data_criacao': row[7],
    })).toList();
  }

  /// Obtém atividade recente dos grupos do usuário
  Future<List<RecentActivity>> getAtividadeRecente(String usuarioId, {int limit = 10}) async {
    final query = '''
      SELECT DISTINCT
        a.id, a.acao, a.tipo_entidade, a.entidade_id, 
        u.nome as usuario_nome, a.data_acao
      FROM atividades a
      JOIN usuarios u ON a.usuario_id = u.id
      JOIN usuarios_grupos ug ON a.grupo_id = ug.grupo_id
      WHERE ug.usuario_id = @usuario_id AND ug.ativo = true
      ORDER BY a.data_acao DESC
      LIMIT @limit;
    ''';

    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'usuario_id': usuarioId, 'limit': limit},
    );

    return result.map((row) => RecentActivity.fromMap({
      'id': row[0],
      'acao': row[1],
      'tipo_entidade': row[2],
      'entidade_id': row[3],
      'usuario_nome': row[4],
      'detalhes_texto': null,
      'data_acao': row[5],
    })).toList();
  }

  /// Obtém todos os dados do dashboard em uma única chamada
  Future<DashboardData> getDashboardData(String usuarioId) async {
    final results = await Future.wait([
      getTaskStats(usuarioId),
      getGroupStats(usuarioId),
      getMinhasTarefas(usuarioId),
      getProximosVencimentos(usuarioId),
      getAtividadeRecente(usuarioId),
    ]);

    return DashboardData(
      taskStats: results[0] as TaskStats,
      groupStats: results[1] as GroupStats,
      minhasTarefas: results[2] as List<TaskSummary>,
      proximosVencimentos: results[3] as List<TaskSummary>,
      atividadeRecente: results[4] as List<RecentActivity>,
    );
  }
} 