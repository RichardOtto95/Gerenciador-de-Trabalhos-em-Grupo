import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool searchMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fulano de tal"),
        actions: [
          Badge(
            label: Text("50"),
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
      body: Column(
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
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              "Grupos",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 15),
          // Card(
          //   child: ,
          // ),
          Center(
            child: Column(
              children: [
                SizedBox(height: 15),
                Icon(Icons.group_off_sharp),
                SizedBox(height: 15),
                Text("Sem grupos ainda"),
                SizedBox(height: 15),
              ],
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              "Tarefas",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 15),
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
        ],
      ),
    );
  }
}
