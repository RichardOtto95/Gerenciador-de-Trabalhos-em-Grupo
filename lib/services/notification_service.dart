import 'package:trabalho_bd/db/models/notificacao_model.dart';
import 'package:trabalho_bd/db/models/preferencia_notificacao_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/comentario_model.dart';

/// Serviço para criação automática de notificações do sistema.
class NotificationService {
  final NotificacaoRepository _notificacaoRepo;
  final PreferenciaNotificacaoRepository _preferenciaRepo;

  NotificationService()
      : _notificacaoRepo = NotificacaoRepository(),
        _preferenciaRepo = PreferenciaNotificacaoRepository();

  /// Cria notificação quando uma tarefa é atribuída a um usuário.
  Future<void> criarNotificacaoTarefaAtribuida({
    required String usuarioId,
    required String atribuidorId,
    required String tarefaId,
    required String tituloTarefa,
    required String grupoId,
    required String atribuidorNome,
  }) async {
    // Verifica se o usuário quer receber este tipo de notificação
    final deveNotificar = await _preferenciaRepo.shouldNotify(
      usuarioId,
      'tarefa_atribuida',
      grupoId,
    );

    if (!deveNotificar) return;

    final notificacao = Notificacao(
      usuarioId: usuarioId,
      tipo: 'tarefa_atribuida',
      titulo: 'Nova tarefa atribuída',
      mensagem: '$atribuidorNome atribuiu a tarefa "$tituloTarefa" para você.',
      entidadeTipo: 'tarefa',
      entidadeId: tarefaId,
    );

    await _notificacaoRepo.createNotificacao(notificacao);
  }

  /// Cria notificação quando uma tarefa está próxima do vencimento.
  Future<void> criarNotificacaoTarefaVencendo({
    required String usuarioId,
    required String tarefaId,
    required String tituloTarefa,
    required String grupoId,
    required DateTime dataVencimento,
  }) async {
    final deveNotificar = await _preferenciaRepo.shouldNotify(
      usuarioId,
      'tarefa_vencendo',
      grupoId,
    );

    if (!deveNotificar) return;

    final diasRestantes = dataVencimento.difference(DateTime.now()).inDays;
    final mensagem = diasRestantes == 0
        ? 'A tarefa "$tituloTarefa" vence hoje!'
        : 'A tarefa "$tituloTarefa" vence em $diasRestantes dias.';

    final notificacao = Notificacao(
      usuarioId: usuarioId,
      tipo: 'tarefa_vencendo',
      titulo: 'Tarefa próxima do vencimento',
      mensagem: mensagem,
      entidadeTipo: 'tarefa',
      entidadeId: tarefaId,
    );

    await _notificacaoRepo.createNotificacao(notificacao);
  }

  /// Cria notificação quando um comentário é adicionado a uma tarefa.
  Future<void> criarNotificacaoComentarioAdicionado({
    required String usuarioId,
    required String autorId,
    required String autorNome,
    required String tarefaId,
    required String tituloTarefa,
    required String grupoId,
    required String comentarioId,
  }) async {
    // Não notifica o próprio autor do comentário
    if (usuarioId == autorId) return;

    final deveNotificar = await _preferenciaRepo.shouldNotify(
      usuarioId,
      'comentario_adicionado',
      grupoId,
    );

    if (!deveNotificar) return;

    final notificacao = Notificacao(
      usuarioId: usuarioId,
      tipo: 'comentario_adicionado',
      titulo: 'Novo comentário',
      mensagem: '$autorNome comentou na tarefa "$tituloTarefa".',
      entidadeTipo: 'tarefa',
      entidadeId: tarefaId,
    );

    await _notificacaoRepo.createNotificacao(notificacao);
  }

  /// Cria notificação quando uma tarefa é concluída.
  Future<void> criarNotificacaoTarefaCompletada({
    required String usuarioId,
    required String completadorId,
    required String completadorNome,
    required String tarefaId,
    required String tituloTarefa,
    required String grupoId,
  }) async {
    // Não notifica quem completou a tarefa
    if (usuarioId == completadorId) return;

    final deveNotificar = await _preferenciaRepo.shouldNotify(
      usuarioId,
      'tarefa_completada',
      grupoId,
    );

    if (!deveNotificar) return;

    final notificacao = Notificacao(
      usuarioId: usuarioId,
      tipo: 'tarefa_completada',
      titulo: 'Tarefa concluída',
      mensagem: '$completadorNome concluiu a tarefa "$tituloTarefa".',
      entidadeTipo: 'tarefa',
      entidadeId: tarefaId,
    );

    await _notificacaoRepo.createNotificacao(notificacao);
  }

