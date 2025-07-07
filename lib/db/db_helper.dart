import 'dart:io';

import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  late Connection _connection;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<bool> connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'trabalho_em_grupo_bd',
          username: 'appuser',
          password: 'masterkey',
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );

      print('Connected to PostgreSQL database.');
    } on PgException catch (e) {
      print(e);
      if (e.message ==
          "Socket error: FormatException: Missing extension byte (at offset 40)") {
        print("Banco não encontrado");
        return false;
      }
    }
    return true;
  }

  Future<void> createTables() async {
    final schema = await File("assets/sql/schema.sql").readAsString();

    final commands = schema.split(";;");

    for (final command in commands) {
      await _connection.execute(command);
    }
  }

  Future<void> mainConnection() async {
    if (!(await connect())) return;
    try {
      await _connection.execute("SELECT * FROM NOTIFICACOES LIMIT 1");
    } on ServerException catch (e) {
      if (e.code == "42P01") {
        createTables();
      }
    }
  }

  Future<void> close() async {
    await _connection.close();
    print('Disconnected from PostgreSQL database.');
  }

  Connection get connection => _connection;
}
