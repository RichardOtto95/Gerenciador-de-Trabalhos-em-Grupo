import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/constants.dart';
import 'package:trabalho_bd/shared/functions.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final formKey = GlobalKey<FormState>();

  String nome = "";
  String email = "";
  String senha = "";

  void save() async {
    if (formKey.currentState!.validate()) {
      bool allright = false;
      await executeWithLoad(context, () async {
        final repo = UsuarioRepository();
        final usuario = await repo.getUsuarioByEmail(email);
        if (usuario == null) {
          await repo.createUsuario(
            Usuario(nome: nome, email: email, senhaHash: senha),
          );
          if (!mounted) return;
          mostrarSnackBar(context, "Usuário $nome criado!");
          allright = true;
        } else {
          if (!mounted) return;
          mostrarSnackBar(context, "E-mail já cadastrado!");
        }
      });
      if (allright && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastrar")),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }

                  return null;
                },
                onChanged: (value) => nome = value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Nome"),
                ),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }
                  if (!emailRegExp.hasMatch(value)) {
                    return 'Por favor, digite um e-mail válido.';
                  }
                  return null;
                },
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("E-mail"),
                ),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }
                  return null;
                },
                onChanged: (value) => senha = value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Senha"),
                ),
                obscureText: true,
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }

                  if (value != senha) {
                    return "As senhas não coincidem";
                  }

                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Confirmar senha"),
                ),
                obscureText: true,
                onFieldSubmitted: (value) => save(),
              ),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.only(top: 20, right: 30),
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: save, child: Text("Salvar")),
            ),
          ],
        ),
      ),
    );
  }
}
