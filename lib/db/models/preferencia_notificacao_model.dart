import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import 'package:trabalho_bd/db/db_helper.dart';

/// Modelo Dart para a tabela 'preferencias_notificacao'.
class PreferenciaNotificacao {
  final String id;
  String usuarioId;
  String? grupoId; // null = configuração global
  String tipoNotificacao; // 'tarefa_atribuida', 'tarefa_vencendo', 'comentario_adicionado', etc.
  bool ativo;
  DateTime dataCriacao;
  DateTime dataAtualizacao;

  PreferenciaNotificacao({
    String? id,
    required this.usuarioId,
    this.grupoId,
    required this.tipoNotificacao,
    this.ativo = true,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now(),
       dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte uma linha do banco de dados (Map) em um objeto PreferenciaNotificacao.
  factory PreferenciaNotificacao.fromMap(Map<String, dynamic> map) {
    return PreferenciaNotificacao(
      id: map['id'],
      usuarioId: map['usuario_id'],
      grupoId: map['grupo_id'],
      tipoNotificacao: map['tipo_notificacao'],
      ativo: map['ativo'],
      dataCriacao: (map['data_criacao'] as DateTime),
      dataAtualizacao: (map['data_atualizacao'] as DateTime),
    );
  }

  /// Converte um objeto PreferenciaNotificacao em um Map para inserção/atualização no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'grupo_id': grupoId,
      'tipo_notificacao': tipoNotificacao,
      'ativo': ativo,
      'data_criacao': dataCriacao,
      'data_atualizacao': dataAtualizacao,
    };
  }

  @override
  String toString() {
    return 'PreferenciaNotificacao(id: $id, usuarioId: $usuarioId, tipoNotificacao: $tipoNotificacao, ativo: $ativo)';
  }
}

/// Repositório para operações CRUD na tabela 'preferencias_notificacao'.
class PreferenciaNotificacaoRepository {
  final Connection _connection;

  PreferenciaNotificacaoRepository() : _connection = DatabaseHelper().connection;

  /// Cria uma nova preferência de notificação no banco de dados.
  Future<void> createPreferencia(PreferenciaNotificacao preferencia) async {
    // Verifica se já existe uma preferência para o mesmo usuário, grupo e tipo
    final existente = await getPreferencia(
      preferencia.usuarioId,
      preferencia.tipoNotificacao,
      preferencia.grupoId,
    );
    
    if (existente != null) {
      // Atualiza a preferência existente
      await updatePreferencia(preferencia.copyWith(id: existente.id));
      return;
    }

    final query = '''
      INSERT INTO preferencias_notificacao (id, usuario_id, grupo_id, tipo_notificacao, ativo, data_atualizacao)
      VALUES (@id, @usuario_id, @grupo_id, @tipo_notificacao, @ativo, @data_atualizacao);
    ''';
    
    // Preparar parâmetros sem data_criacao (usa padrão do banco)
    final params = {
      'id': preferencia.id,
      'usuario_id': preferencia.usuarioId,
      'grupo_id': preferencia.grupoId,
      'tipo_notificacao': preferencia.tipoNotificacao,
      'ativo': preferencia.ativo,
      'data_atualizacao': preferencia.dataAtualizacao,
    };
    
    await _connection.execute(Sql.named(query), parameters: params);
    print('Preferência de notificação criada para o usuário ${preferencia.usuarioId}.');
  }

