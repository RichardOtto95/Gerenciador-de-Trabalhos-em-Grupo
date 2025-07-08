import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/status_tarefa_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/atribuicao_tarefa_model.dart';
import 'package:trabalho_bd/db/models/comentario_model.dart';
import 'package:trabalho_bd/shared/widgets/comment_widget.dart';
import 'package:trabalho_bd/shared/widgets/comment_input.dart';
import 'package:trabalho_bd/shared/widgets/comment_thread_widget.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Tarefa tarefa;
  late Grupo grupo;
  late Usuario usuario;
  List<StatusTarefa> _statusDisponiveis = [];
  List<Usuario> _responsaveis = [];
  List<ComentarioComAutor> _comentarios = [];
  List<ComentarioHierarquico> _comentariosHierarquicos = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  
  // Estado para edição de comentários
  String? _editingCommentId;
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    tarefa = args['tarefa'] as Tarefa;
    grupo = args['grupo'] as Grupo;
    usuario = args['usuario'] as Usuario;
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _totalComentarios {
    return _comentarios.length;
  }

  Future<void> _loadData() async {
    try {
      // Carrega status disponíveis
      final statusFuture = StatusTarefaRepository().getAllStatusTarefas();
      
      // Carrega responsáveis da tarefa
      final responsaveisFuture = _loadResponsaveis();
      
      // Carrega comentários da tarefa
      final comentariosFuture = _loadComentarios();
      
      final results = await Future.wait([statusFuture, responsaveisFuture, comentariosFuture]);
      
      setState(() {
        _statusDisponiveis = results[0] as List<StatusTarefa>;
        _responsaveis = results[1] as List<Usuario>;
        _comentarios = results[2] as List<ComentarioComAutor>;
        _comentariosHierarquicos = ComentarioRepository().organizarComentariosHierarquicos(_comentarios);
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados da tarefa: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Usuario>> _loadResponsaveis() async {
    try {
      final atribuicaoRepo = AtribuicaoTarefaRepository();
      return await atribuicaoRepo.getResponsaveisByTarefa(tarefa.id);
    } catch (e) {
      print('Erro ao carregar responsáveis: $e');
      return [];
    }
  }

  Future<List<ComentarioComAutor>> _loadComentarios() async {
    try {
      final comentarioRepo = ComentarioRepository();
      return await comentarioRepo.getComentariosComAutorByTarefa(tarefa.id);
    } catch (e) {
      print('Erro ao carregar comentários: $e');
      return [];
    }
  }

  Future<void> _reloadComentarios() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comentarios = await _loadComentarios();
      setState(() {
        _comentarios = comentarios;
        _comentariosHierarquicos = ComentarioRepository().organizarComentariosHierarquicos(comentarios);
        _isLoadingComments = false;
      });
    } catch (e) {
      print('Erro ao recarregar comentários: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _adicionarComentario(String conteudo) async {
    try {
      final comentario = Comentario(
        tarefaId: tarefa.id,
        autorId: usuario.id,
        conteudo: conteudo,
      );

      final comentarioRepo = ComentarioRepository();
      await comentarioRepo.createComentario(comentario);

      // Recarregar comentários
      await _reloadComentarios();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comentário adicionado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao adicionar comentário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editarComentario(String comentarioId, String novoConteudo) async {
    try {
      final comentarioAtual = _comentarios.firstWhere(
        (c) => c.id == comentarioId,
      );

      final comentarioAtualizado = Comentario(
        id: comentarioAtual.id,
        tarefaId: comentarioAtual.tarefaId,
        autorId: comentarioAtual.autorId,
        conteudo: novoConteudo,
        comentarioPaiId: comentarioAtual.comentarioPaiId,
        dataCriacao: comentarioAtual.dataCriacao,
        dataAtualizacao: DateTime.now(),
        editado: true,
      );

      final comentarioRepo = ComentarioRepository();
      await comentarioRepo.updateComentario(comentarioAtualizado);

      // Cancelar edição
      setState(() {
        _editingCommentId = null;
      });

      // Recarregar comentários
      await _reloadComentarios();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comentário editado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao editar comentário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao editar comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _excluirComentario(String comentarioId) async {
    try {
      final confirmar = await _mostrarModalConfirmacaoExclusaoComentario();
      
      if (confirmar != true) {
        return;
      }

      final comentarioRepo = ComentarioRepository();
      await comentarioRepo.deleteComentario(comentarioId);

      // Recarregar comentários
      await _reloadComentarios();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comentário excluído!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao excluir comentário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _responderComentario(String comentarioPaiId, String conteudo) async {
    try {
      final resposta = Comentario(
        tarefaId: tarefa.id,
        autorId: usuario.id,
        conteudo: conteudo,
        comentarioPaiId: comentarioPaiId,
      );

      final comentarioRepo = ComentarioRepository();
      await comentarioRepo.createComentario(resposta);

      // Recarregar comentários
      await _reloadComentarios();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resposta adicionada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao adicionar resposta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar resposta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _mostrarModalConfirmacaoExclusaoComentario() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Comentário'),
        content: Text('Tem certeza que deseja excluir este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Excluir'),
          ),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            status.nome,
            style: TextStyle(
              color: cor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioridadeIndicator(int prioridade) {
    Color cor;
    String texto;
    IconData icone;
    
    switch (prioridade) {
      case 1:
        cor = Colors.green;
        texto = "Baixa";
        icone = Icons.keyboard_arrow_down;
        break;
      case 2:
        cor = Colors.blue;
        texto = "Normal";
        icone = Icons.remove;
        break;
      case 3:
        cor = Colors.orange;
        texto = "Alta";
        icone = Icons.keyboard_arrow_up;
        break;
      case 4:
        cor = Colors.red;
        texto = "Urgente";
        icone = Icons.priority_high;
        break;
      default:
        cor = Colors.grey;
        texto = "?";
        icone = Icons.help;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 16),
          SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required Widget content,
    IconData? icon,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                                 if (icon != null) ...[
                   Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                   SizedBox(width: 8),
                 ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Não definida';
    
    return "${data.day.toString().padLeft(2, '0')}/"
           "${data.month.toString().padLeft(2, '0')}/"
           "${data.year} às "
           "${data.hour.toString().padLeft(2, '0')}:"
           "${data.minute.toString().padLeft(2, '0')}";
  }

  String _formatarDataSimples(DateTime? data) {
    if (data == null) return 'Não definida';
    
    return "${data.day.toString().padLeft(2, '0')}/"
           "${data.month.toString().padLeft(2, '0')}/"
           "${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Carregando...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tarefa.titulo,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Ações serão implementadas baseadas em permissões
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'editar':
                  _editarTarefa();
                  break;
                case 'excluir':
                  _excluirTarefa();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status e Prioridade
            Row(
              children: [
                _buildStatusIndicator(tarefa.statusId),
                SizedBox(width: 12),
                _buildPrioridadeIndicator(tarefa.prioridade),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Progresso
            if (tarefa.progresso > 0)
              _buildInfoCard(
                title: "Progresso",
                icon: Icons.trending_up,
                content: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${tarefa.progresso}% concluído"),
                        Text(
                          "${tarefa.progresso}/100",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: tarefa.progresso / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tarefa.progresso == 100 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Descrição
            if (tarefa.descricao != null && tarefa.descricao!.isNotEmpty)
              _buildInfoCard(
                title: "Descrição",
                icon: Icons.description,
                content: Text(
                  tarefa.descricao!,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            
            // Datas
            _buildInfoCard(
              title: "Datas",
              icon: Icons.schedule,
              content: Column(
                children: [
                  _buildDataRow("Criada em:", _formatarData(tarefa.dataCriacao)),
                  _buildDataRow("Última atualização:", _formatarData(tarefa.dataAtualizacao)),
                  if (tarefa.dataInicio != null)
                    _buildDataRow("Data de início:", _formatarDataSimples(tarefa.dataInicio)),
                  if (tarefa.dataVencimento != null)
                    _buildDataRow("Data de vencimento:", _formatarDataSimples(tarefa.dataVencimento)),
                  if (tarefa.dataConclusao != null)
                    _buildDataRow("Concluída em:", _formatarData(tarefa.dataConclusao)),
                ],
              ),
            ),
            
            // Estimativas e tempo
            if (tarefa.estimativaHoras != null || tarefa.horasTrabalhadas > 0)
              _buildInfoCard(
                title: "Tempo",
                icon: Icons.timer,
                content: Column(
                  children: [
                    if (tarefa.estimativaHoras != null)
                      _buildDataRow("Estimativa:", "${tarefa.estimativaHoras} horas"),
                    if (tarefa.horasTrabalhadas > 0)
                      _buildDataRow("Horas trabalhadas:", "${tarefa.horasTrabalhadas} horas"),
                    if (tarefa.estimativaHoras != null && tarefa.horasTrabalhadas > 0)
                      _buildDataRow(
                        "Restante:", 
                        "${(tarefa.estimativaHoras! - tarefa.horasTrabalhadas).toStringAsFixed(1)} horas"
                      ),
                  ],
                ),
              ),
            
            // Responsáveis
            _buildInfoCard(
              title: "Responsáveis",
              icon: Icons.people,
              content: _responsaveis.isEmpty
                  ? Text(
                      "Nenhum responsável atribuído",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      children: _responsaveis.map((usuario) => 
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(usuario.nome[0].toUpperCase()),
                          ),
                          title: Text(usuario.nome),
                          subtitle: Text(usuario.email),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ).toList(),
                    ),
            ),
            
                        // Sistema de Comentários com Respostas
            _buildInfoCard(
              title: "Comentários ($_totalComentarios)",
              icon: Icons.comment,
              content: Column(
                children: [
                  // Lista de comentários hierárquicos
                  if (_isLoadingComments)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_comentariosHierarquicos.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Ainda não há comentários",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Seja o primeiro a comentar!",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _comentariosHierarquicos.length,
                      itemBuilder: (context, index) {
                        final comentarioHierarquico = _comentariosHierarquicos[index];
                        
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CommentThreadWidget(
                            comentarioHierarquico: comentarioHierarquico,
                            currentUser: usuario,
                            editingCommentId: _editingCommentId,
                            onEdit: (comentarioId) {
                              setState(() {
                                _editingCommentId = _editingCommentId == comentarioId 
                                    ? null 
                                    : comentarioId;
                              });
                            },
                            onEditContent: _editarComentario,
                            onDelete: _excluirComentario,
                            onReply: _responderComentario,
                          ),
                        );
                      },
                    ),
                  
                  SizedBox(height: 16),
                  
                  // Input para novo comentário principal
                  if (_editingCommentId == null)
                    CommentInput(
                      currentUser: usuario,
                      onSubmit: _adicionarComentario,
                    ),
                ],
              ),
            ),
            
            // Placeholder para anexos futuros
            _buildInfoCard(
              title: "Anexos",
              icon: Icons.attach_file,
              content: Text(
                "Sistema de anexos será implementado em breve",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarTarefa() async {
    try {
      final result = await Navigator.of(context).pushNamed(
        "/task-edit",
        arguments: {
          'tarefa': tarefa,
          'grupo': grupo,
          'usuario': usuario,
        },
      );

      // Se a tarefa foi atualizada, recarregar os dados
      if (result != null && result is Tarefa) {
        setState(() {
          tarefa = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir edição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _excluirTarefa() async {
    try {
      // Verificar permissões - criador ou admin
      final temPermissao = _verificarPermissaoExclusao();
      
      if (!temPermissao) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você não tem permissão para excluir esta tarefa'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mostrar modal de confirmação
      final confirmar = await _mostrarModalConfirmacao();
      
      if (confirmar != true) {
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Excluindo tarefa...'),
              ],
            ),
          ),
        ),
      );

      // Excluir do banco de dados
      await TarefaRepository().deleteTarefa(tarefa.id);

      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarefa "${tarefa.titulo}" excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Voltar para a lista de tarefas
        Navigator.of(context).pop(true); // true indica que foi excluída
      }
    } catch (e) {
      // Fechar loading se estiver aberto
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('Erro ao excluir tarefa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _verificarPermissaoExclusao() {
    // Verificar se o usuário atual é o criador da tarefa
    if (usuario.id == tarefa.criadorId) {
      return true;
    }

    // Verificar se o usuário é admin do grupo
    // TODO: Implementar verificação de admin quando tivermos roles
    // Por enquanto, permitir para todos os membros do grupo
    return true;
  }

  Future<bool?> _mostrarModalConfirmacao() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Excluir Tarefa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir esta tarefa?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarefa.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (tarefa.descricao != null && tarefa.descricao!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      tarefa.descricao!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Esta ação não pode ser desfeita!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
