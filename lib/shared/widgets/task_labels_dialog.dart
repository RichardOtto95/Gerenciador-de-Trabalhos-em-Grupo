import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/rotulo_model.dart';
import 'package:trabalho_bd/db/models/tarefa_rotulo.dart';
import 'package:trabalho_bd/db/models/atividade_model.dart';

class TaskLabelsDialog extends StatefulWidget {
  final String tarefaId;
  final String grupoId;
  final String usuarioId;
  final String tarefaTitulo;

  const TaskLabelsDialog({
    super.key,
    required this.tarefaId,
    required this.grupoId,
    required this.usuarioId,
    required this.tarefaTitulo,
  });

  @override
  State<TaskLabelsDialog> createState() => _TaskLabelsDialogState();
}

class _TaskLabelsDialogState extends State<TaskLabelsDialog> {
  final RotuloRepository _rotuloRepository = RotuloRepository();
  final TarefaRotuloRepository _tarefaRotuloRepository =
      TarefaRotuloRepository();
  final AtividadeRepository _atividadeRepository = AtividadeRepository();

  List<Rotulo> _rotulosDisponiveis = [];
  List<String> _rotulosAplicados = [];
  List<String> _rotulosSelected = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Carregar rótulos disponíveis do grupo
      final rotulosDisponiveis = await _rotuloRepository.getRotulosByGrupoId(
        widget.grupoId,
      );

      // Carregar rótulos já aplicados à tarefa
      final rotulosAplicados = await _tarefaRotuloRepository.getRotulosByTarefa(
        widget.tarefaId,
      );
      final rotulosAplicadosIds = rotulosAplicados
          .map((tr) => tr.rotuloId)
          .toList();

      setState(() {
        _rotulosDisponiveis = rotulosDisponiveis;
        _rotulosAplicados = rotulosAplicadosIds;
        _rotulosSelected = List.from(rotulosAplicadosIds);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<void> _applyLabels() async {
    try {
      // Aplicar novos rótulos
      await _tarefaRotuloRepository.aplicarRotulosNaTarefa(
        widget.tarefaId,
        _rotulosSelected,
      );

      // Identificar mudanças para log
      final rotulosAdicionados = _rotulosSelected
          .where((id) => !_rotulosAplicados.contains(id))
          .toList();
      final rotulosRemovidos = _rotulosAplicados
          .where((id) => !_rotulosSelected.contains(id))
          .toList();

      // Log das atividades
      if (rotulosAdicionados.isNotEmpty || rotulosRemovidos.isNotEmpty) {
        final nomeRotulosAdicionados = rotulosAdicionados
            .map((id) {
              return _rotulosDisponiveis.firstWhere((r) => r.id == id).nome;
            })
            .join(', ');

        final nomeRotulosRemovidos = rotulosRemovidos
            .map((id) {
              return _rotulosDisponiveis.firstWhere((r) => r.id == id).nome;
            })
            .join(', ');

        String detalhes = '{"tarefa": "${widget.tarefaTitulo}"';
        if (rotulosAdicionados.isNotEmpty) {
          detalhes += ', "rotulos_adicionados": "$nomeRotulosAdicionados"';
        }
        if (rotulosRemovidos.isNotEmpty) {
          detalhes += ', "rotulos_removidos": "$nomeRotulosRemovidos"';
        }
        detalhes += '}';

        await _atividadeRepository.createAtividade(
          Atividade(
            usuarioId: widget.usuarioId,
            acao: 'atualizou',
            entidadeId: widget.tarefaId,
            tipoEntidade: 'tarefa',
            detalhes: detalhes,
          ),
        );
      }

      Navigator.pop(
        context,
        true,
      ); // Retorna true para indicar que houve mudanças
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao aplicar rótulos: $e')));
      }
    }
  }

  Color _stringToColor(String colorString) {
    final hex = colorString.replaceFirst('#', '');
    final int value = int.parse(hex, radix: 16);
    return Color(value + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rótulos - ${widget.tarefaTitulo}'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : _rotulosDisponiveis.isEmpty
          ? const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.label_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum rótulo disponível',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Crie rótulos no grupo primeiro',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione os rótulos para aplicar à tarefa:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rotulosDisponiveis.length,
                      itemBuilder: (context, index) {
                        final rotulo = _rotulosDisponiveis[index];
                        final cor = _stringToColor(rotulo.cor);
                        final isSelected = _rotulosSelected.contains(rotulo.id);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _rotulosSelected.add(rotulo.id);
                                } else {
                                  _rotulosSelected.remove(rotulo.id);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Color.lerp(
                                            cor,
                                            Colors.white,
                                            0.2,
                                          )!.withOpacity(0.3)
                                        : cor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Color.lerp(cor, Colors.white, 0.2)!
                                          : cor,
                                    ),
                                  ),
                                  child: Text(
                                    rotulo.nome,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Color.lerp(cor, Colors.white, 0.2)!
                                          : cor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: rotulo.descricao != null
                                ? Text(
                                    rotulo.descricao!,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            secondary: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: cor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Resumo das mudanças
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo das mudanças:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rótulos selecionados: ${_rotulosSelected.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (_rotulosSelected.length != _rotulosAplicados.length)
                          Text(
                            'Anteriormente: ${_rotulosAplicados.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _rotulosDisponiveis.isEmpty ? null : _applyLabels,
          child: const Text('Aplicar Rótulos'),
        ),
      ],
    );
  }
}

// Widget para exibir rótulos de uma tarefa
class TaskLabelsWidget extends StatelessWidget {
  final String tarefaId;
  final List<Map<String, dynamic>> rotulos;
  final VoidCallback? onTap;

  const TaskLabelsWidget({
    super.key,
    required this.tarefaId,
    required this.rotulos,
    this.onTap,
  });

  Color _stringToColor(String colorString) {
    final hex = colorString.replaceFirst('#', '');
    final int value = int.parse(hex, radix: 16);
    return Color(value + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (rotulos.isEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.label_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Adicionar rótulos',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: rotulos.map((rotulo) {
          final cor = _stringToColor(rotulo['cor']);

          // Ajustar cor para dark mode
          final corAjustada = isDarkMode
              ? Color.lerp(cor, Colors.white, 0.2)!
              : cor;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: corAjustada.withOpacity(isDarkMode ? 0.3 : 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: corAjustada),
            ),
            child: Text(
              rotulo['nome'],
              style: TextStyle(
                color: corAjustada,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
