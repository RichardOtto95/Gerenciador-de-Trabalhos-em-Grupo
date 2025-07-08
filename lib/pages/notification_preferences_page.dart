import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/preferencia_notificacao_model.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/shared/functions.dart';

class NotificationPreferencesPage extends StatefulWidget {
  final Usuario usuario;

  const NotificationPreferencesPage({Key? key, required this.usuario}) : super(key: key);

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  final PreferenciaNotificacaoRepository _preferenciaRepo = PreferenciaNotificacaoRepository();
  final GrupoRepository _grupoRepo = GrupoRepository();
  final UsuarioGrupoRepository _usuarioGrupoRepo = UsuarioGrupoRepository();

  List<PreferenciaNotificacao> _preferenciasGlobais = [];
  List<Grupo> _gruposUsuario = [];
  Map<String, List<PreferenciaNotificacao>> _preferenciasPorGrupo = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tiposNotificacao = [
    {
      'tipo': 'tarefa_atribuida',
      'titulo': 'Tarefa Atribuída',
      'descricao': 'Quando uma tarefa é atribuída para você',
      'icone': Icons.assignment,
      'cor': Colors.blue,
    },
    {
      'tipo': 'tarefa_vencendo',
      'titulo': 'Tarefa Vencendo',
      'descricao': 'Quando uma tarefa está próxima do prazo',
      'icone': Icons.warning,
      'cor': Colors.orange,
    },
    {
      'tipo': 'comentario_adicionado',
      'titulo': 'Novo Comentário',
      'descricao': 'Quando alguém comenta em suas tarefas',
      'icone': Icons.comment,
      'cor': Colors.green,
    },
    {
      'tipo': 'tarefa_completada',
      'titulo': 'Tarefa Concluída',
      'descricao': 'Quando uma tarefa é marcada como concluída',
      'icone': Icons.check_circle,
      'cor': Colors.teal,
    },
    {
      'tipo': 'convite_grupo',
      'titulo': 'Convite para Grupo',
      'descricao': 'Quando você é convidado para um grupo',
      'icone': Icons.group_add,
      'cor': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Carregar preferências globais
      final preferenciasGlobais = await _preferenciaRepo.getPreferenciasByUsuario(widget.usuario.id);
      final prefsGlobais = preferenciasGlobais.where((p) => p.grupoId == null).toList();

      // Carregar grupos do usuário
      final usuarioGrupos = await _usuarioGrupoRepo.getGruposByUsuario(widget.usuario.id);
      final gruposIds = usuarioGrupos.map((ug) => ug.grupoId).toList();
      
      List<Grupo> grupos = [];
      for (final grupoId in gruposIds) {
        final grupo = await _grupoRepo.getGrupoById(grupoId);
        if (grupo != null) {
          grupos.add(grupo);
        }
      }

      // Carregar preferências por grupo
      final preferenciasPorGrupo = <String, List<PreferenciaNotificacao>>{};
      for (final grupo in grupos) {
        final prefsGrupo = preferenciasGlobais.where((p) => p.grupoId == grupo.id).toList();
        preferenciasPorGrupo[grupo.id] = prefsGrupo;
      }

      // Criar preferências padrão se não existirem
      if (prefsGlobais.isEmpty) {
        await _preferenciaRepo.criarPreferenciasDefault(widget.usuario.id);
        final novasPrefs = await _preferenciaRepo.getPreferenciasByUsuario(widget.usuario.id);
        setState(() {
          _preferenciasGlobais = novasPrefs.where((p) => p.grupoId == null).toList();
        });
      } else {
        setState(() {
          _preferenciasGlobais = prefsGlobais;
        });
      }

      setState(() {
        _gruposUsuario = grupos;
        _preferenciasPorGrupo = preferenciasPorGrupo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao carregar configurações: $e');
      }
    }
  }

  Future<void> _alterarPreferencia(String tipo, bool ativo, {String? grupoId}) async {
    try {
      final preferencia = PreferenciaNotificacao(
        usuarioId: widget.usuario.id,
        grupoId: grupoId,
        tipoNotificacao: tipo,
        ativo: ativo,
      );

      await _preferenciaRepo.createPreferencia(preferencia);
      await _carregarDados();
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao salvar preferência: $e');
      }
    }
  }

  bool _getPreferenciaStatus(String tipo, {String? grupoId}) {
    if (grupoId != null) {
      // Busca preferência específica do grupo
      final prefsGrupo = _preferenciasPorGrupo[grupoId] ?? [];
      final pref = prefsGrupo.where((p) => p.tipoNotificacao == tipo).firstOrNull;
      if (pref != null) {
        return pref.ativo;
      }
    }
    
    // Busca preferência global
    final pref = _preferenciasGlobais.where((p) => p.tipoNotificacao == tipo).firstOrNull;
    return pref?.ativo ?? true; // Padrão: true
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Notificações'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Configurações Globais
                _buildSectionHeader(
                  'Configurações Globais',
                  'Estas configurações se aplicam a todos os grupos',
                  Icons.public,
                ),
                const SizedBox(height: 16),
                _buildNotificationTypesList(),
                
                const SizedBox(height: 32),
                
                // Configurações por Grupo
                if (_gruposUsuario.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Configurações por Grupo',
                    'Personalize as notificações para cada grupo',
                    Icons.group,
                  ),
                  const SizedBox(height: 16),
                  ..._gruposUsuario.map((grupo) => _buildGrupoSection(grupo)),
                ],
                
                const SizedBox(height: 32),
                
                // Informações adicionais
                _buildInfoSection(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String titulo, String descricao, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesList() {
    return Column(
      children: _tiposNotificacao.map((tipo) {
        final isAtivo = _getPreferenciaStatus(tipo['tipo']);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (tipo['cor'] as Color).withOpacity(0.1),
              child: Icon(
                tipo['icone'],
                color: tipo['cor'],
                size: 20,
              ),
            ),
            title: Text(
              tipo['titulo'],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              tipo['descricao'],
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: Switch(
              value: isAtivo,
              onChanged: (value) {
                _alterarPreferencia(tipo['tipo'], value);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrupoSection(Grupo grupo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do grupo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _parseColor(grupo.corTema).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _parseColor(grupo.corTema),
                  radius: 20,
                  child: Text(
                    grupo.nome.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (grupo.descricao != null)
                        Text(
                          grupo.descricao!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de preferências do grupo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _tiposNotificacao.map((tipo) {
                final isAtivo = _getPreferenciaStatus(tipo['tipo'], grupoId: grupo.id);
                final isHerdado = _preferenciasPorGrupo[grupo.id]
                    ?.where((p) => p.tipoNotificacao == tipo['tipo'])
                    .isEmpty ?? true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        tipo['icone'],
                        color: tipo['cor'],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo['titulo'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isHerdado)
                              Text(
                                'Usando configuração global',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAtivo,
                        onChanged: (value) {
                          _alterarPreferencia(tipo['tipo'], value, grupoId: grupo.id);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Como funciona',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Configurações por grupo sobrepõem as configurações globais\n'
            '• Se uma configuração não estiver definida para um grupo, a configuração global será usada\n'
            '• Você pode desabilitar completamente um tipo de notificação globalmente\n'
            '• As configurações são salvas automaticamente',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

// Extensão para firstOrNull
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
} 