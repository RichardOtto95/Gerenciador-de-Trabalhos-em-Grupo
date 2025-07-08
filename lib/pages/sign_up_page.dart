import 'package:flutter/material.dart';
import 'package:trabalho_bd/services/auth_service.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmacaoSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final resultado = await AuthService.registerUser(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      confirmacaoSenha: _confirmacaoSenhaController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (resultado['success']) {
      mostrarSnackBar(context, resultado['message']);
      Navigator.pop(context);
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
              "Criar Conta",
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: const Text(
                "Preencha os dados para criar sua conta",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Spacer(),
            
            // Campo Nome
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome completo",
                  hintText: "Digite seu nome completo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Nome é obrigatório";
                  }
                  return AuthService.validateName(value);
                },
                textInputAction: TextInputAction.next,
              ),
            ),

            const SizedBox(height: 20),

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
                  hintText: "Mínimo 8 caracteres",
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
                  return AuthService.validatePassword(value);
                },
                textInputAction: TextInputAction.next,
              ),
            ),

            const SizedBox(height: 20),

            // Campo Confirmação de Senha
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _confirmacaoSenhaController,
                decoration: InputDecoration(
                  labelText: "Confirmar senha",
                  hintText: "Digite a senha novamente",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Confirmação de senha é obrigatória";
                  }
                  if (value != _senhaController.text) {
                    return "As senhas não coincidem";
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _cadastrar(),
              ),
            ),

            const SizedBox(height: 30),

            // Informações de segurança
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Requisitos da senha:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  const Text("• Mínimo 8 caracteres"),
                  const Text("• Pelo menos uma letra maiúscula"),
                  const Text("• Pelo menos uma letra minúscula"),
                  const Text("• Pelo menos um número"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botão de navegação para login
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Já tem uma conta?"),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fazer login"),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Botão de cadastro
            _isLoading
                ? const CircularProgressIndicator()
                : Button(
                    label: "Criar conta",
                    onTap: _cadastrar,
                  ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
