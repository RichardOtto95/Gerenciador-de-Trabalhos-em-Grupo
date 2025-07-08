import 'dart:io';

import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  late Connection _connection;
  bool _isConnected = false;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<bool> connect() async {
    // Lista de configurações para testar
    // final List<Map<String, dynamic>> configs = [
    //   {'sslMode': SslMode.disable, 'description': 'SSL Desabilitado'},
    //   {'sslMode': SslMode.require, 'description': 'SSL Obrigatório'},
    // ];

    // for (final config in configs) {
    try {
      // print('🔄 Tentativa: ${config['description']}');
      _connection = await Connection.open(
        Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'development',
          username: 'postgres',
          password: 'masterkey',
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
        // settings: ConnectionSettings(sslMode: config['sslMode']),
      );

      print('✅ Conectado ao banco PostgreSQL com sucesso!');
      // print('✅ Configuração utilizada: ${config['description']}');
      _isConnected = true;
      return true;
    } catch (e) {
      //   continue;
      // }
    }

    _isConnected = false;
    return false;
  }

  Future<bool> testConnection() async {
    if (!_isConnected) {
      print('❌ Não há conexão ativa com o banco');
      return false;
    }

    try {
      print('🔍 Testando conexão com query simples...');
      final result = await _connection.execute('SELECT 1 as test;');
      print('✅ Conexão testada com sucesso: ${result.first[0]}');
      return true;
    } catch (e) {
      print('❌ Erro ao testar conexão: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> createTables() async {
    if (!_isConnected) {
      print('❌ Não é possível criar tabelas - sem conexão');
      return;
    }

    try {
      print('🏗️ Criando tabelas do banco...');
      final schema = await File("assets/sql/schema.sql").readAsString();
      final commands = schema.split(";;");

      for (final command in commands) {
        if (command.trim().isNotEmpty) {
          await _connection.execute(command);
        }
      }
      print('✅ Tabelas criadas com sucesso!');
    } catch (e) {
      print('❌ Erro ao criar tabelas: $e');
    }
  }

  Future<void> mainConnection() async {
    print('🚀 Iniciando conexão principal...');

    if (!(await connect())) {
      print('❌ Falha na conexão inicial - aplicação continuará sem banco');
      return;
    }

    // Testa a conexão
    if (!(await testConnection())) {
      print('❌ Falha no teste de conexão');
      return;
    }

    // Verifica se as tabelas existem
    try {
      print('🔍 Verificando se tabelas existem...');
      await _connection.execute("SELECT * FROM NOTIFICACOES LIMIT 1");
      print('✅ Tabela NOTIFICACOES encontrada - banco já inicializado');
    } on ServerException catch (e) {
      if (e.code == "42P01") {
        print('⚠️  Tabela NOTIFICACOES não encontrada - criando estrutura...');
        await createTables();
      } else {
        print('❌ Erro inesperado ao verificar tabelas: $e');
      }
    } catch (e) {
      print('❌ Erro ao verificar tabelas: $e');
    }
  }

  Future<void> close() async {
    if (_isConnected) {
      await _connection.close();
      _isConnected = false;
      print('✅ Desconectado do banco PostgreSQL');
    }
  }

  Connection get connection => _connection;
  bool get isConnected => _isConnected;
}
