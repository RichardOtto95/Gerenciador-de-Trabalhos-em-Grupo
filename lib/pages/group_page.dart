import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key, required this.grupo});

  final Grupo grupo;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          child: Text(widget.grupo.nome, style: TextStyle(fontSize: 18)),
          onPressed: () => Navigator.pushNamed(
            context,
            "/group-data",
            arguments: widget.grupo,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  SizedBox(height: 15),
                  Icon(Icons.task),
                  SizedBox(height: 15),
                  Text("Sem tarefas no momento"),
                  SizedBox(height: 15),
                ],
              ),
            ),
            SizedBox(height: 20),
            ...List.generate(
              100,
              (i) => Card(
                child: ListTile(
                  title: Text("Tarefa ${i + 1}"),
                  onTap: () => Navigator.pushNamed(context, "/task"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
