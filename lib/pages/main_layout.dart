import 'package:flutter/material.dart';
import 'package:trabalho_bd/pages/dashboard_page.dart';
import 'package:trabalho_bd/pages/group_list_page.dart';
import 'package:trabalho_bd/pages/profile_page.dart';
import 'package:trabalho_bd/pages/notification_page.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/atribuicao_tarefa_model.dart';
import 'package:trabalho_bd/shared/functions.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  final Usuario usuario;
  
  const MainLayout({Key? key, this.initialIndex = 0, required this.usuario}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  
  late List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      DashboardPage(usuario: widget.usuario),
      GroupListPage(usuario: widget.usuario),
      TasksListPage(usuario: widget.usuario),
      NotificationPage(usuario: widget.usuario),
      Profile(usuario: widget.usuario),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}



// Página melhorada para tarefas
class TasksListPage extends StatefulWidget {
  final Usuario usuario;
  
  const TasksListPage({Key? key, required this.usuario}) : super(key: key);

  @override
  State<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends State<TasksListPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _tarefasComGrupo = [];
  List<Map<String, dynamic>> _tarefasFiltradas = [];
  Map<String, int> _estatisticas = {};
  bool _isLoading = true;
  String? _filtroStatus;
  int? _filtroPrioridade;
  String _ordenacao = 'vencimento'; // vencimento, prioridade, titulo, grupo

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    setState(() => _isLoading = true);
    
