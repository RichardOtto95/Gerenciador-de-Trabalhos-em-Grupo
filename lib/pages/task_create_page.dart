import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/atribuicao_tarefa_model.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';
import 'package:trabalho_bd/shared/widgets/assignee_selector.dart';

class TaskCreate extends StatefulWidget {
  const TaskCreate({
    super.key, 
    required this.grupo,
    required this.criador,
  });

  final Grupo grupo;
  final Usuario criador;

  @override
  State<TaskCreate> createState() => _TaskCreateState();
}

class _TaskCreateState extends State<TaskCreate> {
  final formKey = GlobalKey<FormState>();

  // Campos do formulário
  String titulo = "";
  String descricao = "";
  int prioridade = 2; // Normal por padrão
  DateTime? dataVencimento;
  double? estimativaHoras;
  List<String> responsavelIds = [];

  // Dados dos membros do grupo
  List<Usuario> membrosGrupo = [];
  bool isLoadingMembros = true;

  // Lista de prioridades
  final List<Map<String, dynamic>> prioridades = [
    {'valor': 1, 'nome': 'Baixa', 'cor': Colors.green},
    {'valor': 2, 'nome': 'Normal', 'cor': Colors.blue},
    {'valor': 3, 'nome': 'Alta', 'cor': Colors.orange},
    {'valor': 4, 'nome': 'Urgente', 'cor': Colors.red},
  ];

  // Controllers para campos específicos
  final TextEditingController estimativaController = TextEditingController();
  final TextEditingController dataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarMembrosGrupo();
  }

  @override
  void dispose() {
    estimativaController.dispose();
    dataController.dispose();
    super.dispose();
  }

  Future<void> _carregarMembrosGrupo() async {
    try {
      final usuarioGrupoRepo = UsuarioGrupoRepository();
      final usuarioRepo = UsuarioRepository();
      
      // Buscar relações usuário-grupo
      final usuariosGrupo = await usuarioGrupoRepo.getUsuariosByGrupo(widget.grupo.id);
      
      // Buscar dados completos dos usuários
      List<Usuario> usuarios = [];
      for (var usuarioGrupo in usuariosGrupo) {
        if (usuarioGrupo.ativo) {
          final usuario = await usuarioRepo.getUsuarioById(usuarioGrupo.usuarioId);
          if (usuario != null) {
            usuarios.add(usuario);
          }
        }
      }
      
      setState(() {
        membrosGrupo = usuarios;
        isLoadingMembros = false;
      });
    } catch (e) {
      print('Erro ao carregar membros do grupo: $e');
      setState(() {
        isLoadingMembros = false;
      });
      
      if (mounted) {
        mostrarSnackBar(context, "Erro ao carregar membros do grupo: $e");
      }
    }
  }

  Future<void> selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataVencimento ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: Locale('pt', 'BR'),
    );
    
    if (picked != null) {
      setState(() {
        dataVencimento = picked;
        dataController.text = "${picked.day.toString().padLeft(2, '0')}/"
                             "${picked.month.toString().padLeft(2, '0')}/"
                             "${picked.year}";
      });
    }
  }

  Future<void> criarTarefa() async {
    if (!formKey.currentState!.validate()) return;

    bool sucesso = false;
    
    await executeWithLoad(context, () async {
      try {
        final tarefa = Tarefa(
          titulo: titulo,
          descricao: descricao.isEmpty ? null : descricao,
          grupoId: widget.grupo.id,
          criadorId: widget.criador.id,
          statusId: 1, // Pendente
          prioridade: prioridade,
          dataVencimento: dataVencimento,
          estimativaHoras: estimativaHoras,
        );

        final tarefaRepo = TarefaRepository();
        await tarefaRepo.createTarefa(tarefa);
        
        // Criar atribuições de responsáveis se houver algum selecionado
        if (responsavelIds.isNotEmpty) {
          final atribuicaoRepo = AtribuicaoTarefaRepository();
          await atribuicaoRepo.syncAtribuicoesTarefa(
            tarefa.id,
            responsavelIds,
            widget.criador.id,
          );
        }
        
        sucesso = true;
        
        final mensagem = responsavelIds.isEmpty 
            ? "Tarefa \"$titulo\" criada com sucesso!"
            : "Tarefa \"$titulo\" criada e atribuída a ${responsavelIds.length} responsáve${responsavelIds.length == 1 ? 'l' : 'is'}!";
        
        if (mounted) {
          mostrarSnackBar(context, mensagem);
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(context, "Erro ao criar tarefa: $e");
        }
      }
    });

    if (sucesso && mounted) {
      Navigator.pop(context, true); // Retorna true indicando que foi criada
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nova Tarefa"),
            Text(
              "Grupo: ${widget.grupo.nome}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Título *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 200,
                onChanged: (value) => titulo = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "O título é obrigatório";
                  }
                  if (value.trim().length < 3) {
                    return "O título deve ter pelo menos 3 caracteres";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Descrição
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Descrição",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: "Descreva os detalhes da tarefa...",
                ),
                maxLines: 4,
                maxLength: 1000,
                onChanged: (value) => descricao = value,
              ),
              SizedBox(height: 16),

              // Prioridade
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: "Prioridade",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                value: prioridade,
                items: prioridades.map((prio) {
                  return DropdownMenuItem<int>(
                    value: prio['valor'],
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: prio['cor'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(prio['nome']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      prioridade = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Data de vencimento
              TextFormField(
                controller: dataController,
                decoration: InputDecoration(
                  labelText: "Data de Vencimento",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: "Toque para selecionar",
                  suffixIcon: dataVencimento != null 
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            dataVencimento = null;
                            dataController.clear();
                          });
                        },
                      )
                    : null,
                ),
                readOnly: true,
                onTap: selecionarData,
              ),
              SizedBox(height: 16),

              // Estimativa de horas
              TextFormField(
                controller: estimativaController,
                decoration: InputDecoration(
                  labelText: "Estimativa de Horas",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: "horas",
                  hintText: "Ex: 2.5",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  if (value.isEmpty) {
                    estimativaHoras = null;
                  } else {
                    estimativaHoras = double.tryParse(value);
                  }
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final horas = double.tryParse(value);
                    if (horas == null) {
                      return "Digite um número válido";
                    }
                    if (horas <= 0) {
                      return "A estimativa deve ser maior que zero";
                    }
                    if (horas > 999) {
                      return "A estimativa deve ser menor que 999 horas";
                    }
                  }
                  return null;
                },
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
                      Text("Carregando membros do grupo..."),
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
              SizedBox(height: 24),

              // Informações adicionais
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Informações da Tarefa",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.group, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text("Grupo: ${widget.grupo.nome}"),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text("Criador: ${widget.criador.nome}"),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.info, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text("Status inicial: Pendente"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Botão de criar
              Button(
                label: "Criar Tarefa",
                onTap: criarTarefa,
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 