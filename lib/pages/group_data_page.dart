import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/functions.dart';

class GroupData extends StatefulWidget {
  const GroupData({super.key, required this.grupo});

  final Grupo grupo;

  @override
  State<GroupData> createState() => _GroupDataState();
}

class _GroupDataState extends State<GroupData> {
  Future<List<Usuario>> obterUsuarios() async {
    final ugr = UsuarioGrupoRepository();
    final result = await ugr.getUsuariosByGrupo(widget.grupo.id);
    List<Usuario> usuarios = [];
    final ur = UsuarioRepository();
    for (final ug in result) {
      final usuario = await ur.getUsuarioById(ug.usuarioId);
      if (usuario != null) {
        usuarios.add(usuario);
      }
    }
    return usuarios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupo.nome),
        actions: [
          IconButton(
            onPressed: () async {
              bool? delete = await showConfirmDialog(
                context: context,
                title: "Excluir Grupo",
                content:
                    "Tem certeza de que deseja excluir esse grupo para sempre?",
              );

              if (delete != null && delete) {
                final gr = GrupoRepository();
                final ugr = UsuarioGrupoRepository();
                await gr.deleteGrupo(widget.grupo.id);
                await ugr.deleteGrupo(widget.grupo.id);
                if (mounted) {
                  Navigator.popUntil(context, ModalRoute.withName("/home"));
                }
              }
            },
            icon: Icon(Icons.delete_forever),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text("Descrição:", style: texts(context).titleMedium),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(widget.grupo.descricao ?? ""),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text("Participantes", style: texts(context).titleMedium),
            ),
            SizedBox(height: 5),
            FutureBuilder<List<Usuario>>(
              future: obterUsuarios(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null) {
                  return Container();
                }

                return Column(
                  children: snapshot.data!.map((usuario) {
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        title: Text(usuario.nome),
                        subtitle: Text(usuario.email),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
