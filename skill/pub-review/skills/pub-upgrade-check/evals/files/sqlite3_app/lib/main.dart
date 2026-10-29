import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.openInMemory();
  db.execute('CREATE TABLE notes (body TEXT)');
  db.execute('INSERT INTO notes (body) VALUES (?)', ['hello']);
  print(db.select('SELECT body FROM notes').first['body']);
  db.close();
}
