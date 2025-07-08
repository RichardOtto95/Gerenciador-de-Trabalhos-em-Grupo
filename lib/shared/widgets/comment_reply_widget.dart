import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/comentario_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

class CommentReplyWidget extends StatelessWidget {
  final ComentarioComAutor comentario;
  final Usuario currentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  const CommentReplyWidget({
    super.key,
    required this.comentario,
    required this.currentUser,
    this.onEdit,
    this.onDelete,
    this.onReply,
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
    
    return Container(
      margin: EdgeInsets.only(left: 32, top: 8, bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da resposta (mais compacto)
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.7),
                child: Text(
                  comentario.nomeAutor[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
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
                            fontSize: 13,
                          ),
                        ),
                        if (_isOwner) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Você',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (comentario.editado) ...[
                          SizedBox(width: 6),
                          Tooltip(
                            message: 'Editado em ${_formatDate(comentario.dataAtualizacao)}',
                            child: Icon(
                              Icons.edit,
                              size: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTimeAgo(comentario.dataCriacao),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Menu de ações (mais compacto)
              if (_isOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 16),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 14),
                          SizedBox(width: 6),
                          Text('Editar', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 14, color: Colors.red),
                          SizedBox(width: 6),
                          Text('Excluir', style: TextStyle(color: Colors.red, fontSize: 13)),
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
          
          SizedBox(height: 8),
          
          // Conteúdo da resposta
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text(
              comentario.conteudo,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          
          SizedBox(height: 6),
          
          // Ações da resposta
          Row(
            children: [
              TextButton.icon(
                onPressed: onReply,
                icon: Icon(Icons.reply, size: 14),
                label: Text('Responder'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size(0, 32),
                ),
              ),
              
              Spacer(),
              
              // Timestamp detalhado (tooltip)
              Tooltip(
                message: 'Criado em ${_formatDate(comentario.dataCriacao)}',
                child: Icon(
                  Icons.access_time,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 