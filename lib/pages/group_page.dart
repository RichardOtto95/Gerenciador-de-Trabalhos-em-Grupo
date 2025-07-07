import 'package:flutter/material.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          child: Text("Nome do Grupo", style: TextStyle(fontSize: 18)),
          onPressed: () => Navigator.pushNamed(context, "/group-data"),
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
