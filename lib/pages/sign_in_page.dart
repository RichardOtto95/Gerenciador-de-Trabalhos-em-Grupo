import 'package:flutter/material.dart';
import 'package:trabalho_bd/services/auth_service.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final resultado = await AuthService.loginUser(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (resultado['success']) {
      // Navegar para a tela principal
      Navigator.of(context).pushNamedAndRemoveUntil(
        "/home",
        (route) => false,
        arguments: resultado['usuario'],
      );
    } else {
      mostrarSnackBar(context, resultado['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              "UNBGrupos",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Text(
                "Sua ferramenta favorita para\n facilitar os trabalhos em grupo.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),

            // Campo Email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  hintText: "Digite seu e-mail",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "E-mail é obrigatório";
                  }
                  return AuthService.validateEmail(value);
                },
                textInputAction: TextInputAction.next,
              ),
            ),

            const SizedBox(height: 20),

            // Campo Senha
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: "Senha",
                  hintText: "Digite sua senha",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Senha é obrigatória";
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),
            ),

            const SizedBox(height: 10),

            // Botões de navegação
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed("/forget-password"),
                    child: const Text("Esqueci a senha"),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed("/signup"),
                    child: const Text("Cadastrar"),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Botão de login
            _isLoading
                ? const CircularProgressIndicator()
                : Button(
                    label: "Entrar",
                    onTap: _login,
                  ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
