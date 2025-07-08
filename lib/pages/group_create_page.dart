import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/atividade_model.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';

class GroupCreate extends StatefulWidget {
  const GroupCreate({super.key, required this.criador});

  final Usuario criador;

  @override
  State<GroupCreate> createState() => _GroupCreateState();
}

class _GroupCreateState extends State<GroupCreate> {
  final formKey = GlobalKey<FormState>();

  String nome = "";
  String descricao = "";
  bool publico = false;
  int maxMembros = 10;
  Color corAtual = Color(0xff007bff);
  List<Usuario> participantes = [];

  final userRepo = UsuarioRepository();
  final minMembros = 2;
  List<Usuario> usuariosObtidos = [];
  bool pesquisando = false;

  @override
  initState() {
    participantes.add(widget.criador);
    super.initState();
  }

  bool participanteSelecionado(String email) {
    for (Usuario usuario in participantes) {
      if (email == usuario.email) return true;
    }

    return false;
  }

  Future<void> criarGrupo() async {
    if (participantes.length < minMembros) {
      mostrarSnackBar(
        context,
        "São necessários pelos menos $minMembros membros no grupo.",
      );
      return;
    }
    if (participantes.length > maxMembros) {
      mostrarSnackBar(context, "Há mais usuários do que o máximo estabelecido");
      return;
    }
    
    if (formKey.currentState!.validate()) {
      await executeWithLoad(context, () async {
        try {
          final grupoRepo = GrupoRepository();
          
          // Validar nome único por usuário
          final hasExistingGroup = await grupoRepo.hasGroupWithSameName(
            widget.criador.id, 
            nome
          );
          
          if (hasExistingGroup) {
            if (mounted) {
              mostrarSnackBar(
                context,
                "Você já possui um grupo com esse nome. Escolha outro nome.",
              );
            }
            return;
          }
          
          // Criar o grupo
          final grupo = Grupo(
            nome: nome,
            descricao: descricao,
            corTema: corAtual.toHexString().replaceRange(0, 2, "#"),
            publico: publico,
            maxMembros: maxMembros,
            criadorId: widget.criador.id,
          );
          await grupoRepo.createGrupo(grupo);

          final usuarioGrupoRepo = UsuarioGrupoRepository();
          final atividadeRepo = AtividadeRepository();

          // Adicionar usuários ao grupo
          for (int i = 0; i < participantes.length; i++) {
            final participante = participantes[i];
            final usuarioGrupo = UsuarioGrupo(
              usuarioId: participante.id,
              grupoId: grupo.id,
              papel: i == 0 ? 'admin' : 'membro', // Primeiro usuário (criador) é admin
              ativo: true,
            );

            await usuarioGrupoRepo.createUsuarioGrupo(usuarioGrupo);
          }

          // Registrar atividade de criação do grupo
          final atividade = Atividade(
            tipoEntidade: 'grupo',
            entidadeId: grupo.id,
            usuarioId: widget.criador.id,
            acao: 'criou',
            grupoId: grupo.id, // Added grupoId parameter
            detalhes: '{"acao": "criacao_grupo", "nome_grupo": "${grupo.nome}", "total_membros": ${participantes.length}}', // Valid JSON string
          );
          await atividadeRepo.createAtividade(atividade);

          if (mounted) {
            mostrarSnackBar(
              context,
              "Grupo '${grupo.nome}' criado com sucesso!",
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            mostrarSnackBar(
              context,
              "Erro ao criar grupo: ${e.toString()}",
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Criar Grupo")),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Este campo não pode ser vazio.";
                    }

                    return null;
                  },
                  onChanged: (value) => nome = value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Nome"),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextFormField(
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return "Este campo não pode ser vazio.";
                  //   }

                  //   return null;
                  // },
                  maxLength: 300,
                  minLines: 3,
                  maxLines: 10,
                  onChanged: (value) => descricao = value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Descrição"),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextFormField(
                  initialValue: maxMembros.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Este campo não pode ser vazio.";
                    }

                    int? val = int.tryParse(value);

                    if (val == null) return "Valor inválido";

                    if (val < 2) {
                      return "O grupo precisa de no mínimo 2 participantes.";
                    }
                    if (val > 50) {
                      return "O máximo de participantes é 50.";
                    }

                    return null;
                  },
                  onChanged: (value) => maxMembros = int.tryParse(value) ?? 0,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Maximo de membros"),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  SizedBox(width: 15),
                  Switch.adaptive(
                    value: publico,
                    onChanged: (value) => setState(() {
                      publico = value;
                    }),
                  ),
                  SizedBox(width: 10),
                  Text("Público", style: texts(context).bodyLarge),
                ],
              ),
              SizedBox(height: 15),
              Card(
                color: corAtual,
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: ListTile(
                  title: Text("Cor"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        Color tempColor = corAtual;
                        return AlertDialog(
                          title: const Text('Selecione uma cor'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: corAtual,
                              onColorChanged: (Color color) {
                                tempColor = color;
                              },
                              pickerAreaHeightPercent: 0.8,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            ElevatedButton(
                              child: const Text('Selecionar'),
                              onPressed: () {
                                setState(() {
                                  corAtual = tempColor;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 15),
              Divider(),

              Container(
                width: width(context),
                padding: EdgeInsetsGeometry.all(15),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Text("Participantes:", style: texts(context).titleMedium),

                    for (final (i, participante) in participantes.indexed)
                      InputChip(
                        label: Text(participante.nome),
                        deleteIcon: Icon(Icons.close_rounded),
                        onPressed: () {
                          if (i == 0) return;
                          setState(() {
                            participantes.remove(participante);
                          });
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  onChanged: (value) async {
                    if (value.isEmpty) {
                      usuariosObtidos = [];
                      setState(() {});
                      return;
                    }
                    if (value.length < 3) return;
                    try {
                      setState(() {
                        pesquisando = true;
                      });
                      usuariosObtidos = await userRepo.getUsuariosByNameEmail(
                        value,
                      );
                      setState(() {
                        pesquisando = false;
                      });
                    } catch (e) {
                      print(e);
                    } finally {
                      setState(() {
                        pesquisando = false;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hint: Text(
                      "Pesquisar usuarios",
                      style: TextStyle(
                        color: colors(context).onSurface.withAlpha(80),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (pesquisando)
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 15),
                  child: LinearProgressIndicator(),
                ),
              if (usuariosObtidos.isEmpty && !pesquisando)
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 15),
                      Icon(Icons.person_off_rounded),
                      SizedBox(height: 15),
                      Text("Nenhum usuário encontrado"),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              if (usuariosObtidos.isNotEmpty && !pesquisando)
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Column(
                      children: usuariosObtidos.map((usuario) {
                        final selecionado = participanteSelecionado(
                          usuario.email,
                        );
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: ListTile(
                            selected: selecionado,
                            title: Text(usuario.nome),
                            subtitle: Text(usuario.email),
                            leading: selecionado
                                ? Icon(Icons.check_rounded)
                                : null,
                            onTap: usuario.email == widget.criador.email
                                ? null
                                : () {
                                    if (selecionado) {
                                      participantes.remove(usuario);
                                    } else {
                                      participantes.add(usuario);
                                    }
                                    setState(() {});
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              SizedBox(height: 30),
              Button(label: "Criar", onTap: criarGrupo),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
