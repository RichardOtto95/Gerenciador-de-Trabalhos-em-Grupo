import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/services/auth_service.dart';
import 'package:trabalho_bd/shared/functions.dart';

class Profile extends StatefulWidget {
  final Usuario usuario;

  const Profile({super.key, required this.usuario});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _nomeController.text = widget.usuario.nome;
    _emailController.text = widget.usuario.email;
    _bioController.text = widget.usuario.bio ?? '';
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar logout'),
        content: const Text('Tem certeza que deseja sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Realizar logout
      final resultado = await AuthService.logoutUser(
        usuarioId: widget.usuario.id,
      );

      // Limpar dados da sessão
      await AuthService.clearLocalSession();

      if (!mounted) return;

      // Navegar para tela de login removendo todo o histórico
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );

      // Mostrar mensagem de sucesso (se ainda montado)
      if (resultado['success'] && mounted) {
        mostrarSnackBar(context, resultado['message']);
      }
    } catch (e) {
      setState(() {
        _isLoggingOut = false;
      });
      
      if (mounted) {
        mostrarSnackBar(context, 'Erro durante logout: $e');
      }
    }
  }

  Future<void> _selectProfilePhoto() async {
    try {
      setState(() {
        _isUploadingPhoto = true;
      });

      // Mostrar opções de seleção
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Selecionar foto de perfil'),
          content: Text('Como você gostaria de selecionar sua foto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text('Galeria'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text('Câmera'),
            ),
          ],
        ),
      );

      if (source == null) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // Selecionar imagem
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // Criar diretório para fotos de perfil
      final directory = await getApplicationDocumentsDirectory();
      final profilePhotosDir = Directory('${directory.path}/profile_photos');
      
      if (!await profilePhotosDir.exists()) {
        await profilePhotosDir.create(recursive: true);
      }

      // Gerar nome único para a foto
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = image.path.split('.').last;
      final fileName = '${widget.usuario.id}_$timestamp.$extension';
      final newPath = '${profilePhotosDir.path}/$fileName';

      // Copiar a imagem para o diretório da aplicação
      await File(image.path).copy(newPath);

      // Remover foto anterior se existir
      if (widget.usuario.fotoPerfil != null) {
        try {
          final oldFile = File(widget.usuario.fotoPerfil!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          print('Erro ao deletar foto anterior: $e');
        }
      }

      // Atualizar usuário com nova foto
      widget.usuario.fotoPerfil = newPath;
      widget.usuario.dataAtualizacao = DateTime.now();

      // Salvar no banco de dados
      final usuarioRepo = UsuarioRepository();
      await usuarioRepo.updateUsuario(widget.usuario);

      setState(() {
        _isUploadingPhoto = false;
      });

      if (mounted) {
        mostrarSnackBar(context, 'Foto de perfil atualizada com sucesso!');
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao atualizar foto: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualizar dados do usuário
      widget.usuario.nome = _nomeController.text.trim();
      widget.usuario.email = _emailController.text.trim().toLowerCase();
      widget.usuario.bio = _bioController.text.trim().isEmpty 
          ? null 
          : _bioController.text.trim();
      widget.usuario.dataAtualizacao = DateTime.now();

      // Salvar no banco de dados
      final usuarioRepo = UsuarioRepository();
      await usuarioRepo.updateUsuario(widget.usuario);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        mostrarSnackBar(context, 'Perfil atualizado com sucesso!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        mostrarSnackBar(context, 'Erro ao atualizar perfil: $e');
        // Reverter dados em caso de erro
        _initializeData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Perfil'),
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _isLoading ? null : () {
                setState(() {
                  _isEditing = false;
                });
                _initializeData(); // Reverter mudanças
              },
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ] else ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Editar perfil',
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar section
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: widget.usuario.fotoPerfil != null
                        ? ClipOval(
                            child: _buildProfileImage(),
                          )
                        : _buildDefaultAvatar(),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isUploadingPhoto ? null : _selectProfilePhoto,
                          icon: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.camera_alt, color: Colors.white),
                          iconSize: 20,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),

              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: "Nome completo",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  enabled: _isEditing,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Nome é obrigatório";
                  }
                  return AuthService.validateName(value);
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "E-mail",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  enabled: _isEditing,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "E-mail é obrigatório";
                  }
                  return AuthService.validateEmail(value);
                },
              ),

              const SizedBox(height: 20),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: "Bio",
                  hintText: "Conte um pouco sobre você...",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.info_outline),
                  enabled: _isEditing,
                ),
                maxLines: 3,
                maxLength: 200,
              ),

              const SizedBox(height: 30),

              // Informações da conta
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações da conta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Membro desde',
                        _formatDate(widget.usuario.dataCriacao),
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Último login',
                        widget.usuario.ultimoLogin != null
                            ? _formatDateTime(widget.usuario.ultimoLogin!)
                            : 'Nunca',
                        Icons.access_time,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Status da conta',
                        widget.usuario.ativo ? 'Ativa' : 'Inativa',
                        widget.usuario.ativo ? Icons.check_circle : Icons.cancel,
                        color: widget.usuario.ativo ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Ações
              Column(
                children: [
                  // Alterar senha
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forget-password');
                      },
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Alterar senha'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Configurações de notificação
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/notification-preferences',
                          arguments: widget.usuario,
                        );
                      },
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Configurações de notificação'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoggingOut ? null : _logout,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoggingOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(_isLoggingOut ? 'Saindo...' : 'Sair da conta'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      widget.usuario.nome.isNotEmpty 
          ? widget.usuario.nome[0].toUpperCase()
          : '?',
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileImage() {
    if (widget.usuario.fotoPerfil == null) {
      return _buildDefaultAvatar();
    }

    // Verificar se é um caminho local ou URL
    if (widget.usuario.fotoPerfil!.startsWith('http')) {
      // URL da internet
      return Image.network(
        widget.usuario.fotoPerfil!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else {
      // Arquivo local
      final file = File(widget.usuario.fotoPerfil!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            );
          } else {
            return _buildDefaultAvatar();
          }
        },
      );
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
