import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/comentario_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/widgets/comment_widget.dart';
import 'package:trabalho_bd/shared/widgets/comment_reply_widget.dart';
import 'package:trabalho_bd/shared/widgets/comment_input.dart';

class CommentThreadWidget extends StatefulWidget {
  final ComentarioHierarquico comentarioHierarquico;
  final Usuario currentUser;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final Function(String, String) onReply;
  final Function(String, String) onEditContent;
  final String? editingCommentId;

  const CommentThreadWidget({
    super.key,
    required this.comentarioHierarquico,
    required this.currentUser,
    required this.onEdit,
    required this.onDelete,
    required this.onReply,
    required this.onEditContent,
    this.editingCommentId,
  });

  @override
  State<CommentThreadWidget> createState() => _CommentThreadWidgetState();
}

class _CommentThreadWidgetState extends State<CommentThreadWidget> {
  String? _replyingToCommentId;

  @override
  Widget build(BuildContext context) {
    final comentario = widget.comentarioHierarquico;
    final isEditingMain = widget.editingCommentId == comentario.id;
    final isReplyingToMain = _replyingToCommentId == comentario.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comentário principal
        if (isEditingMain)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
                         child: CommentInput(
               currentUser: widget.currentUser,
               initialText: comentario.conteudo,
               onSubmit: (novoConteudo) async {
                 await widget.onEditContent(comentario.id, novoConteudo);
               },
              onCancel: () {
                // Cancela a edição - será tratado no widget pai
              },
            ),
          )
        else
                     CommentWidget(
             comentario: comentario.comentario,
             currentUser: widget.currentUser,
             replyCount: comentario.totalRespostas,
             onEdit: () => widget.onEdit(comentario.id),
             onDelete: () => widget.onDelete(comentario.id),
             onReply: () {
               setState(() {
                 _replyingToCommentId = _replyingToCommentId == comentario.id 
                     ? null 
                     : comentario.id;
               });
             },
           ),

        // Input de resposta para comentário principal
        if (isReplyingToMain)
          Container(
            margin: EdgeInsets.only(left: 32, top: 8, bottom: 16),
            child: CommentInput(
              currentUser: widget.currentUser,
              placeholder: 'Responda para ${comentario.nomeAutor}...',
              onSubmit: (conteudo) async {
                await widget.onReply(comentario.id, conteudo);
                setState(() {
                  _replyingToCommentId = null;
                });
              },
              onCancel: () {
                setState(() {
                  _replyingToCommentId = null;
                });
              },
            ),
          ),

        // Respostas aninhadas
        if (comentario.respostas.isNotEmpty) ...[
          SizedBox(height: 8),
          ...comentario.respostas.map((resposta) {
            final isEditingReply = widget.editingCommentId == resposta.id;
            final isReplyingToReply = _replyingToCommentId == resposta.id;

            return Column(
              children: [
                // Resposta
                if (isEditingReply)
                  Container(
                    margin: EdgeInsets.only(left: 32, bottom: 12),
                                         child: CommentInput(
                       currentUser: widget.currentUser,
                       initialText: resposta.conteudo,
                       onSubmit: (novoConteudo) async {
                         await widget.onEditContent(resposta.id, novoConteudo);
                       },
                      onCancel: () {
                        // Cancela a edição - será tratado no widget pai
                      },
                    ),
                  )
                else
                  CommentReplyWidget(
                    comentario: resposta.comentario,
                    currentUser: widget.currentUser,
                    onEdit: () => widget.onEdit(resposta.id),
                    onDelete: () => widget.onDelete(resposta.id),
                    onReply: () {
                      setState(() {
                        _replyingToCommentId = _replyingToCommentId == resposta.id 
                            ? null 
                            : resposta.id;
                      });
                    },
                  ),

                // Input de resposta para resposta
                if (isReplyingToReply)
                  Container(
                    margin: EdgeInsets.only(left: 64, top: 8, bottom: 8),
                    child: CommentInput(
                      currentUser: widget.currentUser,
                      placeholder: 'Responda para ${resposta.nomeAutor}...',
                      onSubmit: (conteudo) async {
                        await widget.onReply(resposta.id, conteudo);
                        setState(() {
                          _replyingToCommentId = null;
                        });
                      },
                      onCancel: () {
                        setState(() {
                          _replyingToCommentId = null;
                        });
                      },
                    ),
                  ),

                // Respostas das respostas (recursivo)
                if (resposta.respostas.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(left: 16),
                    child: CommentThreadWidget(
                      comentarioHierarquico: resposta,
                      currentUser: widget.currentUser,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onReply: widget.onReply,
                      onEditContent: widget.onEditContent,
                      editingCommentId: widget.editingCommentId,
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ],
    );
  }
} 