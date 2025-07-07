import 'package:flutter/material.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Esqueci a senha")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 0, 20),
            child: Text("Insira seu e-mail e a nova senha "),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("E-mail"),
              ),
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Senha"),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 20, right: 30),
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Alterar"),
            ),
          ),
        ],
      ),
    );
  }
}
