import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/notificacao_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/services/notification_service.dart';
import 'package:trabalho_bd/services/notification_demo.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  final Usuario usuario;
  
  const NotificationPage({Key? key, required this.usuario}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final NotificationDemo _notificationDemo = NotificationDemo();
  List<Notificacao> _notificacoes = [];
  bool _isLoading = true;
  bool _showOnlyUnread = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  Future<void> _carregarNotificacoes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Notificacao> notificacoes;
      if (_showOnlyUnread) {
        notificacoes = await _notificationService.buscarNotificacesNaoLidas(widget.usuario.id);
      } else {
        notificacoes = await _notificationService.buscarTodasNotificacoes(widget.usuario.id);
      }

      final unreadCount = await _notificationService.contarNotificacesNaoLidas(widget.usuario.id);

      setState(() {
        _notificacoes = notificacoes;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao carregar notificações: $e');
      }
    }
  }

  Future<void> _marcarComoLida(Notificacao notificacao) async {
    if (notificacao.lida) return;

    try {
      await _notificationService.marcarComoLida(notificacao.id);
      await _carregarNotificacoes();
      
      if (mounted) {
        mostrarSnackBar(context, 'Notificação marcada como lida');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao marcar notificação como lida: $e');
      }
    }
  }

  Future<void> _marcarTodasComoLidas() async {
    try {
      final naoLidas = _notificacoes.where((n) => !n.lida).toList();
      if (naoLidas.isEmpty) return;

      final ids = naoLidas.map((n) => n.id).toList();
      await _notificationService.marcarVariasComoLidas(ids);
      await _carregarNotificacoes();
      
      if (mounted) {
        mostrarSnackBar(context, '${naoLidas.length} notificações marcadas como lidas');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao marcar todas como lidas: $e');
      }
    }
  }

  Future<void> _criarNotificacoesTeste() async {
    try {
      await _notificationDemo.criarNotificacoesDemostracao(widget.usuario);
      await _carregarNotificacoes();
      
      if (mounted) {
        mostrarSnackBar(context, 'Notificações de teste criadas com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao criar notificações de teste: $e');
      }
    }
  }

  void _navegarParaEntidade(Notificacao notificacao) {
    if (notificacao.entidadeTipo == null || notificacao.entidadeId == null) return;

    switch (notificacao.entidadeTipo) {
      case 'tarefa':
        Navigator.pushNamed(
          context,
          '/task-detail',
          arguments: {
            'tarefaId': notificacao.entidadeId,
            'usuario': widget.usuario,
          },
        );
        break;
      case 'grupo':
        Navigator.pushNamed(
          context,
          '/group-detail',
          arguments: {
            'grupoId': notificacao.entidadeId,
            'usuario': widget.usuario,
          },
        );
        break;
    }
  }

  IconData _getIconByType(String tipo) {
    switch (tipo) {
      case 'tarefa_atribuida':
        return Icons.assignment;
      case 'tarefa_vencendo':
        return Icons.warning;
      case 'comentario_adicionado':
        return Icons.comment;
      case 'tarefa_completada':
        return Icons.check_circle;
      case 'convite_grupo':
        return Icons.group_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorByType(String tipo) {
    switch (tipo) {
      case 'tarefa_atribuida':
        return Colors.blue;
      case 'tarefa_vencendo':
        return Colors.orange;
      case 'comentario_adicionado':
        return Colors.green;
      case 'tarefa_completada':
        return Colors.teal;
      case 'convite_grupo':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inMinutes < 1) {
      return 'Agora';
    } else if (diferenca.inMinutes < 60) {
      return '${diferenca.inMinutes}m';
    } else if (diferenca.inHours < 24) {
      return '${diferenca.inHours}h';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays}d';
    } else {
      return DateFormat('dd/MM').format(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _marcarTodasComoLidas,
              child: Text(
                'Marcar todas como lidas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'preferences':
                  Navigator.pushNamed(
                    context,
                    '/notification-preferences',
                    arguments: widget.usuario,
                  );
                  break;
                case 'create_demo':
                  _criarNotificacoesTeste();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'preferences',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'create_demo',
                child: Row(
                  children: [
                    Icon(Icons.add_alert),
                    SizedBox(width: 8),
                    Text('Criar Notificações de Teste'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de notificações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Todas'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Não lidas ($_unreadCount)'),
                        icon: Icon(Icons.circle),
                      ),
                    ],
                    selected: {_showOnlyUnread},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _showOnlyUnread = selection.first;
                      });
                      _carregarNotificacoes();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Lista de notificações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notificacoes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showOnlyUnread 
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_none_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyUnread 
                                  ? 'Nenhuma notificação não lida'
                                  : 'Nenhuma notificação',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showOnlyUnread 
                                  ? 'Você está em dia!'
                                  : 'Você receberá notificações sobre\nsuas tarefas e grupos aqui.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarNotificacoes,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _notificacoes.length,
                          itemBuilder: (context, index) {
                            final notificacao = _notificacoes[index];
                            return _buildNotificationItem(notificacao);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Notificacao notificacao) {
    final isUnread = !notificacao.lida;
    final color = _getColorByType(notificacao.tipo);
    final icon = _getIconByType(notificacao.tipo);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notificacao.titulo,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
            color: isUnread 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notificacao.mensagem,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatarData(notificacao.dataCriacao),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'read':
                _marcarComoLida(notificacao);
                break;
              case 'navigate':
                _navegarParaEntidade(notificacao);
                break;
            }
          },
          itemBuilder: (context) => [
            if (isUnread)
              const PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Marcar como lida'),
                  ],
                ),
              ),
            if (notificacao.entidadeTipo != null)
              const PopupMenuItem(
                value: 'navigate',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new),
                    SizedBox(width: 8),
                    Text('Abrir'),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          if (isUnread) {
            _marcarComoLida(notificacao);
          }
          _navegarParaEntidade(notificacao);
        },
      ),
    );
  }
} 