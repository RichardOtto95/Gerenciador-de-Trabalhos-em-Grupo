import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/status_tarefa_model.dart';
import 'package:trabalho_bd/db/models/atribuicao_tarefa_model.dart';
import 'package:trabalho_bd/shared/widgets/assignee_selector.dart';

class TaskEdit extends StatefulWidget {
  const TaskEdit({
    super.key,
    required this.tarefa,
    required this.grupo,
    required this.usuario,
  });

  final Tarefa tarefa;
  final Grupo grupo;
  final Usuario usuario;

  @override
  State<TaskEdit> createState() => _TaskEditState();
}

class _TaskEditState extends State<TaskEdit> {
  final formKey = GlobalKey<FormState>();

  // Campos do formulário
  late String titulo;
  late String descricao;
  late int prioridade;
  late int statusId;
  DateTime? dataVencimento;
  double? estimativaHoras;
  late int progresso;

  // Controllers
  late TextEditingController tituloController;
  late TextEditingController descricaoController;
  late TextEditingController estimativaController;
  late TextEditingController progressoController;

  // Lista de status disponíveis
  List<StatusTarefa> statusDisponiveis = [];
  bool isLoadingStatus = true;

  // Responsáveis
  List<String> responsavelIds = [];
  List<Usuario> membrosGrupo = [];
  bool isLoadingMembros = true;

  @override
  void initState() {
    super.initState();

    // Inicializar com dados da tarefa existente
    titulo = widget.tarefa.titulo;
    descricao = widget.tarefa.descricao ?? '';
    prioridade = widget.tarefa.prioridade;
    statusId = widget.tarefa.statusId;
    dataVencimento = widget.tarefa.dataVencimento;
    estimativaHoras = widget.tarefa.estimativaHoras;
    progresso = widget.tarefa.progresso;

    // Inicializar controllers
    tituloController = TextEditingController(text: titulo);
    descricaoController = TextEditingController(text: descricao);
    estimativaController = TextEditingController(
      text: estimativaHoras?.toString() ?? '',
    );
    progressoController = TextEditingController(text: progresso.toString());

    _carregarStatus();
    _carregarMembrosEResponsaveis();
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    estimativaController.dispose();
    progressoController.dispose();
    super.dispose();
  }

  Future<void> _carregarStatus() async {
    try {
      final status = await StatusTarefaRepository().getAllStatusTarefas();
      setState(() {
        statusDisponiveis = status;
        isLoadingStatus = false;
      });
    } catch (e) {
      print('Erro ao carregar status: $e');
      setState(() {
        isLoadingStatus = false;
      });
    }
  }

  Future<void> _carregarMembrosEResponsaveis() async {
    try {
      // Carregar membros do grupo
      final usuarioGrupoRepo = UsuarioGrupoRepository();
      final usuarioRepo = UsuarioRepository();

      final usuariosGrupo = await usuarioGrupoRepo.getUsuariosByGrupo(
        widget.grupo.id,
      );

      List<Usuario> usuarios = [];
      for (var usuarioGrupo in usuariosGrupo) {
        if (usuarioGrupo.ativo) {
          final usuario = await usuarioRepo.getUsuarioById(
            usuarioGrupo.usuarioId,
          );
          if (usuario != null) {
            usuarios.add(usuario);
          }
        }
      }

      // Carregar responsáveis atuais da tarefa
      final atribuicaoRepo = AtribuicaoTarefaRepository();
      final responsaveisAtuais = await atribuicaoRepo.getResponsaveisByTarefa(
        widget.tarefa.id,
      );

      setState(() {
        membrosGrupo = usuarios;
        responsavelIds = responsaveisAtuais.map((user) => user.id).toList();
        isLoadingMembros = false;
      });
    } catch (e) {
      print('Erro ao carregar membros e responsáveis: $e');
      setState(() {
        isLoadingMembros = false;
      });
    }
  }