    try {
      final tarefaRepo = TarefaRepository();
      final atribuicaoRepo = AtribuicaoTarefaRepository();
      final grupoRepo = GrupoRepository();
      
      // Buscar tarefas onde o usuário é criador
      final tarefasCriadas = await tarefaRepo.getAllTarefas();
      final minhasTarefasCriadas = tarefasCriadas.where((t) => t.criadorId == widget.usuario.id).toList();
      
      // Buscar tarefas onde o usuário é responsável
      final minhasAtribuicoes = await atribuicaoRepo.getAtribuicoesByUsuario(widget.usuario.id);
      final tarefasAtribuidas = <Tarefa>[];
      for (final atribuicao in minhasAtribuicoes) {
        final tarefa = await tarefaRepo.getTarefaById(atribuicao.tarefaId);
        if (tarefa != null) {
          tarefasAtribuidas.add(tarefa);
        }
      }
      
      // Combinar todas as tarefas (remover duplicatas)
      final todasTarefas = <String, Tarefa>{};
      for (final tarefa in minhasTarefasCriadas) {
        todasTarefas[tarefa.id] = tarefa;
      }
      for (final tarefa in tarefasAtribuidas) {
        todasTarefas[tarefa.id] = tarefa;
      }
      
      // Carregar informações do grupo para cada tarefa
      final tarefasComGrupo = <Map<String, dynamic>>[];
      for (final tarefa in todasTarefas.values) {
        final grupo = await grupoRepo.getGrupoById(tarefa.grupoId);
        if (grupo != null) {
          tarefasComGrupo.add({
            'tarefa': tarefa,
            'grupo': grupo,
            'ehCriador': tarefa.criadorId == widget.usuario.id,
          });
        }
      }
      
      // Calcular estatísticas
      final stats = _calcularEstatisticas(todasTarefas.values.toList());
      
      setState(() {
        _tarefasComGrupo = tarefasComGrupo;
        _tarefasFiltradas = tarefasComGrupo;
        _estatisticas = stats;
        _isLoading = false;
      });
      
      _aplicarFiltros();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao carregar tarefas: $e');
      }
    }
  }

  Map<String, int> _calcularEstatisticas(List<Tarefa> tarefas) {
    final stats = <String, int>{};
    stats['total'] = tarefas.length;
    stats['pendentes'] = tarefas.where((t) => t.statusId == 1).length;
    stats['em_andamento'] = tarefas.where((t) => t.statusId == 2).length;
    stats['concluidas'] = tarefas.where((t) => t.statusId == 3).length;
    stats['vencendo'] = tarefas.where((t) {
      if (t.dataVencimento == null || t.statusId == 3) return false;
      final diasRestantes = t.dataVencimento!.difference(DateTime.now()).inDays;
      return diasRestantes <= 3 && diasRestantes >= 0;
    }).length;
    return stats;
  }

  void _aplicarFiltros() {
    String termo = _searchController.text.toLowerCase();
    
    setState(() {
      _tarefasFiltradas = _tarefasComGrupo.where((item) {
        final tarefa = item['tarefa'] as Tarefa;
        final grupo = item['grupo'] as Grupo;
        
        // Filtro de busca
        bool matchesBusca = termo.isEmpty ||
            tarefa.titulo.toLowerCase().contains(termo) ||
            (tarefa.descricao?.toLowerCase().contains(termo) ?? false) ||
            grupo.nome.toLowerCase().contains(termo);
            
        // Filtro de status
        bool matchesStatus = _filtroStatus == null || 
            _getStatusText(tarefa.statusId).toLowerCase() == _filtroStatus!.toLowerCase();
        
        // Filtro de prioridade
        bool matchesPrioridade = _filtroPrioridade == null || 
            tarefa.prioridade == _filtroPrioridade;
        
        return matchesBusca && matchesStatus && matchesPrioridade;
      }).toList();
    });
    
    _aplicarOrdenacao();
  }

  void _aplicarOrdenacao() {
    setState(() {
      switch (_ordenacao) {
        case 'vencimento':
          _tarefasFiltradas.sort((a, b) {
            final tarefaA = a['tarefa'] as Tarefa;
            final tarefaB = b['tarefa'] as Tarefa;
            final dataA = tarefaA.dataVencimento ?? DateTime(2099);
            final dataB = tarefaB.dataVencimento ?? DateTime(2099);
            return dataA.compareTo(dataB);
          });
          break;
        case 'prioridade':
          _tarefasFiltradas.sort((a, b) {
            final tarefaA = a['tarefa'] as Tarefa;
            final tarefaB = b['tarefa'] as Tarefa;
            return tarefaB.prioridade.compareTo(tarefaA.prioridade);
          });
          break;
        case 'titulo':
          _tarefasFiltradas.sort((a, b) {
            final tarefaA = a['tarefa'] as Tarefa;
            final tarefaB = b['tarefa'] as Tarefa;
            return tarefaA.titulo.compareTo(tarefaB.titulo);
          });
          break;
        case 'grupo':
          _tarefasFiltradas.sort((a, b) {
            final grupoA = a['grupo'] as Grupo;
            final grupoB = b['grupo'] as Grupo;
            return grupoA.nome.compareTo(grupoB.nome);
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Minhas Tarefas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarTarefas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas
          if (!_isLoading && _estatisticas.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEstatisticaCard('Total', _estatisticas['total'] ?? 0, Icons.assignment, theme.colorScheme.primary),
                  _buildEstatisticaCard('Vencendo', _estatisticas['vencendo'] ?? 0, Icons.warning, Colors.orange),
                  _buildEstatisticaCard('Andamento', _estatisticas['em_andamento'] ?? 0, Icons.play_circle, Colors.blue),
                  _buildEstatisticaCard('Concluídas', _estatisticas['concluidas'] ?? 0, Icons.check_circle, Colors.green),
                ],
              ),
            ),
          
          // Barra de busca e filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Campo de busca
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar tarefas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _aplicarFiltros();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (_) => _aplicarFiltros(),
                ),
                const SizedBox(height: 12),
                
                // Filtros
                Row(
                  children: [
                    // Filtro por status
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          const DropdownMenuItem(value: 'Pendente', child: Text('Pendente')),
                          const DropdownMenuItem(value: 'Em Andamento', child: Text('Andamento')),
                          const DropdownMenuItem(value: 'Concluída', child: Text('Concluída')),
                        ],
                        onChanged: (value) {
                          _filtroStatus = value;
                          _aplicarFiltros();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Filtro por prioridade
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _filtroPrioridade,
                        decoration: InputDecoration(
                          labelText: 'Prioridade',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas')),
                          const DropdownMenuItem(value: 1, child: Text('Baixa')),
                          const DropdownMenuItem(value: 2, child: Text('Média')),
                          const DropdownMenuItem(value: 3, child: Text('Alta')),
                        ],
                        onChanged: (value) {
                          _filtroPrioridade = value;
                          _aplicarFiltros();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Ordenação
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _ordenacao,
                        decoration: InputDecoration(
                          labelText: 'Ordenar',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'vencimento', child: Text('Vencimento')),
                          DropdownMenuItem(value: 'prioridade', child: Text('Prioridade')),
                          DropdownMenuItem(value: 'titulo', child: Text('Título')),
                          DropdownMenuItem(value: 'grupo', child: Text('Grupo')),
                        ],
                        onChanged: (value) {
                          _ordenacao = value!;
                          _aplicarOrdenacao();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tarefasFiltradas.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _carregarTarefas,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tarefasFiltradas.length,
                          itemBuilder: (context, index) {
                            return _buildTarefaCard(_tarefasFiltradas[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticaCard(String label, int valor, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                valor.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _filtroStatus != null || _filtroPrioridade != null
                ? 'Nenhuma tarefa encontrada com os filtros aplicados'
                : 'Você ainda não tem tarefas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _filtroStatus != null || _filtroPrioridade != null
                ? 'Tente ajustar os filtros de busca'
                : 'Suas tarefas criadas e atribuídas aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTarefaCard(Map<String, dynamic> item) {
    final tarefa = item['tarefa'] as Tarefa;
    final grupo = item['grupo'] as Grupo;
    final ehCriador = item['ehCriador'] as bool;
    
    final isVencida = tarefa.dataVencimento != null && 
        tarefa.dataVencimento!.isBefore(DateTime.now()) &&
        tarefa.statusId != 3;
    
    final diasRestantes = tarefa.dataVencimento?.difference(DateTime.now()).inDays;
    final isVencendoSoon = diasRestantes != null && diasRestantes <= 3 && diasRestantes >= 0 && tarefa.statusId != 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/task',
            arguments: {
              'tarefa': tarefa,
              'grupo': grupo,
              'usuario': widget.usuario,
            },
          ).then((_) {
            // Recarregar tarefas após voltar dos detalhes
            _carregarTarefas();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com título e prioridade
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tarefa.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildPrioridadeChip(tarefa.prioridade),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Descrição
              if (tarefa.descricao != null && tarefa.descricao!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    tarefa.descricao!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // Informações secundárias
              Row(
                children: [
                  // Grupo
                  Icon(Icons.group, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    grupo.nome,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Papel do usuário
                  Icon(
                    ehCriador ? Icons.create : Icons.assignment_ind,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ehCriador ? 'Criador' : 'Responsável',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Footer com status e vencimento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(tarefa.statusId),
                  
                  if (tarefa.dataVencimento != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isVencida 
                              ? Colors.red 
                              : isVencendoSoon 
                                  ? Colors.orange 
                                  : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDataVencimento(tarefa.dataVencimento!),
                          style: TextStyle(
                            fontSize: 13,
                            color: isVencida 
                                ? Colors.red 
                                : isVencendoSoon 
                                    ? Colors.orange 
                                    : Colors.grey[600],
                            fontWeight: isVencida || isVencendoSoon 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(int statusId) {
    final color = _getCorStatus(statusId);
    final text = _getStatusText(statusId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPrioridadeChip(int prioridade) {
    final color = _getCorPrioridade(prioridade);
    final text = _getPrioridadeText(prioridade);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPrioridadeIcon(prioridade), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDataVencimento(DateTime data) {
    final agora = DateTime.now();
    final diferenca = data.difference(agora).inDays;
    
    if (diferenca < 0) {
      return 'Vencida';
    } else if (diferenca == 0) {
      return 'Vence hoje';
    } else if (diferenca == 1) {
      return 'Vence amanhã';
    } else if (diferenca <= 7) {
      return 'Vence em $diferenca dias';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }

  Color _getCorStatus(int statusId) {
    switch (statusId) {
      case 1: return Colors.orange;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(int statusId) {
    switch (statusId) {
      case 1: return 'Pendente';
      case 2: return 'Em Andamento';
      case 3: return 'Concluída';
      case 4: return 'Cancelada';
      default: return 'Desconhecido';
    }
  }

  Color _getCorPrioridade(int prioridade) {
    switch (prioridade) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPrioridadeText(int prioridade) {
    switch (prioridade) {
      case 1: return 'Baixa';
      case 2: return 'Média';
      case 3: return 'Alta';
      default: return 'Normal';
    }
  }

  IconData _getPrioridadeIcon(int prioridade) {
    switch (prioridade) {
      case 1: return Icons.keyboard_arrow_down;
      case 2: return Icons.remove;
      case 3: return Icons.keyboard_arrow_up;
      default: return Icons.remove;
    }
  }
} 