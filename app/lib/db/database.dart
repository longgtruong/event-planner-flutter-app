import 'package:app/models/ContactUser.dart';
import 'package:app/models/Party.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:contacts_service/contacts_service.dart';

class EventDatabase {
  static final EventDatabase instance = EventDatabase._init();

  static Database? _db;

  EventDatabase._init();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB('events.db');
    return _db!;
  }

  Future<Database> _initDB(String file) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, file);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const _id = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const _title = 'TEXT NOT NULL';
    const _description = 'TEXT';
    const _startDate = 'DATETIME NOT NULL';
    const _endDate = 'DATETIME';
    const _userName = 'TEXT NOT NULL';
    const _userEmail = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE events (
        id $_id,
        title $_title,
        description $_description,
        start_date $_startDate,
        end_date $_endDate
      )
      ''');
    await db.execute('''
      INSERT INTO events(title, description, start_date, end_date) VALUES ("Birthday party #1", "Test event party description", "2022-01-20", "2022-02-03");
    ''');
    await db.execute('''
      CREATE TABLE event_users (
        id $_id,
        email $_userEmail,
        name $_userName,
        event_id INTEGER,
        FOREIGN KEY (event_id) REFERENCES events (id)
      )
    ''');
    await db.execute('''
      INSERT INTO event_users(email, name, event_id) VALUES ("449360@student.saxion.nl","Long", 1);
    ''');
  }

  Future<int> create(Party party) async {
    final db = await instance.db;
    final id = await db.insert('events', party.toJson());
    return id;
  }

  deleteEvent(int id) async {
    final db = await instance.db;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ContactUser>> getUsersOfEvents(int eventId) async {
    final db = await instance.db;
    final result = await db
        .query('event_users', where: 'event_id = ?', whereArgs: [eventId]);
    return result.map((e) => ContactUser.parseJson(e)).toList();
  }

  addUserToParty(Contact contact, int id) async {
    final db = await instance.db;
    ContactUser user = ContactUser.userFromContact(contact);
    await db.insert('event_users', ContactUser.toJson(user, id));
  }

  removeUserFromEvent(int userId, int eventId) async {
    final db = await instance.db;
    await db.delete('event_users',
        where: 'id = ? and event_id = ?', whereArgs: [userId, eventId]);
  }

  updateEvent(Party party, int id) async {
    final db = await instance.db;
    db.update('events', party.toJson(), where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Party>> getAllEvents() async {
    final db = await instance.db;
    final results = await db.query('events', orderBy: 'start_date ASC');
    return results.map((json) => Party.parseJson(json)).toList();
  }
}