  Future<void> _selecionarData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: dataVencimento ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: Locale('pt', 'BR'),
    );

    if (dataEscolhida != null) {
      setState(() {
        dataVencimento = dataEscolhida;
      });
    }
  }

  Future<void> _atualizarTarefa() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    formKey.currentState!.save();

    try {
      // Atualizar objeto tarefa
      final tarefaAtualizada = Tarefa(
        id: widget.tarefa.id,
        titulo: titulo,
        descricao: descricao.isEmpty ? null : descricao,
        grupoId: widget.tarefa.grupoId,
        criadorId: widget.tarefa.criadorId,
        statusId: statusId,
        prioridade: prioridade,
        dataInicio: widget.tarefa.dataInicio,
        dataVencimento: dataVencimento,
        estimativaHoras: estimativaHoras,
        horasTrabalhadas: widget.tarefa.horasTrabalhadas,
        progresso: progresso,
        dataCriacao: widget.tarefa.dataCriacao,
        dataAtualizacao: DateTime.now(),
        dataConclusao: progresso == 100 ? DateTime.now() : null,
      );

      // Salvar no banco
      await TarefaRepository().updateTarefa(tarefaAtualizada);

      // Atualizar responsáveis
      final atribuicaoRepo = AtribuicaoTarefaRepository();
      await atribuicaoRepo.syncAtribuicoesTarefa(
        widget.tarefa.id,
        responsavelIds,
        widget.usuario.id,
      );

      // Feedback positivo
      final mensagem = responsavelIds.isEmpty
          ? "Tarefa atualizada com sucesso!"
          : "Tarefa atualizada e atribuída a ${responsavelIds.length} responsáve${responsavelIds.length == 1 ? 'l' : 'is'}!";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
        );

        // Voltar para página de detalhes com tarefa atualizada
        Navigator.of(context).pop(tarefaAtualizada);
      }
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Editar Tarefa"),
            Text(
              "Grupo: ${widget.grupo.nome}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: isLoadingStatus
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextFormField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        labelText: "Título da tarefa *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Título é obrigatório';
                        }
                        if (value.trim().length < 3) {
                          return 'Título deve ter pelo menos 3 caracteres';
                        }
                        return null;
                      },
                      onSaved: (value) => titulo = value!.trim(),
                    ),

                    SizedBox(height: 20),

                    // Descrição
                    TextFormField(
                      controller: descricaoController,
                      decoration: InputDecoration(
                        labelText: "Descrição",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                      onSaved: (value) => descricao = value?.trim() ?? '',
                    ),

                    SizedBox(height: 20),

                    // Status
                    DropdownButtonFormField<int>(
                      value: statusId,
                      decoration: InputDecoration(
                        labelText: "Status da tarefa *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: statusDisponiveis.map((status) {
                        Color cor;
                        try {
                          cor = Color(
                            int.parse(status.cor.replaceFirst('#', '0xFF')),
                          );
                        } catch (e) {
                          cor = Colors.grey;
                        }

                        return DropdownMenuItem<int>(
                          value: status.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(status.nome),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          statusId = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Status é obrigatório';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Prioridade
                    DropdownButtonFormField<int>(
                      value: prioridade,
                      decoration: InputDecoration(
                        labelText: "Prioridade *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Row(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text("Baixa"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Row(
                            children: [
                              Icon(Icons.remove, color: Colors.blue),
                              SizedBox(width: 8),
                              Text("Normal"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Row(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text("Alta"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Row(
                            children: [
                              Icon(Icons.priority_high, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Urgente"),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          prioridade = value!;
                        });
                      },
                    ),

                    SizedBox(height: 20),

                    // Data de vencimento
                    InkWell(
                      onTap: _selecionarData,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dataVencimento == null
                                    ? "Selecionar data de vencimento"
                                    : "Vencimento: ${dataVencimento!.day.toString().padLeft(2, '0')}/"
                                          "${dataVencimento!.month.toString().padLeft(2, '0')}/"
                                          "${dataVencimento!.year}",
                                style: TextStyle(
                                  color: dataVencimento == null
                                      ? Colors.grey[600]
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (dataVencimento != null)
                              IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    dataVencimento = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Estimativa de horas
                    TextFormField(
                      controller: estimativaController,
                      decoration: InputDecoration(
                        labelText: "Estimativa de horas",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                        suffixText: "horas",
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final horas = double.tryParse(value);
                          if (horas == null || horas <= 0) {
                            return 'Estimativa deve ser um número positivo';
                          }
                          if (horas > 1000) {
                            return 'Estimativa não pode ser maior que 1000 horas';
                          }
                        }
                        return null;
                      },
                      onSaved: (value) {
                        if (value != null && value.isNotEmpty) {
                          estimativaHoras = double.tryParse(value);
                        } else {
                          estimativaHoras = null;
                        }
                      },
                    ),

                    SizedBox(height: 20),

                    // Progresso
                    TextFormField(
                      controller: progressoController,
                      decoration: InputDecoration(
                        labelText: "Progresso *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                        suffixText: "%",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Progresso é obrigatório';
                        }
                        final prog = int.tryParse(value);
                        if (prog == null || prog < 0 || prog > 100) {
                          return 'Progresso deve ser entre 0 e 100';
                        }
                        return null;
                      },
                      onSaved: (value) => progresso = int.parse(value!),
                    ),

                    SizedBox(height: 24),

                    // Seletor de Responsáveis
                    if (isLoadingMembros)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text("Carregando responsáveis..."),
                          ],
                        ),
                      )
                    else
                      AssigneeSelector(
                        availableUsers: membrosGrupo,
                        selectedUserIds: responsavelIds,
                        onSelectionChanged: (selectedIds) {
                          setState(() {
                            responsavelIds = selectedIds;
                          });
                        },
                        title: "Responsáveis pela Tarefa",
                      ),

                    SizedBox(height: 30),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text("Cancelar"),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _atualizarTarefa,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text("Atualizar Tarefa"),
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
}
