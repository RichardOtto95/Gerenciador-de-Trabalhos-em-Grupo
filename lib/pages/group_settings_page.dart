import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/atividade_model.dart';
import 'package:trabalho_bd/shared/functions.dart';

class GroupSettingsPage extends StatefulWidget {
  final Grupo grupo;
  final Usuario usuario;

  const GroupSettingsPage({
    super.key,
    required this.grupo,
    required this.usuario,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  final GrupoRepository _grupoRepo = GrupoRepository();
  final UsuarioGrupoRepository _usuarioGrupoRepo = UsuarioGrupoRepository();
  final AtividadeRepository _atividadeRepo = AtividadeRepository();

  bool _isLoading = false;
  bool _temPermissaoEditar = false;
  bool _podeUsuarioSair = false;
  Color _corSelecionada = Colors.blue;
  bool _isPublico = false;
  int _maxMembros = 50;
  String _papelUsuario = '';

  @override
  void initState() {
    super.initState();
    _inicializarDados();
    _verificarPermissoes();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _inicializarDados() {
    _nomeController.text = widget.grupo.nome;
    _descricaoController.text = widget.grupo.descricao ?? '';
    _corSelecionada = Color(int.parse(widget.grupo.corTema.replaceAll('#', '0xFF')));
    _isPublico = widget.grupo.publico;
    _maxMembros = widget.grupo.maxMembros;
  }

  Future<void> _verificarPermissoes() async {
    setState(() => _isLoading = true);

    try {
      final temPermissao = await _grupoRepo.temPermissaoEditarGrupo(
        widget.usuario.id,
        widget.grupo.id,
      );

      final podeUsuarioSair = await _usuarioGrupoRepo.podeUsuarioSairDoGrupo(
        widget.usuario.id,
        widget.grupo.id,
      );

      // Obter papel do usuário
      final membros = await _usuarioGrupoRepo.getMembrosComInfo(widget.grupo.id);
      final membroAtual = membros.firstWhere(
        (m) => m.usuario.id == widget.usuario.id,
        orElse: () => throw Exception('Usuário não encontrado no grupo'),
      );

      setState(() {
        _temPermissaoEditar = temPermissao;
        _podeUsuarioSair = podeUsuarioSair;
        _papelUsuario = membroAtual.usuarioGrupo.papel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao verificar permissões: ${e.toString()}');
      }
    }
  }

  Future<void> _salvarInformacoesBasicas() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verificar se o nome já existe
      final nomeExiste = await _grupoRepo.hasGroupWithSameNameForEdit(
        widget.grupo.criadorId,
        _nomeController.text.trim(),
        widget.grupo.id,
      );

      if (nomeExiste) {
        if (mounted) {
          mostrarSnackBar(context, 'Já existe um grupo com este nome');
        }
        return;
      }

      // Atualizar informações básicas
      await _grupoRepo.atualizarInformacoesBasicas(
        widget.grupo.id,
        _nomeController.text.trim(),
        _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
      );

      // Log da ação
      await _atividadeRepo.createAtividade(
        Atividade(
          tipoEntidade: 'grupo',
          entidadeId: widget.grupo.id,
          usuarioId: widget.usuario.id,
          acao: 'atualizou',
          grupoId: widget.grupo.id,
          detalhes: '{"acao": "editar_informacoes", "nome_anterior": "${widget.grupo.nome}", "nome_novo": "${_nomeController.text.trim()}", "descricao_editada": true}',
        ),
      );

      if (mounted) {
        mostrarSnackBar(context, 'Informações do grupo atualizadas');
        Navigator.pop(context, true); // Retorna true para indicar que houve alteração
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao atualizar informações: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _salvarConfiguracoes() async {
    setState(() => _isLoading = true);

    try {
      await _grupoRepo.atualizarConfiguracoes(
        widget.grupo.id,
        corTema: '#${_corSelecionada.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        publico: _isPublico,
        maxMembros: _maxMembros,
      );

      // Log da ação
      await _atividadeRepo.createAtividade(
        Atividade(
          tipoEntidade: 'grupo',
          entidadeId: widget.grupo.id,
          usuarioId: widget.usuario.id,
          acao: 'atualizou',
          grupoId: widget.grupo.id,
          detalhes: '{"acao": "editar_configuracoes", "cor_tema": "#${_corSelecionada.value.toRadixString(16).padLeft(8, '0').substring(2)}", "publico": $_isPublico, "max_membros": $_maxMembros}',
        ),
      );

      if (mounted) {
        mostrarSnackBar(context, 'Configurações do grupo atualizadas');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao atualizar configurações: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sairDoGrupo() async {
    // Confirmar saída
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar saída'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja sair do grupo "${widget.grupo.nome}"?'),
            const SizedBox(height: 8),
            const Text(
              'Esta ação não pode ser desfeita. Você será removido de todas as tarefas atribuídas a você neste grupo.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair do Grupo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      // Sair do grupo
      await _usuarioGrupoRepo.sairDoGrupo(widget.usuario.id, widget.grupo.id);

      // Log da ação
      await _atividadeRepo.createAtividade(
        Atividade(
          tipoEntidade: 'grupo',
          entidadeId: widget.grupo.id,
          usuarioId: widget.usuario.id,
          acao: 'deletou',
          grupoId: widget.grupo.id,
          detalhes: '{"acao": "sair_do_grupo", "usuario": "${widget.usuario.nome}", "papel_anterior": "$_papelUsuario", "grupo_nome": "${widget.grupo.nome}"}',
        ),
      );

      if (mounted) {
        mostrarSnackBar(context, 'Você saiu do grupo "${widget.grupo.nome}"');
        Navigator.pop(context, 'left_group'); // Retorna indicador de que saiu do grupo
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao sair do grupo: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarSeletorCor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher cor do grupo'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _corSelecionada,
            onColorChanged: (color) {
              setState(() => _corSelecionada = color);
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _salvarConfiguracoes();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informações do Grupo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Grupo',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _temPermissaoEditar,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _temPermissaoEditar,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_temPermissaoEditar)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _salvarInformacoesBasicas,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Salvar Informações'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracoesCard() {
    if (!_temPermissaoEditar) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Cor do tema
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _corSelecionada,
                radius: 12,
              ),
              title: const Text('Cor do Grupo'),
              subtitle: Text('#${_corSelecionada.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _mostrarSeletorCor,
            ),
            
            const Divider(),
            
            // Visibilidade
            SwitchListTile(
              secondary: const Icon(Icons.public),
              title: const Text('Grupo Público'),
              subtitle: Text(_isPublico ? 'Qualquer pessoa pode encontrar este grupo' : 'Apenas convidados podem participar'),
              value: _isPublico,
              onChanged: (value) {
                setState(() => _isPublico = value);
                _salvarConfiguracoes();
              },
            ),
            
            const Divider(),
            
            // Máximo de membros
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Máximo de Membros'),
              subtitle: Text('$_maxMembros membros'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _mostrarDialogMaxMembros(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcoesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Ações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sair do grupo
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Sair do Grupo'),
              subtitle: Text(_podeUsuarioSair 
                  ? 'Você será removido de todas as tarefas' 
                  : 'Você é o único administrador e não pode sair'),
              trailing: _podeUsuarioSair ? const Icon(Icons.arrow_forward_ios) : null,
              onTap: _podeUsuarioSair ? _sairDoGrupo : null,
              enabled: _podeUsuarioSair,
            ),
            
            if (!_podeUsuarioSair && _papelUsuario == 'admin')
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Para sair do grupo, você precisa promover outro membro a administrador.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogMaxMembros() {
    int valorTemp = _maxMembros;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Máximo de Membros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Defina o número máximo de membros para este grupo:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Slider(
                    value: valorTemp.toDouble(),
                    min: 5,
                    max: 200,
                    divisions: 39,
                    label: valorTemp.toString(),
                    onChanged: (value) {
                      setState(() => valorTemp = value.round());
                    },
                  ),
                  Text('$valorTemp membros'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _maxMembros = valorTemp);
              Navigator.pop(context);
              _salvarConfiguracoes();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações do Grupo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildConfiguracoesCard(),
                  const SizedBox(height: 16),
                  _buildAcoesCard(),
                ],
              ),
            ),
    );
  }
} 