  /// Retorna todas as preferências de notificação de um usuário.
  Future<List<PreferenciaNotificacao>> getPreferenciasByUsuario(String usuarioId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM preferencias_notificacao WHERE usuario_id = @usuario_id ORDER BY tipo_notificacao;'),
      parameters: {'usuario_id': usuarioId},
    );
    return result
        .map(
          (row) => PreferenciaNotificacao.fromMap({
            'id': row[0],
            'usuario_id': row[1],
            'grupo_id': row[2],
            'tipo_notificacao': row[3],
            'ativo': row[4],
            'data_criacao': row[5],
            'data_atualizacao': row[6],
          }),
        )
        .toList();
  }

  /// Retorna uma preferência específica.
  Future<PreferenciaNotificacao?> getPreferencia(
    String usuarioId,
    String tipoNotificacao,
    String? grupoId,
  ) async {
    final result = await _connection.execute(
      Sql.named('''
        SELECT * FROM preferencias_notificacao 
        WHERE usuario_id = @usuario_id 
          AND tipo_notificacao = @tipo_notificacao 
          AND (grupo_id = @grupo_id OR (grupo_id IS NULL AND @grupo_id IS NULL));
      '''),
      parameters: {
        'usuario_id': usuarioId,
        'tipo_notificacao': tipoNotificacao,
        'grupo_id': grupoId,
      },
    );
    
    if (result.isNotEmpty) {
      final row = result.first;
      return PreferenciaNotificacao.fromMap({
        'id': row[0],
        'usuario_id': row[1],
        'grupo_id': row[2],
        'tipo_notificacao': row[3],
        'ativo': row[4],
        'data_criacao': row[5],
        'data_atualizacao': row[6],
      });
    }
    return null;
  }

  /// Atualiza uma preferência de notificação existente.
  Future<void> updatePreferencia(PreferenciaNotificacao preferencia) async {
    final query = '''
      UPDATE preferencias_notificacao
      SET usuario_id = @usuario_id, grupo_id = @grupo_id, tipo_notificacao = @tipo_notificacao, 
          ativo = @ativo, data_atualizacao = @data_atualizacao
      WHERE id = @id;
    ''';
    
    // Preparar parâmetros sem data_criacao (não deve ser alterada)
    final params = {
      'id': preferencia.id,
      'usuario_id': preferencia.usuarioId,
      'grupo_id': preferencia.grupoId,
      'tipo_notificacao': preferencia.tipoNotificacao,
      'ativo': preferencia.ativo,
      'data_atualizacao': preferencia.dataAtualizacao,
    };
    
    await _connection.execute(Sql.named(query), parameters: params);
    print('Preferência de notificação com ID ${preferencia.id} atualizada.');
  }

  /// Deleta uma preferência de notificação pelo seu ID.
  Future<void> deletePreferencia(String id) async {
    await _connection.execute(
      Sql.named('DELETE FROM preferencias_notificacao WHERE id = @id;'),
      parameters: {'id': id},
    );
    print('Preferência de notificação com ID $id deletada.');
  }

  /// Verifica se o usuário deve receber notificação para um tipo específico.
  Future<bool> shouldNotify(String usuarioId, String tipoNotificacao, String? grupoId) async {
    // Primeiro verifica se existe configuração específica para o grupo
    if (grupoId != null) {
      final preferenciaGrupo = await getPreferencia(usuarioId, tipoNotificacao, grupoId);
      if (preferenciaGrupo != null) {
        return preferenciaGrupo.ativo;
      }
    }
    
    // Se não tem configuração específica, verifica a configuração global
    final preferenciaGlobal = await getPreferencia(usuarioId, tipoNotificacao, null);
    if (preferenciaGlobal != null) {
      return preferenciaGlobal.ativo;
    }
    
    // Se não tem configuração, por padrão é true
    return true;
  }

  /// Configura preferências padrão para um usuário novo.
  Future<void> criarPreferenciasDefault(String usuarioId) async {
    final tiposNotificacao = [
      'tarefa_atribuida',
      'tarefa_vencendo',
      'comentario_adicionado',
      'tarefa_completada',
      'convite_grupo',
    ];

    for (final tipo in tiposNotificacao) {
      final preferencia = PreferenciaNotificacao(
        usuarioId: usuarioId,
        tipoNotificacao: tipo,
        ativo: true,
      );
      await createPreferencia(preferencia);
    }
  }
}

/// Extensão para criar cópias do objeto.
extension PreferenciaNotificacaoExtension on PreferenciaNotificacao {
  PreferenciaNotificacao copyWith({
    String? id,
    String? usuarioId,
    String? grupoId,
    String? tipoNotificacao,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return PreferenciaNotificacao(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      grupoId: grupoId ?? this.grupoId,
      tipoNotificacao: tipoNotificacao ?? this.tipoNotificacao,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
} 