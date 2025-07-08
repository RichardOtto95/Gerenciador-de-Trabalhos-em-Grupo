import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/atividade_model.dart';
import 'package:trabalho_bd/shared/functions.dart';

class GroupMembersPage extends StatefulWidget {
  final Grupo grupo;
  final Usuario usuarioLogado;

  const GroupMembersPage({
    super.key,
    required this.grupo,
    required this.usuarioLogado,
  });

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final UsuarioGrupoRepository _usuarioGrupoRepo = UsuarioGrupoRepository();
  final AtividadeRepository _atividadeRepo = AtividadeRepository();
  final TextEditingController _searchController = TextEditingController();

  List<MembroGrupo> _membros = [];
  List<Usuario> _usuariosPesquisa = [];
  Map<String, int> _estatisticas = {};
  bool _isLoading = true;
  bool _temPermissaoGerenciar = false;
  bool _buscandoUsuarios = false;

  @override
  void initState() {
    super.initState();
    _carregarMembros();
    _verificarPermissoes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarMembros() async {
    setState(() => _isLoading = true);

    try {
      final membros = await _usuarioGrupoRepo.getMembrosComInfo(widget.grupo.id);
      final estatisticas = await _usuarioGrupoRepo.getEstatisticasMembros(widget.grupo.id);

      setState(() {
        _membros = membros;
        _estatisticas = estatisticas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao carregar membros: ${e.toString()}');
      }
    }
  }

  Future<void> _verificarPermissoes() async {
    final temPermissao = await _usuarioGrupoRepo.temPermissaoGerenciarMembros(
      widget.usuarioLogado.id,
      widget.grupo.id,
    );
    setState(() {
      _temPermissaoGerenciar = temPermissao;
    });
  }

  Future<void> _buscarUsuarios(String termo) async {
    if (termo.isEmpty) {
      setState(() => _usuariosPesquisa = []);
      return;
    }

    setState(() => _buscandoUsuarios = true);

    try {
      final usuarios = await _usuarioGrupoRepo.buscarUsuariosNaoMembros(
        widget.grupo.id,
        termo,
      );
      setState(() {
        _usuariosPesquisa = usuarios;
        _buscandoUsuarios = false;
      });
    } catch (e) {
      setState(() => _buscandoUsuarios = false);
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao buscar usuários: ${e.toString()}');
      }
    }
  }

  Future<void> _adicionarMembro(Usuario usuario, String papel) async {
    try {
      final novoMembro = UsuarioGrupo(
        usuarioId: usuario.id,
        grupoId: widget.grupo.id,
        papel: papel,
      );

      await _usuarioGrupoRepo.createUsuarioGrupo(novoMembro);

      // Log da ação
      await _atividadeRepo.createAtividade(
        Atividade(
          tipoEntidade: 'grupo',
          entidadeId: widget.grupo.id,
          usuarioId: widget.usuarioLogado.id,
          acao: 'atribuiu',
          grupoId: widget.grupo.id,
          detalhes: '{"acao": "adicionar_membro", "membro_adicionado": "${usuario.nome}", "papel": "$papel", "grupo_nome": "${widget.grupo.nome}"}',
        ),
      );

      setState(() {
        _usuariosPesquisa.remove(usuario);
        _searchController.clear();
      });

      await _carregarMembros();
      
      if (mounted) {
        mostrarSnackBar(context, '${usuario.nome} adicionado ao grupo como $papel');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao adicionar membro: ${e.toString()}');
      }
    }
  }

  Future<void> _removerMembro(MembroGrupo membro) async {
    // Verificar se não é o próprio usuário
    if (membro.usuario.id == widget.usuarioLogado.id) {
      mostrarSnackBar(context, 'Você não pode remover a si mesmo do grupo');
      return;
    }

    // Verificar se não é o único admin
    if (membro.usuarioGrupo.papel == 'admin' && _estatisticas['admin'] == 1) {
      mostrarSnackBar(context, 'Não é possível remover o único administrador do grupo');
      return;
    }

    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: Text('Tem certeza que deseja remover ${membro.usuario.nome} do grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        await _usuarioGrupoRepo.desativarMembro(
          membro.usuario.id,
          widget.grupo.id,
        );

        // Log da ação
        await _atividadeRepo.createAtividade(
          Atividade(
            tipoEntidade: 'grupo',
            entidadeId: widget.grupo.id,
            usuarioId: widget.usuarioLogado.id,
            acao: 'deletou',
            grupoId: widget.grupo.id,
            detalhes: '{"acao": "remover_membro", "membro_removido": "${membro.usuario.nome}", "papel_anterior": "${membro.usuarioGrupo.papel}", "grupo_nome": "${widget.grupo.nome}"}',
          ),
        );

        await _carregarMembros();
        
        if (mounted) {
          mostrarSnackBar(context, '${membro.usuario.nome} removido do grupo');
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(context, 'Erro ao remover membro: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _alterarPapel(MembroGrupo membro, String novoPapel) async {
    // Verificar se não é o próprio usuário alterando para não-admin
    if (membro.usuario.id == widget.usuarioLogado.id && novoPapel != 'admin') {
      mostrarSnackBar(context, 'Você não pode alterar seu próprio papel para não-admin');
      return;
    }

    // Verificar se não é o único admin sendo rebaixado
    if (membro.usuarioGrupo.papel == 'admin' && _estatisticas['admin'] == 1 && novoPapel != 'admin') {
      mostrarSnackBar(context, 'Não é possível alterar o papel do único administrador');
      return;
    }

    try {
      await _usuarioGrupoRepo.alterarPapelMembro(
        membro.usuario.id,
        widget.grupo.id,
        novoPapel,
      );

      // Log da ação
      await _atividadeRepo.createAtividade(
        Atividade(
          tipoEntidade: 'grupo',
          entidadeId: widget.grupo.id,
          usuarioId: widget.usuarioLogado.id,
          acao: 'atualizou',
          grupoId: widget.grupo.id,
          detalhes: '{"acao": "alterar_papel", "membro": "${membro.usuario.nome}", "papel_anterior": "${membro.usuarioGrupo.papel}", "papel_novo": "$novoPapel", "grupo_nome": "${widget.grupo.nome}"}',
        ),
      );

      await _carregarMembros();
      
      if (mounted) {
        mostrarSnackBar(context, 'Papel de ${membro.usuario.nome} alterado para $novoPapel');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao alterar papel: ${e.toString()}');
      }
    }
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
        title: Text('Membros - ${widget.grupo.nome}'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_temPermissaoGerenciar)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _mostrarDialogAdicionarMembro(),
              tooltip: 'Adicionar membro',
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
                  _buildEstatisticaCard('Total', _estatisticas['total'] ?? 0, Icons.people, theme.colorScheme.primary),
                  _buildEstatisticaCard('Admin', _estatisticas['admin'] ?? 0, Icons.admin_panel_settings, Colors.red),
                  _buildEstatisticaCard('Moderador', _estatisticas['moderador'] ?? 0, Icons.shield, Colors.orange),
                  _buildEstatisticaCard('Membro', _estatisticas['membro'] ?? 0, Icons.person, Colors.blue),
                ],
              ),
            ),

          // Lista de membros
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _membros.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum membro encontrado',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarMembros,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _membros.length,
                          itemBuilder: (context, index) {
                            return _buildMembroCard(_membros[index]);
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

  Widget _buildMembroCard(MembroGrupo membro) {
    final theme = Theme.of(context);
    final isUsuarioLogado = membro.usuario.id == widget.usuarioLogado.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getCorPapel(membro.usuarioGrupo.papel),
              child: Icon(
                _getIconePapel(membro.usuarioGrupo.papel),
                color: _getCorTextoPapel(membro.usuarioGrupo.papel),
              ),
            ),
            const SizedBox(width: 12),

            // Informações do membro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          membro.usuario.nome,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUsuarioLogado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Você',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    membro.usuario.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCorPapel(membro.usuarioGrupo.papel),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          membro.usuarioGrupo.papel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getCorTextoPapel(membro.usuarioGrupo.papel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Desde ${_formatarData(membro.usuarioGrupo.dataEntrada)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ações
            if (_temPermissaoGerenciar)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'change_role':
                      _mostrarDialogAlterarPapel(membro);
                      break;
                    case 'remove':
                      _removerMembro(membro);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(width: 8),
                        Text('Alterar papel'),
                      ],
                    ),
                  ),
                  if (!isUsuarioLogado)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remover', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogAdicionarMembro() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adicionar Membro'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar usuário',
                      hintText: 'Digite nome ou email',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _buscarUsuarios(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_buscandoUsuarios)
                    const Center(child: CircularProgressIndicator())
                  else if (_usuariosPesquisa.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _usuariosPesquisa.length,
                        itemBuilder: (context, index) {
                          final usuario = _usuariosPesquisa[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(usuario.nome[0].toUpperCase()),
                            ),
                            title: Text(usuario.nome),
                            subtitle: Text(usuario.email),
                            trailing: PopupMenuButton<String>(
                              onSelected: (papel) {
                                _adicionarMembro(usuario, papel);
                                Navigator.pop(context);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'membro',
                                  child: Text('Adicionar como Membro'),
                                ),
                                const PopupMenuItem(
                                  value: 'moderador',
                                  child: Text('Adicionar como Moderador'),
                                ),
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Adicionar como Admin'),
                                ),
                              ],
                              child: const Icon(Icons.add),
                            ),
                          );
                        },
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    const Text('Nenhum usuário encontrado'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogAlterarPapel(MembroGrupo membro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alterar papel de ${membro.usuario.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Membro'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pop(context);
                _alterarPapel(membro, 'membro');
              },
            ),
            ListTile(
              title: const Text('Moderador'),
              leading: const Icon(Icons.shield),
              onTap: () {
                Navigator.pop(context);
                _alterarPapel(membro, 'moderador');
              },
            ),
            ListTile(
              title: const Text('Admin'),
              leading: const Icon(Icons.admin_panel_settings),
              onTap: () {
                Navigator.pop(context);
                _alterarPapel(membro, 'admin');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
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
      return '${diferenca.inDays} dias';
    } else if (diferenca.inDays < 30) {
      final semanas = (diferenca.inDays / 7).floor();
      return '$semanas ${semanas == 1 ? 'semana' : 'semanas'}';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }
} 