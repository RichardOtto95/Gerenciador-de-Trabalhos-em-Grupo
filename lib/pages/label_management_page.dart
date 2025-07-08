import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/rotulo_model.dart';
import 'package:trabalho_bd/db/models/atividade_model.dart';

class LabelManagementPage extends StatefulWidget {
  final String grupoId;
  final String usuarioId;

  const LabelManagementPage({
    super.key,
    required this.grupoId,
    required this.usuarioId,
  });

  @override
  State<LabelManagementPage> createState() => _LabelManagementPageState();
}

class _LabelManagementPageState extends State<LabelManagementPage> {
  final RotuloRepository _rotuloRepository = RotuloRepository();
  final AtividadeRepository _atividadeRepository = AtividadeRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Rotulo> _rotulos = [];
  List<Rotulo> _rotulosFiltered = [];
  Map<String, int> _estatisticas = {};
  bool _isLoading = true;

  // Cores predefinidas para rótulos
  final List<Color> _coresPredefinidas = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _loadRotulos();
    _loadEstatisticas();
    _searchController.addListener(_filterRotulos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRotulos() async {
    try {
      final rotulos = await _rotuloRepository.getRotulosByGrupoId(
        widget.grupoId,
      );
      setState(() {
        _rotulos = rotulos;
        _rotulosFiltered = rotulos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar rótulos: $e')));
      }
    }
  }

  Future<void> _loadEstatisticas() async {
    try {
      final estatisticas = await _rotuloRepository.getEstatisticasRotulosGrupo(
        widget.grupoId,
      );
      setState(() {
        _estatisticas = estatisticas;
      });
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  void _filterRotulos() {
    final termo = _searchController.text.toLowerCase();
    setState(() {
      _rotulosFiltered = _rotulos.where((rotulo) {
        return rotulo.nome.toLowerCase().contains(termo) ||
            (rotulo.descricao?.toLowerCase().contains(termo) ?? false);
      }).toList();
    });
  }

  Future<void> _showCreateEditDialog({Rotulo? rotulo}) async {
    final isEditing = rotulo != null;
    final titleController = TextEditingController(text: rotulo?.nome ?? '');
    final descriptionController = TextEditingController(
      text: rotulo?.descricao ?? '',
    );
    Color selectedColor = rotulo != null
        ? _stringToColor(rotulo.cor)
        : _coresPredefinidas[0];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Rótulo' : 'Criar Rótulo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Rótulo *',
                    hintText: 'Ex: Urgente, Bug, Feature...',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    hintText: 'Descreva o uso deste rótulo...',
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cor do Rótulo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _coresPredefinidas.map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.grey,
                            width: selectedColor == color ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Preview do rótulo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selectedColor),
                  ),
                  child: Text(
                    titleController.text.isEmpty
                        ? 'Preview'
                        : titleController.text,
                    style: TextStyle(
                      color: selectedColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome do rótulo é obrigatório'),
                    ),
                  );
                  return;
                }

                try {
                  final nomeRotulo = titleController.text.trim();
                  final corHex = _colorToString(selectedColor);

                  // Verificar nome único
                  bool nomeJaExiste = false;
                  if (isEditing) {
                    nomeJaExiste = await _rotuloRepository
                        .hasRotuloWithSameNameForEdit(
                          nomeRotulo,
                          widget.grupoId,
                          rotulo.id,
                        );
                  } else {
                    nomeJaExiste = await _rotuloRepository
                        .hasRotuloWithSameName(nomeRotulo, widget.grupoId);
                  }

                  if (nomeJaExiste) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Já existe um rótulo com esse nome no grupo',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  if (isEditing) {
                    rotulo.nome = nomeRotulo;
                    rotulo.descricao = descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim();
                    rotulo.cor = corHex;
                    await _rotuloRepository.updateRotulo(rotulo);
                  } else {
                    final novoRotulo = Rotulo(
                      nome: nomeRotulo,
                      descricao: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      cor: corHex,
                      grupoId: widget.grupoId,
                    );
                    await _rotuloRepository.createRotulo(novoRotulo);
                  }

                  // Log da atividade
                  await _atividadeRepository.createAtividade(
                    Atividade(
                      usuarioId: widget.usuarioId,
                      acao: isEditing ? 'atualizou' : 'criou',
                      entidadeId: widget.grupoId,
                      tipoEntidade: 'grupo',
                      detalhes:
                          '{"rotulo": "${titleController.text.trim()}", "acao": "${isEditing ? 'editou' : 'criou'} rótulo"}',
                    ),
                  );

                  Navigator.pop(context);
                  _loadRotulos();
                  _loadEstatisticas();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Rótulo ${isEditing ? 'editado' : 'criado'} com sucesso!',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erro ao ${isEditing ? 'editar' : 'criar'} rótulo: $e',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Rotulo rotulo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja realmente excluir o rótulo "${rotulo.nome}"?'),
            const SizedBox(height: 8),
            Text(
              'Esta ação não pode ser desfeita e removerá o rótulo de todas as tarefas.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _rotuloRepository.deleteRotulo(rotulo.id);

        // Log da atividade
        await _atividadeRepository.createAtividade(
          Atividade(
            usuarioId: widget.usuarioId,
            acao: 'deletou',
            entidadeId: widget.grupoId,
            tipoEntidade: 'grupo',
            detalhes: '{"rotulo": "${rotulo.nome}", "acao": "deletou rótulo"}',
          ),
        );

        _loadRotulos();
        _loadEstatisticas();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rótulo excluído com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao excluir rótulo: $e')));
        }
      }
    }
  }

  Color _stringToColor(String colorString) {
    final hex = colorString.replaceFirst('#', '');
    final int value = int.parse(hex, radix: 16);
    return Color(value + 0xFF000000);
  }

  String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rótulos do Grupo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Estatísticas
                if (_estatisticas.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_estatisticas['total_rotulos'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Rótulos'),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_estatisticas['total_tarefas_com_rotulos'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Aplicações'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Barra de pesquisa
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar rótulos',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Lista de rótulos
                Expanded(
                  child: _rotulosFiltered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.label_outline,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _rotulos.isEmpty
                                    ? 'Nenhum rótulo criado ainda'
                                    : 'Nenhum rótulo encontrado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_rotulos.isEmpty)
                                ElevatedButton(
                                  onPressed: () => _showCreateEditDialog(),
                                  child: const Text('Criar Primeiro Rótulo'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _rotulosFiltered.length,
                          itemBuilder: (context, index) {
                            final rotulo = _rotulosFiltered[index];
                            final cor = _stringToColor(rotulo.cor);
                            final quantidadeTarefas =
                                _estatisticas[rotulo.nome] ?? 0;
                            final isDarkMode =
                                Theme.of(context).brightness == Brightness.dark;
                            final corAjustada = isDarkMode
                                ? Color.lerp(cor, Colors.white, 0.2)!
                                : cor;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: corAjustada.withOpacity(
                                      isDarkMode ? 0.3 : 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: corAjustada),
                                  ),
                                  child: Icon(Icons.label, color: corAjustada),
                                ),
                                title: Text(
                                  rotulo.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (rotulo.descricao != null)
                                      Text(rotulo.descricao!),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$quantidadeTarefas tarefa${quantidadeTarefas != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _showCreateEditDialog(rotulo: rotulo),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                      onPressed: () => _confirmDelete(rotulo),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