  /// Cria notificação quando um usuário é convidado para um grupo.
  Future<void> criarNotificacaoConviteGrupo({
    required String usuarioId,
    required String convidadorId,
    required String convidadorNome,
    required String grupoId,
    required String nomeGrupo,
  }) async {
    final deveNotificar = await _preferenciaRepo.shouldNotify(
      usuarioId,
      'convite_grupo',
      null, // Convite é sempre global
    );

    if (!deveNotificar) return;

    final notificacao = Notificacao(
      usuarioId: usuarioId,
      tipo: 'convite_grupo',
      titulo: 'Convite para grupo',
      mensagem: '$convidadorNome te convidou para o grupo "$nomeGrupo".',
      entidadeTipo: 'grupo',
      entidadeId: grupoId,
    );

    await _notificacaoRepo.createNotificacao(notificacao);
  }

  /// Notifica todos os usuários de um grupo sobre um evento.
  Future<void> notificarGrupo({
    required String grupoId,
    required List<String> usuarioIds,
    required String tipo,
    required String titulo,
    required String mensagem,
    String? entidadeTipo,
    String? entidadeId,
    String? autorId, // Para evitar autonotificação
  }) async {
    for (final usuarioId in usuarioIds) {
      // Não notifica o autor da ação
      if (autorId != null && usuarioId == autorId) continue;

      final deveNotificar = await _preferenciaRepo.shouldNotify(
        usuarioId,
        tipo,
        grupoId,
      );

      if (!deveNotificar) continue;

      final notificacao = Notificacao(
        usuarioId: usuarioId,
        tipo: tipo,
        titulo: titulo,
        mensagem: mensagem,
        entidadeTipo: entidadeTipo,
        entidadeId: entidadeId,
      );

      await _notificacaoRepo.createNotificacao(notificacao);
    }
  }

  /// Verifica tarefas que estão próximas do vencimento e cria notificações.
  Future<void> verificarTarefasVencendo() async {
    try {
      final tarefaRepo = TarefaRepository();
      final todasTarefas = await tarefaRepo.getAllTarefas();
      final agora = DateTime.now();

      for (final tarefa in todasTarefas) {
        if (tarefa.dataVencimento == null) continue;
        if (tarefa.statusId == 3) continue; // Pula tarefas concluídas

        final diasRestantes = tarefa.dataVencimento!.difference(agora).inDays;
        
        // Notifica se falta 1 dia ou está vencendo hoje
        if (diasRestantes <= 1 && diasRestantes >= 0) {
          // Busca usuários atribuídos à tarefa
          // TODO: Implementar busca de usuários atribuídos
          // Por enquanto, notifica apenas o criador
          await criarNotificacaoTarefaVencendo(
            usuarioId: tarefa.criadorId,
            tarefaId: tarefa.id,
            tituloTarefa: tarefa.titulo,
            grupoId: tarefa.grupoId,
            dataVencimento: tarefa.dataVencimento!,
          );
        }
      }
    } catch (e) {
      print('Erro ao verificar tarefas vencendo: $e');
    }
  }

  /// Marca uma notificação como lida.
  Future<void> marcarComoLida(String notificacaoId) async {
    await _notificacaoRepo.markNotificacaoAsRead(notificacaoId);
  }

  /// Marca várias notificações como lidas.
  Future<void> marcarVariasComoLidas(List<String> notificacaoIds) async {
    for (final id in notificacaoIds) {
      await _notificacaoRepo.markNotificacaoAsRead(id);
    }
  }

  /// Busca notificações não lidas de um usuário.
  Future<List<Notificacao>> buscarNotificacesNaoLidas(String usuarioId) async {
    return await _notificacaoRepo.getNotificacoesByUsuario(usuarioId, lida: false);
  }

  /// Busca todas as notificações de um usuário.
  Future<List<Notificacao>> buscarTodasNotificacoes(String usuarioId) async {
    return await _notificacaoRepo.getNotificacoesByUsuario(usuarioId);
  }

  /// Conta notificações não lidas.
  Future<int> contarNotificacesNaoLidas(String usuarioId) async {
    final notificacoes = await _notificacaoRepo.getNotificacoesByUsuario(usuarioId, lida: false);
    return notificacoes.length;
  }

  /// Remove notificações antigas para manter o banco limpo.
  Future<void> limparNotificacoesAntigas({int diasParaRemover = 30}) async {
    try {
      final dataLimite = DateTime.now().subtract(Duration(days: diasParaRemover));
      // TODO: Implementar query para deletar notificações antigas
      print('Limpeza de notificações antigas: antes de $dataLimite');
    } catch (e) {
      print('Erro ao limpar notificações antigas: $e');
    }
  }
} 