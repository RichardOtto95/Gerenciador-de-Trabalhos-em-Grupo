import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  late Connection _connection;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<void> connect() async {
    _connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'user',
        password: 'pass',
      ),
    );

    print('Connected to PostgreSQL database.');
  }

  Future<void> close() async {
    await _connection.close();
    print('Disconnected from PostgreSQL database.');
  }

  Connection get connection => _connection;
}
