import 'package:flutter/material.dart';
import 'package:trabalho_bd/pages/dashboard_page.dart';
import 'package:trabalho_bd/pages/group_list_page.dart';
import 'package:trabalho_bd/pages/profile_page.dart';
import 'package:trabalho_bd/pages/notification_page.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
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
      const Profile(),
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



// Página temporária para tarefas
class TasksListPage extends StatefulWidget {
  final Usuario usuario;
  
  const TasksListPage({Key? key, required this.usuario}) : super(key: key);

  @override
  State<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends State<TasksListPage> {
  List<Tarefa> _tarefas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    try {
      final tarefaRepo = TarefaRepository();
      final todasTarefas = await tarefaRepo.getAllTarefas();
      // Filtra apenas as tarefas onde o usuário é criador ou responsável
      final tarefasFiltradas = todasTarefas.where((tarefa) => 
        tarefa.criadorId == widget.usuario.id
      ).toList();
      setState(() {
        _tarefas = tarefasFiltradas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao carregar tarefas: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tarefas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma tarefa encontrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tarefas.length,
                  itemBuilder: (context, index) {
                    final tarefa = _tarefas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCorStatus(tarefa.statusId),
                          child: Icon(
                            Icons.task,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          tarefa.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          tarefa.descricao ?? 'Sem descrição',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getStatusText(tarefa.statusId),
                              style: TextStyle(
                                color: _getCorStatus(tarefa.statusId),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (tarefa.dataVencimento != null)
                              Text(
                                'Prazo: ${tarefa.dataVencimento!.day}/${tarefa.dataVencimento!.month}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          // Aqui você pode navegar para os detalhes da tarefa
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para criar nova tarefa
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getCorStatus(int statusId) {
    switch (statusId) {
      case 1: // Pendente
        return Colors.orange;
      case 2: // Em Andamento
        return Colors.blue;
      case 3: // Concluída
        return Colors.green;
      case 4: // Cancelada
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int statusId) {
    switch (statusId) {
      case 1:
        return 'Pendente';
      case 2:
        return 'Em Andamento';
      case 3:
        return 'Concluída';
      case 4:
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }
} 