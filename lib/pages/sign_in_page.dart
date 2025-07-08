import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/constants.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final formKey = GlobalKey<FormState>();
  String email = "";
  String senha = "";

  Future<void> login() async {
    final repo = UsuarioRepository();
    final usuario = await repo.getUsuarioByEmail(email);
    if (usuario == null) {
      if (!mounted) return;
      mostrarSnackBar(context, "E-mail não cadastrado!");
    } else {
      if (!mounted) return;
      if (senha == usuario.senhaHash) {
        Navigator.of(context).pushNamed("/groups", arguments: usuario);
      } else {
        mostrarSnackBar(context, "E-mail ou senha incorreto.");
      }
    }
  }

  @override
  void initState() {
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        email = "teste@exemplo.com";
        senha = "senha123";
        await login();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              "Class Work",
              style: Theme.of(context).textTheme.displayMedium,
            ),
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
              child: TextFormField(
                decoration: InputDecoration(
                  label: Text("E-mail"),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => email = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }
                  if (!emailRegExp.hasMatch(value)) {
                    return 'Por favor, digite um e-mail válido.';
                  }
                  return null;
                },
              ),
            ),

            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                decoration: InputDecoration(
                  label: Text("Senha"),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => senha = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }
                  return null;
                },
                onFieldSubmitted: (value) => login(),
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
            Button(label: "Entrar", onTap: login),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
