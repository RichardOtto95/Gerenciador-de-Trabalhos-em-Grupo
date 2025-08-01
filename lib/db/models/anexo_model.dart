import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'anexos'.
class Anexo {
  final String id;
  String tarefaId; // Chave estrangeira para tarefas(id)
  String usuarioId; // Chave estrangeira para usuarios(id)
  String nomeOriginal;
  String nomeArquivo; // Nome no sistema de arquivos
  String tipoMime; // Tipo MIME do arquivo
  int tamanhoBytes; // BIGINT no SQL, mapeado para int em Dart
  String caminhoArquivo; // URL ou caminho do arquivo
  DateTime dataUpload;

  Anexo({
    String? id,
    required this.tarefaId,
    required this.usuarioId,
    required this.nomeOriginal,
    required this.nomeArquivo,
    required this.tipoMime,
    required this.tamanhoBytes,
    required this.caminhoArquivo,
    DateTime? dataUpload,
  }) : id = id ?? const Uuid().v4(),
       dataUpload = dataUpload ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto Anexo.
  factory Anexo.fromMap(Map<String, dynamic> map) {
    return Anexo(
      id: map['id'],
      tarefaId: map['tarefa_id'],
      usuarioId: map['usuario_id'],
      nomeOriginal: map['nome_original'],
      nomeArquivo: map['nome_arquivo'],
      tipoMime: map['tipo_mime'],
      tamanhoBytes: map['tamanho_bytes'],
      caminhoArquivo: map['caminho_arquivo'],
      dataUpload: (map['data_upload'] as DateTime),
    );
  }

  /// Converte um objeto Anexo em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarefa_id': tarefaId,
      'usuario_id': usuarioId,
      'nome_original': nomeOriginal,
      'nome_arquivo': nomeArquivo,
      'tipo_mime': tipoMime,
      'tamanho_bytes': tamanhoBytes,
      'caminho_arquivo': caminhoArquivo,
      'data_upload': dataUpload,
    };
  }

  @override
  String toString() {
    return 'Anexo(id: $id, tarefaId: $tarefaId, nomeOriginal: $nomeOriginal, tipoMime: $tipoMime)';
  }
}

/// Repositório para operações CRUD na tabela 'anexos'.
class AnexoRepository {
  final Connection _connection;

  AnexoRepository() : _connection = DatabaseHelper().connection;

  /// Cria um novo anexo no banco de dados.
  Future<void> createAnexo(Anexo anexo) async {
    final query = '''
      INSERT INTO anexos (id, tarefa_id, usuario_id, nome_original, nome_arquivo, tipo_mime, tamanho_bytes, caminho_arquivo, data_upload)
      VALUES (@id, @tarefa_id, @usuario_id, @nome_original, @nome_arquivo, @tipo_mime, @tamanho_bytes, @caminho_arquivo, @data_upload);
    ''';
    await _connection.execute(Sql.named(query), parameters: anexo.toMap());
    print(
      'Anexo "${anexo.nomeOriginal}" criado para a tarefa ${anexo.tarefaId}.',
    );
  }

  /// Retorna todos os anexos de uma tarefa específica.
  Future<List<Anexo>> getAnexosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM anexos WHERE tarefa_id = @tarefa_id;'),
      parameters: {'tarefa_id': tarefaId},
    );
    return result
        .map(
          (row) => Anexo.fromMap({
            'id': row[0],
            'tarefa_id': row[1],
            'usuario_id': row[2],
            'nome_original': row[3],
            'nome_arquivo': row[4],
            'tipo_mime': row[5],
            'tamanho_bytes': row[6],
            'caminho_arquivo': row[7],
            'data_upload': row[8],
          }),
        )
        .toList();
  }

  /// Retorna um anexo pelo seu ID.
  Future<Anexo?> getAnexoById(String id) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM anexos WHERE id = @id;'),
      parameters: {'id': id},
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return Anexo.fromMap({
        'id': row[0],
        'tarefa_id': row[1],
        'usuario_id': row[2],
        'nome_original': row[3],
        'nome_arquivo': row[4],
        'tipo_mime': row[5],
        'tamanho_bytes': row[6],
        'caminho_arquivo': row[7],
        'data_upload': row[8],
      });
    }
    return null;
  }

  /// Atualiza as informações de um anexo existente.
  /// Note: Geralmente, anexos são deletados e recriados em vez de atualizados,
  /// mas esta função pode ser usada para atualizar metadados.
  Future<void> updateAnexo(Anexo anexo) async {
    final query = '''
      UPDATE anexos
      SET nome_original = @nome_original, nome_arquivo = @nome_arquivo, 
          tipo_mime = @tipo_mime, tamanho_bytes = @tamanho_bytes, caminho_arquivo = @caminho_arquivo
      WHERE id = @id;
    ''';
    await _connection.execute(Sql.named(query), parameters: anexo.toMap());
    print('Anexo com ID ${anexo.id} atualizado.');
  }

  /// Deleta um anexo pelo seu ID.
  Future<void> deleteAnexo(String id) async {
    await _connection.execute(
      Sql.named('DELETE FROM anexos WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Anexo com ID $id deletado.');
  }

  /// Retorna o total de anexos de uma tarefa.
  Future<int> getCountAnexosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      Sql.named('SELECT COUNT(*) FROM anexos WHERE tarefa_id = @tarefa_id;'),
      parameters: {'tarefa_id': tarefaId},
    );
    return result.first[0] as int;
  }

  /// Verifica se um usuário pode remover um anexo (apenas autor ou admin).
  Future<bool> podeUsuarioRemoverAnexo(String anexoId, String usuarioId) async {
    final anexo = await getAnexoById(anexoId);
    if (anexo == null) return false;
    
    // Autor pode sempre remover
    if (anexo.usuarioId == usuarioId) return true;
    
    // TODO: Implementar verificação de admin quando tiver controle de papéis
    // Por enquanto, apenas o autor pode remover
    return false;
  }

  /// Retorna o tamanho total dos anexos de uma tarefa em bytes.
  Future<int> getTamanhoTotalAnexosByTarefa(String tarefaId) async {
    final result = await _connection.execute(
      Sql.named('SELECT COALESCE(SUM(tamanho_bytes), 0) FROM anexos WHERE tarefa_id = @tarefa_id;'),
      parameters: {'tarefa_id': tarefaId},
    );
    return result.first[0] as int;
  }

  /// Retorna anexos de uma tarefa com informações do usuário que fez upload.
  Future<List<Map<String, dynamic>>> getAnexosComUsuarioByTarefa(String tarefaId) async {
    final query = '''
      SELECT 
        a.id, a.tarefa_id, a.usuario_id, a.nome_original, a.nome_arquivo,
        a.tipo_mime, a.tamanho_bytes, a.caminho_arquivo, a.data_upload,
        u.nome as usuario_nome, u.email as usuario_email
      FROM anexos a 
      JOIN usuarios u ON a.usuario_id = u.id 
      WHERE a.tarefa_id = @tarefa_id 
      ORDER BY a.data_upload DESC;
    ''';
    
    final result = await _connection.execute(
      Sql.named(query),
      parameters: {'tarefa_id': tarefaId},
    );
    
    return result.map((row) => {
      'anexo': Anexo.fromMap({
        'id': row[0],
        'tarefa_id': row[1],
        'usuario_id': row[2],
        'nome_original': row[3],
        'nome_arquivo': row[4],
        'tipo_mime': row[5],
        'tamanho_bytes': row[6],
        'caminho_arquivo': row[7],
        'data_upload': row[8],
      }),
      'usuario_nome': row[9],
      'usuario_email': row[10],
    }).toList();
  }
}
