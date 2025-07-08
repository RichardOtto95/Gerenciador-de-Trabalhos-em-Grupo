import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/notificacao_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/pages/dashboard_page.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool searchMode = false;

  List<Notificacao> notificacoes = [
    Notificacao(
      usuarioId: "usuarioId",
      tipo: "tipo",
      titulo: "titulo",
      mensagem: "mensagem",
    ),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Carrega as notificações
      final notiRepo = NotificacaoRepository();
      notificacoes = await notiRepo.getNotificacoesByUsuario(widget.usuario.id);
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuario.nome),
        actions: [
          Badge(
            backgroundColor: notificacoes.isEmpty ? Colors.transparent : null,

            label: notificacoes.isEmpty
                ? null
                : Text(notificacoes.length.toString()),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/profile");
              },
              icon: Icon(Icons.person),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hint: Text(
                    "Procurar por grupos",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .5),
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Grupos",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/groups',
                        arguments: widget.usuario,
                      );
                    },
                    icon: const Icon(Icons.view_list),
                    label: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            FutureBuilder<List<UsuarioGrupo>>(
              future: UsuarioGrupoRepository().getGruposByUsuario(
                widget.usuario.id,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        Icon(Icons.group_off_sharp),
                        SizedBox(height: 15),
                        Text("Sem grupos ainda"),
                        SizedBox(height: 15),
                      ],
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.map((ug) {
                    return FutureBuilder<Grupo?>(
                      future: GrupoRepository().getGrupoById(ug.grupoId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Card(
                            child: ListTile(title: LinearProgressIndicator()),
                          );
                        }
                        final grupo = snapshot.data!;

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: ListTile(
                            title: Text(grupo.nome),
                            subtitle: Text(grupo.descricao ?? ""),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FutureBuilder<int>(
                                  future: UsuarioGrupoRepository()
                                      .getUsuariosNoGrupo(ug.grupoId),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Text("");
                                    }
                                    return Text("${snapshot.data.toString()}/");
                                  },
                                ),
                                Text(grupo.maxMembros.toString()),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.of(
                                context,
                              ).pushNamed("/group", arguments: {
                                'grupo': grupo,
                                'usuario': widget.usuario,
                              });
                              setState(() {});
                            },
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            SizedBox(height: 20),
            // Dashboard integrado
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7, // 70% da altura da tela
              child: DashboardPage(usuario: widget.usuario),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).pushNamed("/group-create", arguments: widget.usuario);
          setState(() {});
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
