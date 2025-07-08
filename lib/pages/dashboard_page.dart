import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/dashboard_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  final Usuario usuario;

  const DashboardPage({
    super.key,
    required this.usuario,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final dashboardRepo = DashboardRepository();
      final data = await dashboardRepo.getDashboardData(widget.usuario.id);

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/groups',
                arguments: widget.usuario,
              );
            },
            icon: Icon(Icons.group),
            tooltip: 'Meus Grupos',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: Icon(Icons.person),
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/group-create',
            arguments: widget.usuario,
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Criar Grupo',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando dashboard...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Ops! Algo deu errado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: Icon(Icons.refresh),
              label: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_dashboardData == null) {
      return Center(
        child: Text('Nenhum dado disponível'),
      );
    }

    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com saudação
          _buildWelcomeHeader(),
          
          SizedBox(height: 16),
          
          // Estatísticas de grupos
          DashboardSection(
            title: 'Meus Grupos',
            icon: Icons.group,
            child: GroupStatsCard(
              stats: _dashboardData!.groupStats,
              onTap: () => Navigator.pushNamed(
                context,
                '/groups',
                arguments: widget.usuario,
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Estatísticas de tarefas
          DashboardSection(
            title: 'Minhas Tarefas',
            icon: Icons.assignment,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TaskStatsGrid(
                stats: _dashboardData!.taskStats,
                onTap: () {
                  // TODO: Navegar para página de tarefas filtradas
                },
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Próximos vencimentos
          if (_dashboardData!.proximosVencimentos.isNotEmpty) ...[
            DashboardSection(
              title: 'Próximos Vencimentos',
              icon: Icons.schedule,
              actionText: 'Ver todas',
              onActionPressed: () {
                // TODO: Navegar para tarefas com vencimento próximo
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _dashboardData!.proximosVencimentos
                      .map((task) => TaskSummaryTile(
                            task: task,
                            onTap: () => _navigateToTask(task),
                          ))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
          
          // Tarefas recentes
          if (_dashboardData!.minhasTarefas.isNotEmpty) ...[
            DashboardSection(
              title: 'Minhas Tarefas Recentes',
              icon: Icons.task_alt,
              actionText: 'Ver todas',
              onActionPressed: () {
                // TODO: Navegar para todas as tarefas do usuário
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _dashboardData!.minhasTarefas
                      .take(5) // Mostrar apenas as 5 mais recentes
                      .map((task) => TaskSummaryTile(
                            task: task,
                            onTap: () => _navigateToTask(task),
                          ))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
          
          // Atividade recente
          DashboardSection(
            title: 'Atividade Recente',
            icon: Icons.history,
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: RecentActivityWidget(
                activities: _dashboardData!.atividadeRecente,
              ),
            ),
          ),
          
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) {
      greeting = 'Bom dia';
    } else if (hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              widget.usuario.nome,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (_dashboardData != null) ...[
              Text(
                _buildSummaryText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildSummaryText() {
    final stats = _dashboardData!.taskStats;
    final groupCount = _dashboardData!.groupStats.totalGrupos;
    
    if (stats.total == 0) {
      if (groupCount == 0) {
        return 'Comece criando seu primeiro grupo!';
      } else {
        return 'Você participa de $groupCount ${groupCount == 1 ? 'grupo' : 'grupos'}. Que tal criar uma tarefa?';
      }
    }
    
    final pendentes = stats.pendentes + stats.emProgresso;
    if (pendentes == 0) {
      return 'Parabéns! Você está em dia com suas tarefas!';
    } else {
      return 'Você tem $pendentes ${pendentes == 1 ? 'tarefa pendente' : 'tarefas pendentes'} em $groupCount ${groupCount == 1 ? 'grupo' : 'grupos'}.';
    }
  }

  void _navigateToTask(TaskSummary task) {
    // TODO: Implementar navegação para detalhes da tarefa
    // Por enquanto, apenas mostra um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando para tarefa: ${task.titulo}'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 