import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

class CommentInput extends StatefulWidget {
  final Usuario currentUser;
  final Function(String) onSubmit;
  final String? placeholder;
  final bool enabled;
  final String? initialText;
  final VoidCallback? onCancel;

  const CommentInput({
    super.key,
    required this.currentUser,
    required this.onSubmit,
    this.placeholder,
    this.enabled = true,
    this.initialText,
    this.onCancel,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => 
      _controller.text.trim().isNotEmpty && 
      !_isSubmitting && 
      widget.enabled;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final text = _controller.text.trim();
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(text);
      _controller.clear();
      _focusNode.unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _cancel() {
    _controller.clear();
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialText != null;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          // Cabeçalho se estiver editando
          if (isEditing) ...[
            Row(
              children: [
                Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Editando comentário',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _cancel,
                  child: Text('Cancelar'),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar do usuário
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  widget.currentUser.nome[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Campo de texto
              Expanded(
                child:                   Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLines: null,
                    minLines: 1,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: widget.placeholder ?? 
                          (isEditing ? 'Edite seu comentário...' : 'Escreva um comentário...'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      counterText: '', // Remove contador de caracteres
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => setState(() {}), // Para atualizar botão
                  ),
                ),
              ),
              
              SizedBox(width: 8),
              
              // Botão de enviar
                              Container(
                  decoration: BoxDecoration(
                    color: _canSubmit 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                child: _isSubmitting
                    ? Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _canSubmit ? _submit : null,
                        icon: Icon(
                          isEditing ? Icons.check : Icons.send,
                          color: _canSubmit ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
              ),
            ],
          ),
          
          // Dicas de uso
          if (_focusNode.hasFocus) ...[
            SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 48), // Alinhado com o texto
                Expanded(
                  child:                    Text(
                     'Pressione Enter para enviar • Máximo 1000 caracteres',
                     style: TextStyle(
                       fontSize: 12,
                       color: theme.colorScheme.onSurfaceVariant,
                     ),
                   ),
                ),
                                 Text(
                   '${_controller.text.length}/1000',
                   style: TextStyle(
                     fontSize: 12,
                     color: _controller.text.length > 900 
                         ? Colors.orange 
                         : theme.colorScheme.onSurfaceVariant,
                   ),
                 ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 