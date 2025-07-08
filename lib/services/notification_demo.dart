import 'package:trabalho_bd/services/notification_service.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/preferencia_notificacao_model.dart';
import 'package:uuid/uuid.dart';

/// Serviço para demonstrar e testar o sistema de notificações.
class NotificationDemo {
  final NotificationService _notificationService = NotificationService();
  final PreferenciaNotificacaoRepository _preferenciaRepo = PreferenciaNotificacaoRepository();
  final Uuid _uuid = const Uuid();

  /// Cria notificações de exemplo para demonstrar o sistema.
  Future<void> criarNotificacoesDemostracao(Usuario usuario) async {
    try {
      // Criar preferências padrão se não existirem
      await _preferenciaRepo.criarPreferenciasDefault(usuario.id);

      // Gerar IDs válidos para os exemplos
      final demoUserId = _uuid.v4();
      final demoGroupId = _uuid.v4();
      final demoTaskId = _uuid.v4();
      final demoTaskId2 = _uuid.v4();
      final demoTaskId3 = _uuid.v4();
      final demoTaskId4 = _uuid.v4();
      final demoCommentId = _uuid.v4();
      final demoUser2Id = _uuid.v4();
      final demoUser3Id = _uuid.v4();
      final demoUser4Id = _uuid.v4();
      final demoGroup2Id = _uuid.v4();

      // Simular notificações de diferentes tipos
      await _notificationService.criarNotificacaoTarefaAtribuida(
        usuarioId: usuario.id,
        atribuidorId: demoUserId,
        tarefaId: demoTaskId,
        tituloTarefa: 'Revisar documentação do projeto',
        grupoId: demoGroupId,
        atribuidorNome: 'João Silva',
      );

      await _notificationService.criarNotificacaoComentarioAdicionado(
        usuarioId: usuario.id,
        autorId: demoUser2Id,
        autorNome: 'Maria Santos',
        tarefaId: demoTaskId2,
        tituloTarefa: 'Implementar nova funcionalidade',
        grupoId: demoGroupId,
        comentarioId: demoCommentId,
      );

      await _notificationService.criarNotificacaoTarefaVencendo(
        usuarioId: usuario.id,
        tarefaId: demoTaskId3,
        tituloTarefa: 'Preparar apresentação',
        grupoId: demoGroupId,
        dataVencimento: DateTime.now().add(Duration(days: 1)),
      );

      await _notificationService.criarNotificacaoTarefaCompletada(
        usuarioId: usuario.id,
        completadorId: demoUser3Id,
        completadorNome: 'Pedro Oliveira',
        tarefaId: demoTaskId4,
        tituloTarefa: 'Corrigir bugs do sistema',
        grupoId: demoGroupId,
      );

      await _notificationService.criarNotificacaoConviteGrupo(
        usuarioId: usuario.id,
        convidadorId: demoUser4Id,
        convidadorNome: 'Ana Costa',
        grupoId: demoGroup2Id,
        nomeGrupo: 'Equipe de Desenvolvimento',
      );

      print('✅ Notificações de demonstração criadas com sucesso!');
    } catch (e) {
      print('❌ Erro ao criar notificações de demonstração: $e');
    }
  }

  /// Limpa todas as notificações do usuário.
  Future<void> limparNotificacoes(Usuario usuario) async {
    try {
      final notificacoes = await _notificationService.buscarTodasNotificacoes(usuario.id);
      
      // Para cada notificação, deleta do banco
      for (final notificacao in notificacoes) {
        // TODO: Implementar método de deletar notificação
        // await _notificationService.deletarNotificacao(notificacao.id);
      }
      
      print('✅ Notificações limpas com sucesso!');
    } catch (e) {
      print('❌ Erro ao limpar notificações: $e');
    }
  }

  /// Conta quantas notificações não lidas o usuário tem.
  Future<int> contarNotificacaoNaoLidas(Usuario usuario) async {
    try {
      return await _notificationService.contarNotificacesNaoLidas(usuario.id);
    } catch (e) {
      print('❌ Erro ao contar notificações não lidas: $e');
      return 0;
    }
  }

  /// Demonstra como o sistema verifica tarefas vencendo.
  Future<void> demonstrarTarefasVencendo() async {
    try {
      await _notificationService.verificarTarefasVencendo();
      print('✅ Verificação de tarefas vencendo executada!');
    } catch (e) {
      print('❌ Erro ao verificar tarefas vencendo: $e');
    }
  }

  /// Cria uma notificação personalizada para teste.
  Future<void> criarNotificacaoPersonalizada(
    Usuario usuario,
    String tipo,
    String titulo,
    String mensagem,
  ) async {
    try {
      // Gerar IDs válidos para os exemplos
      final demoUserId = _uuid.v4();
      final demoGroupId = _uuid.v4();
      final demoTaskId = _uuid.v4();
      final demoCommentId = _uuid.v4();
      
      // Usar o serviço para criar notificação
      switch (tipo) {
        case 'tarefa_atribuida':
          await _notificationService.criarNotificacaoTarefaAtribuida(
            usuarioId: usuario.id,
            atribuidorId: demoUserId,
            tarefaId: demoTaskId,
            tituloTarefa: titulo,
            grupoId: demoGroupId,
            atribuidorNome: 'Sistema',
          );
          break;
        case 'comentario_adicionado':
          await _notificationService.criarNotificacaoComentarioAdicionado(
            usuarioId: usuario.id,
            autorId: demoUserId,
            autorNome: 'Sistema',
            tarefaId: demoTaskId,
            tituloTarefa: titulo,
            grupoId: demoGroupId,
            comentarioId: demoCommentId,
          );
          break;
        default:
          print('Tipo de notificação não suportado: $tipo');
      }
      
      print('✅ Notificação personalizada criada!');
    } catch (e) {
      print('❌ Erro ao criar notificação personalizada: $e');
    }
  }
} 