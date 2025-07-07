import 'package:flutter/material.dart';
import 'package:trabalho_bd/shared/design_helper.dart';

class GroupData extends StatefulWidget {
  const GroupData({super.key});

  @override
  State<GroupData> createState() => _GroupDataState();
}

class _GroupDataState extends State<GroupData> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nome do grupo")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text("Descrição", style: texts(context).titleMedium),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Lorem ipsum dolor sit amet voc vous mer si docie lasd mentorian a pratuche",
              ),
            ),
            Text("Participantes", style: texts(context).titleMedium),
            SizedBox(height: 20),
            Card(child: ListTile(title: Text("Fulano"))),
            Card(child: ListTile(title: Text("Ciclano"))),
            Card(child: ListTile(title: Text("Beltrano"))),
            Card(child: ListTile(title: Text("Alano"))),
            Card(child: ListTile(title: Text("Dilano"))),
            Card(child: ListTile(title: Text("Elano"))),
          ],
        ),
      ),
    );
  }
}
