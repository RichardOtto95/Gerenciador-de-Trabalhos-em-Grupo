import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:trabalho_bd/db/models/anexo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';

class FileAttachmentWidget extends StatefulWidget {
  final String tarefaId;
  final Usuario currentUser;
  final VoidCallback? onAttachmentChanged;

  const FileAttachmentWidget({
    super.key,
    required this.tarefaId,
    required this.currentUser,
    this.onAttachmentChanged,
  });

  @override
  State<FileAttachmentWidget> createState() => _FileAttachmentWidgetState();
}

class _FileAttachmentWidgetState extends State<FileAttachmentWidget> {
  List<Map<String, dynamic>> _anexos = [];
  bool _isLoading = true;
  bool _isUploading = false;

  // Configurações de upload
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const List<String> allowedExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'rtf', 'odt', 'ods', 'odp',
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg',
    'mp4', 'avi', 'mov', 'wmv', 'flv',
    'mp3', 'wav', 'aac', 'flac',
    'zip', 'rar', '7z', 'tar', 'gz'
  ];

  @override
  void initState() {
    super.initState();
    _loadAnexos();
  }

  Future<void> _loadAnexos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final anexoRepo = AnexoRepository();
      final anexos = await anexoRepo.getAnexosComUsuarioByTarefa(widget.tarefaId);

      setState(() {
        _anexos = anexos;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar anexos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      print('🔍 Iniciando seleção de arquivos...');
      print('🖥️ Plataforma: ${defaultTargetPlatform}');
      
      // Configurações específicas para desktop
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb, // Usar bytes apenas na web
        withReadStream: false,
        allowedExtensions: null, // Permitir todos os tipos inicialmente
      );

      print('📁 Resultado da seleção: ${result?.files.length ?? 0} arquivos');

      if (result == null || result.files.isEmpty) {
        print('❌ Nenhum arquivo selecionado');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      List<String> errors = [];
      int successCount = 0;

      for (final file in result.files) {
        try {
          print('📄 Processando arquivo: ${file.name}');
          
          // Validações
          if (file.size > maxFileSize) {
            errors.add('${file.name}: Arquivo muito grande (máx. 50MB)');
            continue;
          }

          final extension = file.extension?.toLowerCase();
          if (extension != null && !allowedExtensions.contains(extension)) {
            errors.add('${file.name}: Tipo de arquivo não permitido');
            continue;
          }

          // No desktop, verificar se temos o path
          if (file.path == null) {
            errors.add('${file.name}: Caminho do arquivo não disponível');
            continue;
          }

          // Upload do arquivo
          await _uploadFile(file);
          successCount++;
          print('✅ Arquivo ${file.name} enviado com sucesso');
        } catch (e) {
          print('❌ Erro no upload do arquivo ${file.name}: $e');
          errors.add('${file.name}: Erro no upload - $e');
        }
      }

      setState(() {
        _isUploading = false;
      });

      // Recarregar lista
      await _loadAnexos();

      // Callback de alteração
      widget.onAttachmentChanged?.call();

      // Feedback para o usuário
      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount arquivo(s) enviado(s) com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Erros no Upload'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors.map((error) => Text('• $error')).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro geral na seleção de arquivos: $e');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar arquivos: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    try {
      print('📤 Iniciando upload do arquivo: ${file.name}');
      
      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${directory.path}/attachments');
      
      // Criar diretório se não existir
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
        print('📁 Diretório de anexos criado: ${attachmentsDir.path}');
      }

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? '';
      final uniqueFileName = '${timestamp}_${widget.tarefaId}_${file.name}';
      final destinationPath = '${attachmentsDir.path}/$uniqueFileName';

      // Copiar arquivo usando o path (desktop) ou bytes (web/mobile)
      final sourceFile = File(file.path!);
      final destinationFile = File(destinationPath);
      
      if (await sourceFile.exists()) {
        // No desktop, copiamos o arquivo do path original
        await sourceFile.copy(destinationPath);
        print('✅ Arquivo copiado para: $destinationPath');
      } else {
        throw Exception('Arquivo fonte não encontrado: ${file.path}');
      }

      // Verificar o tamanho real do arquivo copiado
      final copiedFileSize = await destinationFile.length();
      print('📊 Tamanho do arquivo copiado: $copiedFileSize bytes');

      // Detectar tipo MIME
      final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
      print('🏷️ Tipo MIME detectado: $mimeType');

      // Criar registro no banco
      final anexo = Anexo(
        tarefaId: widget.tarefaId,
        usuarioId: widget.currentUser.id,
        nomeOriginal: file.name,
        nomeArquivo: uniqueFileName,
        tipoMime: mimeType,
        tamanhoBytes: copiedFileSize, // Usar tamanho real do arquivo copiado
        caminhoArquivo: destinationPath,
      );

      final anexoRepo = AnexoRepository();
      await anexoRepo.createAnexo(anexo);
      print('💾 Anexo salvo no banco de dados');
      
    } catch (e) {
      print('❌ Erro no upload: $e');
      rethrow;
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> anexoData) async {
    try {
      final anexo = anexoData['anexo'] as Anexo;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Baixando arquivo...'),
            ],
          ),
        ),
      );

      // Verificar se arquivo existe
      final file = File(anexo.caminhoArquivo);
      if (!await file.exists()) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arquivo não encontrado no sistema'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Obter diretório de downloads do usuário
      Directory downloadsDir;
      try {
        // No macOS, tentar diretório padrão de Downloads do usuário
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null && Platform.isMacOS) {
          downloadsDir = Directory('$homeDir/Downloads');
          print('📁 Usando Downloads do usuário: ${downloadsDir.path}');
        } else {
          throw Exception('Diretório HOME não encontrado');
        }
      } catch (e) {
        print('⚠️ Erro ao acessar Downloads do usuário: $e');
        // Fallback para diretório de documentos da aplicação
        final documentsDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${documentsDir.path}/Downloads');
        print('📁 Usando fallback: ${downloadsDir.path}');
      }

      // Garantir que o diretório existe
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
        print('📁 Diretório criado: ${downloadsDir.path}');
      }

      // Gerar nome único para evitar conflitos
      String finalFileName = anexo.nomeOriginal;
      String downloadPath = '${downloadsDir.path}/$finalFileName';
      int counter = 1;
      
      // Se arquivo já existe, gerar nome único
      while (await File(downloadPath).exists()) {
        final extension = anexo.nomeOriginal.contains('.') 
            ? anexo.nomeOriginal.substring(anexo.nomeOriginal.lastIndexOf('.'))
            : '';
        final nameWithoutExt = anexo.nomeOriginal.contains('.') 
            ? anexo.nomeOriginal.substring(0, anexo.nomeOriginal.lastIndexOf('.'))
            : anexo.nomeOriginal;
        
        finalFileName = '${nameWithoutExt}_($counter)$extension';
        downloadPath = '${downloadsDir.path}/$finalFileName';
        counter++;
      }

      print('📥 Copiando arquivo para: $downloadPath');
      
      // Copiar arquivo para downloads
      await file.copy(downloadPath);
      
      // Verificar se arquivo foi copiado
      final downloadedFile = File(downloadPath);
      if (await downloadedFile.exists()) {
        final fileSize = await downloadedFile.length();
        print('✅ Arquivo baixado com sucesso! Tamanho: $fileSize bytes');
      } else {
        throw Exception('Arquivo não foi copiado corretamente');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo baixado: $finalFileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Abrir pasta',
              onPressed: () {
                _openFileLocation(downloadsDir.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao baixar arquivo: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFileLocation(String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Erro ao abrir pasta: $e');
    }
  }

  Future<void> _removeFile(Map<String, dynamic> anexoData) async {
    final anexo = anexoData['anexo'] as Anexo;

    // Verificar permissões
    final anexoRepo = AnexoRepository();
    final podeRemover = await anexoRepo.podeUsuarioRemoverAnexo(
      anexo.id,
      widget.currentUser.id,
    );

    if (!podeRemover) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você não tem permissão para remover este anexo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover Anexo'),
        content: Text('Tem certeza que deseja remover "${anexo.nomeOriginal}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // Remover do banco
      await anexoRepo.deleteAnexo(anexo.id);

      // Remover arquivo físico
      final file = File(anexo.caminhoArquivo);
      if (await file.exists()) {
        await file.delete();
      }

      // Recarregar lista
      await _loadAnexos();

      // Callback de alteração
      widget.onAttachmentChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anexo removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover anexo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icon(Icons.image, color: Colors.blue);
    } else if (mimeType.startsWith('video/')) {
      return Icon(Icons.videocam, color: Colors.red);
    } else if (mimeType.startsWith('audio/')) {
      return Icon(Icons.audiotrack, color: Colors.purple);
    } else if (mimeType.contains('pdf')) {
      return Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icon(Icons.description, color: Colors.blue);
    } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icon(Icons.table_chart, color: Colors.green);
    } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icon(Icons.slideshow, color: Colors.orange);
    } else if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('7z')) {
      return Icon(Icons.archive, color: Colors.brown);
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/"
        "${dateTime.month.toString().padLeft(2, '0')}/"
        "${dateTime.year} às "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão de upload
        Row(
          children: [
                         ElevatedButton.icon(
               onPressed: _isUploading ? null : () async {
                 print('🔥 Botão Anexar Arquivos clicado!');
                 
                 // Debug: Testar se o FilePicker está funcionando
                 try {
                   print('🧪 Testando FilePicker...');
                   print('🧪 Plataforma detectada: ${defaultTargetPlatform}');
                   
                   // Configuração mais específica para macOS
                   final testResult = await FilePicker.platform.pickFiles(
                     type: FileType.custom,
                     allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'gif'],
                     dialogTitle: 'Selecionar Arquivo para Anexar',
                   );
                   
                   print('🧪 Resultado do teste: ${testResult != null ? 'Sucesso' : 'Cancelado'}');
                   
                   if (testResult != null && testResult.files.isNotEmpty) {
                     final file = testResult.files.first;
                     print('🧪 Arquivo selecionado: ${file.name}');
                     print('🧪 Path: ${file.path}');
                     print('🧪 Size: ${file.size}');
                     
                     // Processar o arquivo
                     setState(() {
                       _isUploading = true;
                     });
                     
                     try {
                       await _uploadFile(file);
                       await _loadAnexos();
                       widget.onAttachmentChanged?.call();
                       
                       if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Arquivo "${file.name}" enviado com sucesso!'),
                             backgroundColor: Colors.green,
                           ),
                         );
                       }
                     } catch (e) {
                       print('❌ Erro no upload: $e');
                       if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Erro no upload: $e'),
                             backgroundColor: Colors.red,
                           ),
                         );
                       }
                     } finally {
                       setState(() {
                         _isUploading = false;
                       });
                     }
                   }
                 } catch (e) {
                   print('❌ Erro no FilePicker: $e');
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Erro ao abrir seletor de arquivos: $e'),
                         backgroundColor: Colors.red,
                       ),
                     );
                   }
                 }
               },
               icon: _isUploading 
                 ? SizedBox(
                     width: 16,
                     height: 16,
                     child: CircularProgressIndicator(strokeWidth: 2),
                   )
                 : Icon(Icons.attach_file),
               label: Text(_isUploading ? 'Enviando...' : 'Anexar Arquivos'),
               style: ElevatedButton.styleFrom(
                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               ),
             ),
            if (_anexos.isNotEmpty) ...[
              SizedBox(width: 16),
              Text(
                '${_anexos.length} arquivo(s)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 16),

        // Lista de anexos
        if (_anexos.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                SizedBox(height: 12),
                Text(
                  "Nenhum anexo adicionado",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Clique em 'Anexar Arquivos' para adicionar documentos",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _anexos.length,
            itemBuilder: (context, index) {
              final anexoData = _anexos[index];
              final anexo = anexoData['anexo'] as Anexo;
              final usuarioNome = anexoData['usuario_nome'] as String;

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _buildFileIcon(anexo.tipoMime),
                  title: Text(
                    anexo.nomeOriginal,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enviado por $usuarioNome',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${_formatFileSize(anexo.tamanhoBytes)} • ${_formatDateTime(anexo.dataUpload)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () => _downloadFile(anexoData),
                        tooltip: 'Baixar arquivo',
                      ),
                      if (anexo.usuarioId == widget.currentUser.id)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFile(anexoData),
                          tooltip: 'Remover arquivo',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
} 