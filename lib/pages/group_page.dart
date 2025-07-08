import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/status_tarefa_model.dart';
import 'package:trabalho_bd/db/models/atribuicao_tarefa_model.dart';
import 'package:trabalho_bd/db/models/tarefa_rotulo.dart';
import 'package:trabalho_bd/db/models/rotulo_model.dart';
import 'package:trabalho_bd/shared/widgets/task_labels_dialog.dart';
import 'package:trabalho_bd/shared/functions.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key, required this.grupo, required this.usuario});

  final Grupo grupo;
  final Usuario usuario;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  // Variáveis de estado para filtros e busca
  String _searchQuery = '';
  int? _filterStatus;
  int? _filterPrioridade;
  List<String> _filterRotulos = []; // IDs dos rótulos selecionados para filtro
  String _ordenacao = 'prioridade'; // 'prioridade', 'data', 'titulo'

  final TextEditingController _searchController = TextEditingController();
  List<StatusTarefa> _statusDisponiveis = [];
  List<Rotulo> _rotulosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _loadStatusDisponiveis();
    _loadRotulosDisponiveis();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatusDisponiveis() async {
    try {
      final status = await StatusTarefaRepository().getAllStatusTarefas();
      setState(() {
        _statusDisponiveis = status;
      });
    } catch (e) {
      print('Erro ao carregar status: $e');
    }
  }

  Future<void> _loadRotulosDisponiveis() async {
    try {
      final rotulos = await RotuloRepository().getRotulosByGrupoId(
        widget.grupo.id,
      );
      setState(() {
        _rotulosDisponiveis = rotulos;
      });
    } catch (e) {
      print('Erro ao carregar rótulos: $e');
    }
  }

  Future<int> _contarResponsaveis(String tarefaId) async {
    try {
      final atribuicaoRepo = AtribuicaoTarefaRepository();
      final responsaveis = await atribuicaoRepo.getResponsaveisByTarefa(
        tarefaId,
      );
      return responsaveis.length;
    } catch (e) {
      print('Erro ao contar responsáveis: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _carregarRotulosTarefa(
    String tarefaId,
  ) async {
    try {
      final tarefaRotuloRepo = TarefaRotuloRepository();
      final rotulos = await tarefaRotuloRepo.getRotulosCompletosFromTarefa(
        tarefaId,
      );
      return rotulos;
    } catch (e) {
      print('Erro ao carregar rótulos: $e');
      return [];
    }
  }

  Future<void> _gerenciarRotulosTarefa(Tarefa tarefa) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => TaskLabelsDialog(
        tarefaId: tarefa.id,
        grupoId: widget.grupo.id,
        usuarioId: widget.usuario.id,
        tarefaTitulo: tarefa.titulo,
      ),
    );

    if (resultado == true) {
      setState(() {
        // Força rebuild para atualizar os rótulos
      });
    }
  }

  Future<void> _mostrarFiltroRotulos() async {
    final resultado = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar por Rótulos'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _rotulosDisponiveis.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nenhum rótulo disponível'),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selecione os rótulos para filtrar:'),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _rotulosDisponiveis.length,
                          itemBuilder: (context, index) {
                            final rotulo = _rotulosDisponiveis[index];
                            final isSelected = _filterRotulos.contains(
                              rotulo.id,
                            );
                            final cor = Color(
                              int.parse(rotulo.cor.replaceFirst('#', '0xFF')),
                            );

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    _filterRotulos.add(rotulo.id);
                                  } else {
                                    _filterRotulos.remove(rotulo.id);
                                  }
                                });
                              },
                              title: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: cor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rotulo.nome)),
                                ],
                              ),
                              subtitle: rotulo.descricao != null
                                  ? Text(
                                      rotulo.descricao!,
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _filterRotulos.clear();
                });
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _filterRotulos),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        _filterRotulos = resultado;
      });
    }
  }

  Future<void> criarTarefa() async {
    final resultado = await Navigator.pushNamed(
      context,
      "/task-create",
      arguments: {'grupo': widget.grupo, 'criador': widget.usuario},
    );

    // Se uma tarefa foi criada, atualiza a lista
    if (resultado == true) {
      setState(() {});
    }
  }

  Widget _buildPrioridadeIndicator(int prioridade) {
    Color cor;
    String texto;

    switch (prioridade) {
      case 1:
        cor = Colors.green;
        texto = "Baixa";
        break;
      case 2:
        cor = Colors.blue;
        texto = "Normal";
        break;
      case 3:
        cor = Colors.orange;
        texto = "Alta";
        break;
      case 4:
        cor = Colors.red;
        texto = "Urgente";
        break;
      default:
        cor = Colors.grey;
        texto = "?";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusIndicator(int statusId) {
    final status = _statusDisponiveis.firstWhere(
      (s) => s.id == statusId,
      orElse: () => StatusTarefa(id: statusId, nome: "Desconhecido"),
    );

    Color cor;
    try {
      cor = Color(int.parse(status.cor.replaceFirst('#', '0xFF')));
    } catch (e) {
      cor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        status.nome,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Tarefa> _filtrarEOrdenarTarefas(List<Tarefa> tarefas) {
    List<Tarefa> resultado = tarefas;

    // Aplicar filtros
    if (_searchQuery.isNotEmpty) {
      resultado = resultado.where((tarefa) {
        final titulo = tarefa.titulo.toLowerCase();
        final descricao = tarefa.descricao?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return titulo.contains(query) || descricao.contains(query);
      }).toList();
    }

    if (_filterStatus != null) {
      resultado = resultado
          .where((tarefa) => tarefa.statusId == _filterStatus)
          .toList();
    }

    if (_filterPrioridade != null) {
      resultado = resultado
          .where((tarefa) => tarefa.prioridade == _filterPrioridade)
          .toList();
    }

    // Aplicar ordenação
    switch (_ordenacao) {
      case 'prioridade':
        resultado.sort((a, b) => b.prioridade.compareTo(a.prioridade));
        break;
      case 'data':
        resultado.sort((a, b) {
          final dataA = a.dataVencimento ?? DateTime(2099);
          final dataB = b.dataVencimento ?? DateTime(2099);
          return dataA.compareTo(dataB);
        });
        break;
      case 'titulo':
        resultado.sort((a, b) => a.titulo.compareTo(b.titulo));
        break;
    }

    return resultado;
  }

  Future<List<Tarefa>> _aplicarFiltroRotulos(List<Tarefa> tarefas) async {
    if (_filterRotulos.isEmpty) {
      return tarefas;
    }

    final tarefaRotuloRepo = TarefaRotuloRepository();
    final tarefasFiltradas = <Tarefa>[];

    for (final tarefa in tarefas) {
      final rotulosTarefa = await tarefaRotuloRepo.getRotulosByTarefa(
        tarefa.id,
      );
      final rotulosIdsTarefa = rotulosTarefa.map((tr) => tr.rotuloId).toList();

      // Verifica se a tarefa tem pelo menos um dos rótulos selecionados
      final temRotuloSelecionado = _filterRotulos.any(
        (rotuloId) => rotulosIdsTarefa.contains(rotuloId),
      );
      if (temRotuloSelecionado) {
        tarefasFiltradas.add(tarefa);
      }
    }

    return tarefasFiltradas;
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar tarefas...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          SizedBox(height: 12),

          // Filtros em duas linhas para evitar overflow
          Column(
            children: [
              // Primeira linha: Status e Prioridade
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _filterStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ..._statusDisponiveis.map(
                          (status) => DropdownMenuItem<int?>(
                            value: status.id,
                            child: Text(status.nome),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _filterPrioridade,
                      decoration: InputDecoration(
                        labelText: 'Prioridade',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        DropdownMenuItem<int?>(value: 1, child: Text('Baixa')),
                        DropdownMenuItem<int?>(value: 2, child: Text('Normal')),
                        DropdownMenuItem<int?>(value: 3, child: Text('Alta')),
                        DropdownMenuItem<int?>(
                          value: 4,
                          child: Text('Urgente'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterPrioridade = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Segunda linha: Ordenação e Rótulos
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ordenacao,
                      decoration: InputDecoration(
                        labelText: 'Ordenar por',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'prioridade',
                          child: Text('Prioridade'),
                        ),
                        DropdownMenuItem(
                          value: 'data',
                          child: Text('Data de vencimento'),
                        ),
                        DropdownMenuItem(
                          value: 'titulo',
                          child: Text('Título (A-Z)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _ordenacao = value ?? 'prioridade';
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 12),

                  // Filtro por rótulos
                  Expanded(
                    child: GestureDetector(
                      onTap: _mostrarFiltroRotulos,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.label_outline, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _filterRotulos.isEmpty
                                    ? 'Filtrar rótulos'
                                    : '${_filterRotulos.length} rótulo${_filterRotulos.length != 1 ? 's' : ''}',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_filterRotulos.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _filterRotulos.clear();
                                  });
                                },
                                child: Icon(Icons.clear, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: TextButton(
          child: Text(widget.grupo.nome, style: TextStyle(fontSize: 18)),
          onPressed: () => Navigator.pushNamed(
            context,
            "/group-data",
            arguments: widget.grupo,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'members':
                  Navigator.pushNamed(
                    context,
                    '/group-members',
                    arguments: {
                      'grupo': widget.grupo,
                      'usuario': widget.usuario,
                    },
                  );
                  break;
                case 'labels':
                  Navigator.pushNamed(
                    context,
                    '/label-management',
                    arguments: {
                      'grupoId': widget.grupo.id,
                      'usuarioId': widget.usuario.id,
                    },
                  );
                  break;
                case 'settings':
                  Navigator.pushNamed(
                    context,
                    '/group-settings',
                    arguments: {
                      'grupo': widget.grupo,
                      'usuario': widget.usuario,
                    },
                  ).then((result) {
                    // Se o usuário saiu do grupo, voltar para a home
                    if (result == 'left_group') {
                      Navigator.pop(context);
                    } else if (result == true) {
                      // Se houve alterações, atualizar a página
                      setState(() {});
                    }
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.group),
                    SizedBox(width: 8),
                    Text('Membros'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'labels',
                child: Row(
                  children: [
                    Icon(Icons.label),
                    SizedBox(width: 8),
                    Text('Rótulos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Tarefa>>(
        future: TarefaRepository().getTarefasByGrupoAndStatus(widget.grupo.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Erro ao carregar tarefas",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text("${snapshot.error}"),
                ],
              ),
            );
          }

          final tarefasOriginais = snapshot.data ?? [];
          final tarefasFiltradas = _filtrarEOrdenarTarefas(tarefasOriginais);

          return Column(
            children: [
              _buildFiltersBar(),

              Expanded(
                child: tarefasOriginais.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "Nenhuma tarefa ainda",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text("Toque no + para criar a primeira tarefa"),
                          ],
                        ),
                      )
                    : FutureBuilder<List<Tarefa>>(
                        future: _aplicarFiltroRotulos(tarefasFiltradas),
                        builder: (context, labelSnapshot) {
                          if (labelSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final tarefasComRotulos =
                              labelSnapshot.data ?? tarefasFiltradas;

                          return tarefasComRotulos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Nenhuma tarefa encontrada",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      SizedBox(height: 8),
                                      Text("Tente ajustar os filtros ou busca"),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: tarefasComRotulos.length,
                                  itemBuilder: (context, index) {
                                    final tarefa = tarefasComRotulos[index];

                                    return Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      child: InkWell(
                                        onTap: () =>
                                            Navigator.pushNamed(
                                              context,
                                              "/task",
                                              arguments: {
                                                'tarefa': tarefa,
                                                'grupo': widget.grupo,
                                                'usuario': widget.usuario,
                                              },
                                            ).then((result) {
                                              // Se a tarefa foi excluída, recarregar a lista
                                              if (result == true) {
                                                setState(() {
                                                  // Força rebuild do FutureBuilder para recarregar dados
                                                });
                                              }
                                            }),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Cabeçalho da tarefa
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      tarefa.titulo,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (tarefa.progresso > 0) ...[
                                                    SizedBox(width: 8),
                                                    SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            value:
                                                                tarefa
                                                                    .progresso /
                                                                100,
                                                            strokeWidth: 3,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),

                                              // Descrição
                                              if (tarefa.descricao != null) ...[
                                                SizedBox(height: 8),
                                                Text(
                                                  tarefa.descricao!,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],

                                              SizedBox(height: 12),

                                              // Indicadores e informações
                                              Row(
                                                children: [
                                                  _buildStatusIndicator(
                                                    tarefa.statusId,
                                                  ),
                                                  SizedBox(width: 8),
                                                  _buildPrioridadeIndicator(
                                                    tarefa.prioridade,
                                                  ),

                                                  Spacer(),

                                                  // Data de vencimento
                                                  if (tarefa.dataVencimento !=
                                                      null) ...[
                                                    Icon(
                                                      Icons.schedule,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "${tarefa.dataVencimento!.day.toString().padLeft(2, '0')}/"
                                                      "${tarefa.dataVencimento!.month.toString().padLeft(2, '0')}/"
                                                      "${tarefa.dataVencimento!.year}",
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),

                                              // Progresso se maior que 0
                                              if (tarefa.progresso > 0) ...[
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.trending_up,
                                                      size: 16,
                                                      color: Colors.blue,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "${tarefa.progresso}% concluído",
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],

                                              // Responsáveis (indicador simples)
                                              SizedBox(height: 8),
                                              FutureBuilder<int>(
                                                future: _contarResponsaveis(
                                                  tarefa.id,
                                                ),
                                                builder: (context, snapshot) {
                                                  final count =
                                                      snapshot.data ?? 0;
                                                  if (count == 0) {
                                                    return Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person_outline,
                                                          size: 14,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "Sem responsáveis",
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[500],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }

                                                  return Row(
                                                    children: [
                                                      Icon(
                                                        Icons.people,
                                                        size: 14,
                                                        color:
                                                            Colors.green[600],
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        "$count responsáve${count == 1 ? 'l' : 'is'}",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.green[600],
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),

                                              // Rótulos da tarefa
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        FutureBuilder<
                                                          List<
                                                            Map<String, dynamic>
                                                          >
                                                        >(
                                                          future:
                                                              _carregarRotulosTarefa(
                                                                tarefa.id,
                                                              ),
                                                          builder: (context, snapshot) {
                                                            final rotulos =
                                                                snapshot.data ??
                                                                [];
                                                            return TaskLabelsWidget(
                                                              tarefaId:
                                                                  tarefa.id,
                                                              rotulos: rotulos,
                                                              onTap: () =>
                                                                  _gerenciarRotulosTarefa(
                                                                    tarefa,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                  ),
                                                  // Botão para gerenciar rótulos
                                                  // GestureDetector(
                                                  //   onTap: () =>
                                                  //       _gerenciarRotulosTarefa(
                                                  //         tarefa,
                                                  //       ),
                                                  //   child: Container(
                                                  //     padding: EdgeInsets.all(
                                                  //       4,
                                                  //     ),
                                                  //     decoration: BoxDecoration(
                                                  //       color: Colors
                                                  //           .grey
                                                  //           .shade200,
                                                  //       borderRadius:
                                                  //           BorderRadius.circular(
                                                  //             8,
                                                  //           ),
                                                  //     ),
                                                  //     child: Icon(
                                                  //       Icons.label_outline,
                                                  //       size: 16,
                                                  //       color: Colors
                                                  //           .grey
                                                  //           .shade600,
                                                  //     ),
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                        },
                      ),
              ),

              // Resumo dos filtros
              if (tarefasOriginais.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Mostrando ${tarefasFiltradas.length} de ${tarefasOriginais.length} tarefas",
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: criarTarefa,
        child: Icon(Icons.add),
        tooltip: "Criar Nova Tarefa",
      ),
    );
  }
}
