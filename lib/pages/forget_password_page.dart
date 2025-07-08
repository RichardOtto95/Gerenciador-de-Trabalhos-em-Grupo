import 'package:flutter/material.dart';
import 'package:trabalho_bd/services/auth_service.dart';
import 'package:trabalho_bd/shared/functions.dart';
import 'package:trabalho_bd/shared/widgets/button.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoSenhaController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Implementação simplificada - em produção seria necessário um sistema de tokens
      final resultado = await AuthService.resetPassword(
        email: _emailController.text.trim(),
        novaSenha: _novaSenhaController.text,
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      mostrarSnackBar(context, 'Erro interno: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar senha"),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            
            // Ícone e título
            Icon(
              Icons.lock_reset,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            
            Text(
              "Redefinir senha",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Digite seu e-mail e a nova senha que deseja usar",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 30),

            // Campo Email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  hintText: "Digite seu e-mail cadastrado",
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

            // Campo Nova Senha
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _novaSenhaController,
                decoration: InputDecoration(
                  labelText: "Nova senha",
                  hintText: "Digite sua nova senha",
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
                    return "Nova senha é obrigatória";
                  }
                  return AuthService.validatePassword(value);
                },
                textInputAction: TextInputAction.next,
              ),
            ),

            const SizedBox(height: 20),

            // Campo Confirmação Nova Senha
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextFormField(
                controller: _confirmacaoSenhaController,
                decoration: InputDecoration(
                  labelText: "Confirmar nova senha",
                  hintText: "Digite a nova senha novamente",
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
                    return "Confirmação da senha é obrigatória";
                  }
                  if (value != _novaSenhaController.text) {
                    return "As senhas não coincidem";
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _resetPassword(),
              ),
            ),

            const SizedBox(height: 30),

            // Informações de segurança
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Requisitos da nova senha:",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text("• Mínimo 8 caracteres"),
                    const Text("• Pelo menos uma letra maiúscula"),
                    const Text("• Pelo menos uma letra minúscula"),
                    const Text("• Pelo menos um número"),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Botão de redefinição
            _isLoading
                ? const CircularProgressIndicator()
                : Button(
                    label: "Redefinir senha",
                    onTap: _resetPassword,
                  ),

            const SizedBox(height: 20),

            // Botão voltar para login
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Voltar para o login"),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
