import 'package:flutter/material.dart';

class Task extends StatelessWidget {
  const Task({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Título da task")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Lorem ipsum dolor sit amet voc vous mer si docie lasd mentorian a pratuche",
            ),
          ),
        ],
      ),
    );
  }
}
