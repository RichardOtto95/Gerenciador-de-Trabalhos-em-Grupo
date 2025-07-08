import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/comentario_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

class CommentWidget extends StatelessWidget {
  final ComentarioComAutor comentario;
  final Usuario currentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final int? replyCount;

  const CommentWidget({
    super.key,
    required this.comentario,
    required this.currentUser,
    this.onEdit,
    this.onDelete,
    this.onReply,
    this.replyCount,
  });

  bool get _isOwner => comentario.autorId == currentUser.id;

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays == 1 ? '' : 's'} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours == 1 ? '' : 's'} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'} atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/"
           "${dateTime.month.toString().padLeft(2, '0')}/"
           "${dateTime.year} às "
           "${dateTime.hour.toString().padLeft(2, '0')}:"
           "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do comentário
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    comentario.nomeAutor[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comentario.nomeAutor,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (_isOwner) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Você',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (comentario.editado) ...[
                            SizedBox(width: 8),
                                                         Tooltip(
                               message: 'Editado em ${_formatDate(comentario.dataAtualizacao)}',
                               child: Icon(
                                 Icons.edit,
                                 size: 12,
                                 color: theme.colorScheme.onSurfaceVariant,
                               ),
                             ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(comentario.dataCriacao),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu de ações
                if (_isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Conteúdo do comentário
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              child: Text(
                comentario.conteudo,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
                        // Ações do comentário
            Row(
              children: [
                TextButton.icon(
                  onPressed: onReply,
                  icon: Icon(Icons.reply, size: 16),
                  label: Text('Responder'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                
                // Contador de respostas
                if (replyCount != null && replyCount! > 0) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$replyCount',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                Spacer(),
                
                // Timestamp detalhado (tooltip)
                Tooltip(
                  message: 'Criado em ${_formatDate(comentario.dataCriacao)}',
                  child: Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 