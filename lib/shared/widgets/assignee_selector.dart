import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

class AssigneeSelector extends StatefulWidget {
  final List<Usuario> availableUsers;
  final List<String> selectedUserIds;
  final Function(List<String>) onSelectionChanged;
  final String title;
  final bool enabled;

  const AssigneeSelector({
    super.key,
    required this.availableUsers,
    required this.selectedUserIds,
    required this.onSelectionChanged,
    this.title = "Responsáveis",
    this.enabled = true,
  });

  @override
  State<AssigneeSelector> createState() => _AssigneeSelectorState();
}

class _AssigneeSelectorState extends State<AssigneeSelector> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedUserIds);
  }

  @override
  void didUpdateWidget(AssigneeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUserIds != widget.selectedUserIds) {
      _selectedIds = List.from(widget.selectedUserIds);
    }
  }

  void _toggleUser(String userId) {
    if (!widget.enabled) return;

    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
    
    widget.onSelectionChanged(_selectedIds);
  }

  Widget _buildUserChip(Usuario usuario) {
    final isSelected = _selectedIds.contains(usuario.id);
    
    return GestureDetector(
      onTap: () => _toggleUser(usuario.id),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8, bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[400],
              child: Text(
                usuario.nome[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              usuario.nome,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 20),
            SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selectedIds.isNotEmpty) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedIds.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        SizedBox(height: 12),
        
        if (widget.availableUsers.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Nenhum membro disponível no grupo",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toque para selecionar/deselecionar:",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  children: widget.availableUsers
                      .map((user) => _buildUserChip(user))
                      .toList(),
                ),
                
                if (_selectedIds.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "${_selectedIds.length} responsáve${_selectedIds.length == 1 ? 'l' : 'is'} selecionado${_selectedIds.length == 1 ? '' : 's'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
} 