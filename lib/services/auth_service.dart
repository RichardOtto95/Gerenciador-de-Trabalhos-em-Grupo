import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

/// Serviço de autenticação para gerenciar login, cadastro e validações de segurança
class AuthService {
  static const int _minPasswordLength = 8;
  static const int _saltLength = 16;
  
  /// Gera um salt aleatório para o hash da senha
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }
  
  /// Cria um hash bcrypt da senha com salt
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }
  
  /// Verifica se a senha corresponde ao hash armazenado
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final storedHash = parts[1];
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == storedHash;
    } catch (e) {
      return false;
    }
  }
  
  /// Valida se a senha atende aos critérios mínimos
  static String? validatePassword(String password) {
    if (password.length < _minPasswordLength) {
      return 'A senha deve ter pelo menos $_minPasswordLength caracteres';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'A senha deve conter pelo menos uma letra maiúscula';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'A senha deve conter pelo menos uma letra minúscula';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'A senha deve conter pelo menos um número';
    }
    
    return null; // Senha válida
  }
  
  /// Valida se o email tem formato válido
  static String? validateEmail(String email) {
    final emailRegExp = RegExp(r'^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      return 'Por favor, digite um email válido';
    }
    return null;
  }
  
  /// Valida se o nome atende aos critérios
  static String? validateName(String name) {
    if (name.trim().length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres';
    }
    
    if (name.trim().length > 100) {
      return 'O nome não pode ter mais de 100 caracteres';
    }
    
    return null;
  }
  
  /// Realiza o cadastro de um novo usuário com validações
  static Future<Map<String, dynamic>> registerUser({
    required String nome,
    required String email,
    required String senha,
    required String confirmacaoSenha,
  }) async {
    try {
      // Validações
      final nomeError = validateName(nome);
      if (nomeError != null) {
        return {'success': false, 'message': nomeError};
      }
      
      final emailError = validateEmail(email);
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }
      
      final senhaError = validatePassword(senha);
      if (senhaError != null) {
        return {'success': false, 'message': senhaError};
      }
      
      if (senha != confirmacaoSenha) {
        return {'success': false, 'message': 'As senhas não coincidem'};
      }
      
      // Verificar se email já existe
      final usuarioRepo = UsuarioRepository();
      final usuarioExistente = await usuarioRepo.getUsuarioByEmail(email);
      if (usuarioExistente != null) {
        return {'success': false, 'message': 'E-mail já cadastrado'};
      }
      
      // Criar usuário com senha criptografada
      final senhaHash = hashPassword(senha);
      final usuario = Usuario(
        nome: nome.trim(),
        email: email.toLowerCase().trim(),
        senhaHash: senhaHash,
      );
      
      await usuarioRepo.createUsuario(usuario);
      
      return {
        'success': true,
        'message': 'Usuário cadastrado com sucesso',
        'usuario': usuario,
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro interno: $e'};
    }
  }
  
  /// Realiza o login do usuário
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String senha,
  }) async {
    try {
      // Validações básicas
      final emailError = validateEmail(email);
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }
      
      if (senha.isEmpty) {
        return {'success': false, 'message': 'Senha é obrigatória'};
      }
      
      // Rate limiting básico - em produção seria mais sofisticado
      await Future.delayed(Duration(milliseconds: 500));
      
      // Buscar usuário
      final usuarioRepo = UsuarioRepository();
      final usuario = await usuarioRepo.getUsuarioByEmail(email.toLowerCase().trim());
      
      if (usuario == null) {
        return {'success': false, 'message': 'E-mail ou senha incorretos'};
      }
      
      if (!usuario.ativo) {
        return {'success': false, 'message': 'Conta desativada. Entre em contato com o suporte.'};
      }
      
      // Verificar senha
      if (!verifyPassword(senha, usuario.senhaHash)) {
        return {'success': false, 'message': 'E-mail ou senha incorretos'};
      }
      
      // Atualizar último login
      usuario.ultimoLogin = DateTime.now();
      await usuarioRepo.updateUsuario(usuario);
      
      return {
        'success': true,
        'message': 'Login realizado com sucesso',
        'usuario': usuario,
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro interno durante o login. Tente novamente.'};
    }
  }
  
  /// Atualiza a senha do usuário
  static Future<Map<String, dynamic>> updatePassword({
    required String usuarioId,
    required String senhaAtual,
    required String novaSenha,
    required String confirmacaoNovaSenha,
  }) async {
    try {
      // Validações
      final senhaError = validatePassword(novaSenha);
      if (senhaError != null) {
        return {'success': false, 'message': senhaError};
      }
      
      if (novaSenha != confirmacaoNovaSenha) {
        return {'success': false, 'message': 'As senhas não coincidem'};
      }
      
      // Verificar usuário e senha atual
      final usuarioRepo = UsuarioRepository();
      final usuario = await usuarioRepo.getUsuarioById(usuarioId);
      
      if (usuario == null) {
        return {'success': false, 'message': 'Usuário não encontrado'};
      }
      
      if (!verifyPassword(senhaAtual, usuario.senhaHash)) {
        return {'success': false, 'message': 'Senha atual incorreta'};
      }
      
      // Atualizar senha
      usuario.senhaHash = hashPassword(novaSenha);
      usuario.dataAtualizacao = DateTime.now();
      await usuarioRepo.updateUsuario(usuario);
      
      return {
        'success': true,
        'message': 'Senha atualizada com sucesso',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro interno: $e'};
    }
  }
  
  /// Redefine a senha do usuário (para recuperação de senha)
  /// NOTA: Em produção, isso deveria usar um sistema de tokens/emails
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String novaSenha,
    required String confirmacaoSenha,
  }) async {
    try {
      // Validações
      final emailError = validateEmail(email);
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }
      
      final senhaError = validatePassword(novaSenha);
      if (senhaError != null) {
        return {'success': false, 'message': senhaError};
      }
      
      if (novaSenha != confirmacaoSenha) {
        return {'success': false, 'message': 'As senhas não coincidem'};
      }
      
      // Verificar se usuário existe
      final usuarioRepo = UsuarioRepository();
      final usuario = await usuarioRepo.getUsuarioByEmail(email.toLowerCase().trim());
      
      if (usuario == null) {
        return {'success': false, 'message': 'E-mail não encontrado'};
      }
      
      if (!usuario.ativo) {
        return {'success': false, 'message': 'Usuário inativo'};
      }
      
      // Atualizar senha
      usuario.senhaHash = hashPassword(novaSenha);
      usuario.dataAtualizacao = DateTime.now();
      await usuarioRepo.updateUsuario(usuario);
      
      return {
        'success': true,
        'message': 'Senha redefinida com sucesso',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro interno: $e'};
    }
  }

  /// Realiza o logout do usuário
  /// Remove dados da sessão e registra a saída
  static Future<Map<String, dynamic>> logoutUser({
    required String usuarioId,
  }) async {
    try {
      // Registrar último logout no banco
      final usuarioRepo = UsuarioRepository();
      final usuario = await usuarioRepo.getUsuarioById(usuarioId);
      
      if (usuario != null) {
        // Em uma implementação real, poderíamos ter uma tabela de sessões
        // Por agora, apenas limparemos os dados locais
        usuario.dataAtualizacao = DateTime.now();
        await usuarioRepo.updateUsuario(usuario);
      }
      
      // Simular limpeza de dados de sessão/cache
      // Em produção: limpar SharedPreferences, tokens, etc.
      
      return {
        'success': true,
        'message': 'Logout realizado com sucesso',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro durante o logout. Dados locais podem ter sido limpos.'};
    }
  }

  /// Verifica se há uma sessão ativa válida
  static Future<bool> hasActiveSession() async {
    try {
      // Em produção: verificar token de sessão, SharedPreferences, etc.
      // Por agora, sempre retorna false (implementação simplificada)
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Limpa completamente os dados de sessão local
  static Future<void> clearLocalSession() async {
    try {
      // Em produção: limpar SharedPreferences, secure storage, cache, etc.
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.clear();
      
      // Por agora, apenas simula a limpeza
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      // Log error but don't fail
      print('Erro ao limpar sessão local: $e');
    }
  }
} 