import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/functions.dart';

class GroupListPage extends StatefulWidget {
  final Usuario usuario;

  const GroupListPage({super.key, required this.usuario});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final GrupoRepository _grupoRepo = GrupoRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<GrupoComInfo> _grupos = [];
  List<GrupoComInfo> _gruposFiltrados = [];
  Map<String, int> _estatisticas = {};
  bool _isLoading = true;
  String? _filtroAtual;
  String _ordenacaoAtual = 'data_entrada'; // data_entrada, nome, membros

  @override
  void initState() {
    super.initState();
    _carregarGrupos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarGrupos() async {
    setState(() => _isLoading = true);
    
    try {
      final grupos = await _grupoRepo.getGruposDoUsuario(
        widget.usuario.id,
        filtrarPorPapel: _filtroAtual,
      );
      final estatisticas = await _grupoRepo.getEstatisticasGruposUsuario(widget.usuario.id);
      
      setState(() {
        _grupos = grupos;
        _gruposFiltrados = grupos;
        _estatisticas = estatisticas;
        _isLoading = false;
      });
      
      _aplicarOrdenacao();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao carregar grupos: ${e.toString()}');
      }
    }
  }

  void _aplicarFiltros() {
    String termo = _searchController.text.toLowerCase();
    
    setState(() {
      _gruposFiltrados = _grupos.where((grupoInfo) {
        bool matchesBusca = termo.isEmpty ||
            grupoInfo.grupo.nome.toLowerCase().contains(termo) ||
            (grupoInfo.grupo.descricao?.toLowerCase().contains(termo) ?? false);
            
        bool matchesFiltro = _filtroAtual == null || grupoInfo.papelUsuario == _filtroAtual;
        
        return matchesBusca && matchesFiltro;
      }).toList();
    });
    
    _aplicarOrdenacao();
  }

  void _aplicarOrdenacao() {
    setState(() {
      switch (_ordenacaoAtual) {
        case 'nome':
          _gruposFiltrados.sort((a, b) => a.grupo.nome.compareTo(b.grupo.nome));
          break;
        case 'membros':
          _gruposFiltrados.sort((a, b) => b.totalMembros.compareTo(a.totalMembros));
          break;
        case 'data_entrada':
        default:
          _gruposFiltrados.sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada));
          break;
      }
    });
  }

  Color _getCorPapel(String papel) {
    switch (papel) {
      case 'admin':
        return Colors.red.shade100;
      case 'moderador':
        return Colors.orange.shade100;
      case 'membro':
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getCorTextoPapel(String papel) {
    switch (papel) {
      case 'admin':
        return Colors.red.shade800;
      case 'moderador':
        return Colors.orange.shade800;
      case 'membro':
      default:
        return Colors.blue.shade800;
    }
  }

  IconData _getIconePapel(String papel) {
    switch (papel) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'moderador':
        return Icons.shield;
      case 'membro':
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Grupos'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/group-create',
                arguments: widget.usuario,
              ).then((_) => _carregarGrupos());
            },
            tooltip: 'Criar novo grupo',
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
                  _buildEstatisticaCard('Total', _estatisticas['total'] ?? 0, Icons.groups, theme.colorScheme.primary),
                  _buildEstatisticaCard('Admin', _estatisticas['admin'] ?? 0, Icons.admin_panel_settings, Colors.red),
                  _buildEstatisticaCard('Moderador', _estatisticas['moderador'] ?? 0, Icons.shield, Colors.orange),
                  _buildEstatisticaCard('Membro', _estatisticas['membro'] ?? 0, Icons.person, Colors.blue),
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
                    hintText: 'Buscar grupos...',
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
                
                // Filtros e ordenação
                Row(
                  children: [
                    // Filtro por papel
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filtroAtual,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por papel',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          const DropdownMenuItem(value: 'moderador', child: Text('Moderador')),
                          const DropdownMenuItem(value: 'membro', child: Text('Membro')),
                        ],
                        onChanged: (value) {
                          _filtroAtual = value;
                          _aplicarFiltros();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Ordenação
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _ordenacaoAtual,
                        decoration: InputDecoration(
                          labelText: 'Ordenar por',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'data_entrada', child: Text('Data de entrada')),
                          DropdownMenuItem(value: 'nome', child: Text('Nome')),
                          DropdownMenuItem(value: 'membros', child: Text('Nº de membros')),
                        ],
                        onChanged: (value) {
                          _ordenacaoAtual = value!;
                          _aplicarOrdenacao();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de grupos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gruposFiltrados.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _carregarGrupos,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _gruposFiltrados.length,
                          itemBuilder: (context, index) {
                            return _buildGrupoCard(_gruposFiltrados[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticaCard(String titulo, int valor, IconData icone, Color cor) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cor, size: 24),
              const SizedBox(height: 4),
              Text(
                valor.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              Text(
                titulo,
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
            Icons.groups_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _filtroAtual != null
                ? 'Nenhum grupo encontrado'
                : 'Você ainda não participa de nenhum grupo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _filtroAtual != null
                ? 'Tente ajustar os filtros de busca'
                : 'Crie um novo grupo ou peça para ser adicionado a um existente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty && _filtroAtual == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context, 
                  '/group-create',
                  arguments: widget.usuario,
                ).then((_) => _carregarGrupos());
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar meu primeiro grupo'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrupoCard(GrupoComInfo grupoInfo) {
    final theme = Theme.of(context);
    final grupo = grupoInfo.grupo;
    
    // Parse da cor do grupo
    Color corGrupo;
    try {
      final corHex = grupo.corTema.replaceFirst('#', '');
      corGrupo = Color(int.parse('FF$corHex', radix: 16));
    } catch (e) {
      corGrupo = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/group',
            arguments: {
              'grupo': grupo,
              'usuario': widget.usuario,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do card
              Row(
                children: [
                  // Indicador de cor do grupo
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: corGrupo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Informações principais
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                grupo.nome,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Badge do papel
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCorPapel(grupoInfo.papelUsuario),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getIconePapel(grupoInfo.papelUsuario),
                                    size: 14,
                                    color: _getCorTextoPapel(grupoInfo.papelUsuario),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    grupoInfo.papelUsuario.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getCorTextoPapel(grupoInfo.papelUsuario),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (grupo.descricao != null && grupo.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            grupo.descricao!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações adicionais
              Row(
                children: [
                  // Total de membros
                  Icon(
                    Icons.people,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${grupoInfo.totalMembros} ${grupoInfo.totalMembros == 1 ? 'membro' : 'membros'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Visibilidade
                  Icon(
                    grupo.publico ? Icons.public : Icons.lock,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    grupo.publico ? 'Público' : 'Privado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Data de entrada
                  Text(
                    'Entrou em ${_formatarData(grupoInfo.dataEntrada)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);
    
    if (diferenca.inDays == 0) {
      return 'hoje';
    } else if (diferenca.inDays == 1) {
      return 'ontem';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays} dias atrás';
    } else if (diferenca.inDays < 30) {
      final semanas = (diferenca.inDays / 7).floor();
      return '$semanas ${semanas == 1 ? 'semana' : 'semanas'} atrás';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }
} 