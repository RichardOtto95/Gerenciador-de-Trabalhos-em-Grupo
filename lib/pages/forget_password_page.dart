import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/shared/constants.dart';
import 'package:trabalho_bd/shared/functions.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  String email = "";
  String novaSenha = "";
  final formKey = GlobalKey<FormState>();

  void save() async {
    if (formKey.currentState!.validate()) {
      await executeWithLoad(context, () async {
        final repo = UsuarioRepository();
        final usuario = await repo.getUsuarioByEmail(email);
        if (usuario == null) {
          if (!mounted) return;
          mostrarSnackBar(context, "E-mail não encontrado!");
        } else {
          await repo.updatePassword(usuario.id, novaSenha);
          if (!mounted) return;
          mostrarSnackBar(context, "Usuário ${usuario.nome} atualizado!");
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Esqueci a senha")),
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 0, 20),
              child: Text("Insira seu e-mail e a nova senha "),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("E-mail"),
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
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Senha"),
                ),
                onChanged: (value) => novaSenha = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }

                  return null;
                },
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Confirmar senha"),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Este campo não pode ser vazio.";
                  }

                  if (value != novaSenha) {
                    return "As senhas não coincidem";
                  }

                  return null;
                },
                onFieldSubmitted: (value) => save(),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 20, right: 30),
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: save, child: Text("Alterar")),
            ),
          ],
        ),
      ),
    );
  }
}
