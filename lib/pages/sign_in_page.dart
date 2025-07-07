import 'package:flutter/material.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Spacer(),
          Text("Class Work", style: Theme.of(context).textTheme.displayMedium),
          Spacer(),
          Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: Text(
              "Sua ferramenta favorita para facilitar os trabalhos em grupo",
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              decoration: InputDecoration(
                label: Text("E-mail"),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              decoration: InputDecoration(
                label: Text("Senha"),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed("/forget-password"),
                  child: Text("Esqueci a senha"),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed("/signup"),
                  child: Text("Cadastrar"),
                ),
              ],
            ),
          ),
          Spacer(),
          Button(
            label: "Entrar",
            onTap: () => Navigator.of(context).pushNamed("/home"),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
