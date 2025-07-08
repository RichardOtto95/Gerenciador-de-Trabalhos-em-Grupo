import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/dashboard_model.dart';
import 'package:intl/intl.dart';

/// Widget para card de estatísticas com ícone e cores
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget para grid de estatísticas de tarefas
class TaskStatsGrid extends StatelessWidget {
  final TaskStats stats;
  final VoidCallback? onTap;

  const TaskStatsGrid({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatsCard(
          title: 'Pendentes',
          value: stats.pendentes.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
          onTap: onTap,
        ),
        StatsCard(
          title: 'Em Progresso',
          value: stats.emProgresso.toString(),
          icon: Icons.work,
          color: Colors.blue,
          onTap: onTap,
        ),
        StatsCard(
          title: 'Concluídas',
          value: stats.concluidas.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: onTap,
        ),
        StatsCard(
          title: 'Total',
          value: stats.total.toString(),
          icon: Icons.assignment,
          color: Colors.grey[700]!,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// Widget para exibir informações de uma tarefa resumida
class TaskSummaryTile extends StatelessWidget {
  final TaskSummary task;
  final VoidCallback? onTap;

  const TaskSummaryTile({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _parseColor(task.statusCor) ?? Colors.grey;
    final Color prioridadeColor = _getPriorityColor(task.prioridade);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.statusNome == 'Concluída' 
              ? TextDecoration.lineThrough 
              : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.group, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.grupoNome,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.statusNome,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: prioridadeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.prioridadeTexto,
                    style: TextStyle(
                      fontSize: 10,
                      color: prioridadeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (task.dataVencimento != null) ...[
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    task.vencida ? Icons.warning : Icons.schedule,
                    size: 14,
                    color: task.vencida ? Colors.red : Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(task.dataVencimento!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.vencida ? Colors.red : Colors.grey[600],
                      fontWeight: task.vencida ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: task.vencida
          ? Icon(Icons.error, color: Colors.red, size: 20)
          : null,
      ),
    );
  }

  Color _getPriorityColor(int? prioridade) {
    switch (prioridade) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Widget para lista de atividades recentes
class RecentActivityWidget extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivityWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8),
            Text(
              'Nenhuma atividade recente',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final timeAgo = _getTimeAgo(activity.dataAcao);
        
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: _getActivityColor(activity.acao).withOpacity(0.2),
            child: Icon(
              _getActivityIcon(activity.acao, activity.tipoEntidade),
              size: 18,
              color: _getActivityColor(activity.acao),
            ),
          ),
          title: Text(
            activity.descricao,
            style: TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        );
      },
    );
  }

  IconData _getActivityIcon(String acao, String tipoEntidade) {
    switch (acao) {
      case 'criou':
        switch (tipoEntidade) {
          case 'tarefa': return Icons.add_task;
          case 'grupo': return Icons.group_add;
          case 'comentario': return Icons.comment;
          case 'anexo': return Icons.attach_file;
          default: return Icons.add;
        }
      case 'atualizou':
        return Icons.edit;
      case 'concluiu':
        return Icons.check_circle;
      case 'atribuiu':
        return Icons.person_add;
      case 'comentou':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String acao) {
    switch (acao) {
      case 'criou': return Colors.green;
      case 'atualizou': return Colors.blue;
      case 'concluiu': return Colors.purple;
      case 'atribuiu': return Colors.orange;
      case 'comentou': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}

/// Widget para seção do dashboard com título e ação
class DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final IconData? icon;

  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.actionText,
    this.onActionPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionText != null && onActionPressed != null)
                TextButton.icon(
                  onPressed: onActionPressed,
                  icon: Icon(Icons.arrow_forward, size: 16),
                  label: Text(actionText!),
                  style: TextButton.styleFrom(
                    textStyle: TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Widget para card de resumo de grupos
class GroupStatsCard extends StatelessWidget {
  final GroupStats stats;
  final VoidCallback? onTap;

  const GroupStatsCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meus Grupos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${stats.totalGrupos} grupos',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.group,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRoleStats(context, 'Admin', stats.comoAdmin, Colors.red),
                  _buildRoleStats(context, 'Moderador', stats.comoModerador, Colors.orange),
                  _buildRoleStats(context, 'Membro', stats.comoMembro, Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleStats(BuildContext context, String role, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          role,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 