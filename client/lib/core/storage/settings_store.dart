import 'package:sembast/sembast.dart';

class SettingsStore {
  SettingsStore(this._db);
  final Database _db;
  final _store = StoreRef<String, String>('settings');

  Future<String?> read(String key) => _store.record(key).get(_db);
  Future<void> write(String key, String value) => _store.record(key).put(_db, value);
}
