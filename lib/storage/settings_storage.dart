import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:immersion_reader/data/database/sql_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:immersion_reader/data/settings/settings_data.dart';
import 'package:immersion_reader/dictionary/dictionary_meta_entry.dart';
import 'package:immersion_reader/dictionary/user_dictionary.dart';
import 'package:immersion_reader/dictionary/pitch_data.dart';
import 'package:immersion_reader/data/settings/dictionary_setting.dart';
import 'package:immersion_reader/dictionary/dictionary_entry.dart';

class SettingsStorage {
  Database? database;
  List<DictionarySetting>? dictionarySettingCache;
  SettingsData? settingsCache;
  static const databaseName = 'data.db';

  SettingsStorage._create() {
    // print("_create() (private constructor)");
  }

  static Future<SettingsStorage> create() async {
    SettingsStorage settingsStorage = SettingsStorage._create();
    String databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, databaseName);
    debugPrint('path; $path');
    try {
      await Directory(databasesPath).create(recursive: true);
    } catch (_) {}

    // delete existing if any
    // await deleteDatabase(path);

    // copy from resources if data doesn't exist
    await File(path).exists();
    if (!File(path).existsSync()) {
      // Copy from asset
      ByteData data =
          await rootBundle.load(p.join("assets", "japanese", "data.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    // opening the database
    settingsStorage.database = await openDatabase(
      path,
      version: 1,
      onCreate: onCreateStorageData,
    );

    settingsStorage.settingsCache = await settingsStorage.getConfigSettings();
    return settingsStorage;
  }

  Future<List<DictionarySetting>> getDictionarySettings() async {
    if (database == null) {
      return [];
    }
    if (dictionarySettingCache != null) {
      return dictionarySettingCache!;
    }
    List<Map<String, Object?>> rows = await database!
        .rawQuery('SELECT * FROM Dictionary'); // to do: add limit

    List<DictionarySetting> dictionarySettingList =
        rows.map((row) => DictionarySetting.fromMap(row)).toList();
    dictionarySettingCache = dictionarySettingList;
    return dictionarySettingList;
  }

  Future<String> getDictionaryNameFromId(int dictionaryId) async {
    List<DictionarySetting> dictionarySettings = await getDictionarySettings();
    return dictionarySettings
        .firstWhere((dictionarySetting) => dictionarySetting.id == dictionaryId)
        .title;
  }

  Future<SettingsData> getConfigSettings({bool forceRefetch = false}) async {
    if (settingsCache != null && !forceRefetch) {
      return settingsCache!;
    }
    List<Map<String, Object?>> rows =
        await database!.rawQuery('SELECT * FROM Config');
    Map<String, Map<String, Object?>> configMap = {};
    for (Map<String, Object?> row in rows) {
      String categoryKey = row['category'] as String;
      if (!configMap.containsKey(categoryKey)) {
        configMap[categoryKey] = {};
      }
      configMap[categoryKey]![row['title'] as String] = row['customValue'];
    }
    try {
      settingsCache = SettingsData.fromMap(configMap);
      return settingsCache!;
    } catch (e) {
      settingsCache = await patchConfigSettings(configMap);
      return settingsCache!;
    }
  }

  // reads default config and writes missing rows into database
  Future<SettingsData> patchConfigSettings(
      Map<String, Map<String, Object?>> configMap) async {
    Batch batch = database!.batch();
    ByteData bytes = await rootBundle
        .load(p.join("assets", "settings", "defaultConfig.json"));
    String jsonStr = const Utf8Decoder().convert(bytes.buffer.asUint8List());
    Map<String, Object?> json = jsonDecode(jsonStr);
    for (MapEntry<String, Object?> categoryEntry in json.entries) {
      Map<String, Object?> map = categoryEntry.value as Map<String, Object?>;
      for (MapEntry<String, Object?> entry in map.entries) {
        if (!configMap.containsKey(categoryEntry.key) ||
            configMap[categoryEntry.key]!.containsKey(entry.key)) {
          batch.rawInsert(
              "INSERT INTO Config(title, customValue, category) VALUES(?, ?, ?)",
              [entry.key, entry.value, categoryEntry.key]);
          if (!configMap.containsKey(categoryEntry.key)) {
            configMap[categoryEntry.key] = {};
          }
          configMap[categoryEntry.key]![entry.key] = entry.value;
        }
      }
    }
    await batch.commit();
    try {
      SettingsData settingsData = SettingsData.fromMap(configMap);
      return settingsData;
    } catch (e) {
      return resetConfigSettings(json);
    }
  }

  Future<SettingsData> resetConfigSettings(Map<String, Object?> json) async {
    Map<String, Map<String, Object?>> configMap = {};
    for (MapEntry<String, Object?> categoryEntry in json.entries) {
      Map<String, Object?> map = categoryEntry.value as Map<String, Object?>;
      for (MapEntry<String, Object?> entry in map.entries) {
        if (!configMap.containsKey(categoryEntry.key)) {
          configMap[categoryEntry.key] = {};
        }
        configMap[categoryEntry.key]![entry.key] = entry.value;
      }
    }
    return SettingsData.fromMap(configMap);
  }

  Future<int> changeConfigSettings(String settingKey, String settingValue,
      {VoidCallback? onSuccessCallback}) async {
    int count = await database!.rawUpdate(
        'UPDATE Config SET customvalue = ? WHERE title = ?',
        [settingValue, settingKey]);
    if (count > 0 && onSuccessCallback != null) {
      onSuccessCallback();
    }
    return count;
  }

  Future<List<int>> getDisabledDictionaryIds() async {
    List<DictionarySetting> dictionarySettings = await getDictionarySettings();
    return List.from(dictionarySettings
        .where(
            (DictionarySetting dictionarySetting) => !dictionarySetting.enabled)
        .map((DictionarySetting dictionarySetting) => dictionarySetting.id));
  }

  Future<int> toggleDictionaryEnabled(
      DictionarySetting dictionarySetting) async {
    if (database != null) {
      int count = await database!.rawUpdate(
          'UPDATE Dictionary SET enabled = ? WHERE id = ?',
          [dictionarySetting.enabled ? 0 : 1, dictionarySetting.id]);
      if (dictionarySettingCache != null) {
        dictionarySettingCache!
            .firstWhere(
                (settingCache) => settingCache.id == dictionarySetting.id)
            .enabled = !dictionarySetting.enabled;
      }
      return count;
    }
    return 0;
  }

  Future<int> getLastRecordId() async {
    List<Map> mapData = await database!
        .rawQuery('SELECT id FROM Vocab ORDER BY id DESC LIMIT 1;');
    if (mapData.isEmpty) {
      return 0;
    } else {
      int lastRecordId = mapData.first['id'];
      return lastRecordId;
    }
  }

  Future<void> removeDictionary(int dictionaryId) async {
    Batch batch = database!.batch();
    batch.rawDelete('DELETE FROM Vocab WHERE dictionaryId = ?', [dictionaryId]);
    batch.rawDelete(
        'DELETE FROM VocabGloss WHERE dictionaryId = ?', [dictionaryId]);
    batch.rawDelete(
        'DELETE FROM VocabFreq WHERE dictionaryId = ?', [dictionaryId]);
    batch.rawDelete(
        'DELETE FROM VocabPitch WHERE dictionaryId = ?', [dictionaryId]);
    batch.rawDelete('DELETE FROM Dictionary WHERE id = ?', [dictionaryId]);
    await batch.commit();
    if (dictionarySettingCache != null) {
      dictionarySettingCache!.removeWhere(
          (dictionarySetting) => dictionarySetting.id == dictionaryId);
    }
  }

  Future<void> addDictionary(UserDictionary userDictionary) async {
    int dictionaryId = await database!
        .rawInsert('INSERT INTO Dictionary(title, enabled) VALUES(?, ?)', [
      userDictionary.dictionaryName,
      1, // enabled
    ]);
    int lastRecordId = await getLastRecordId();
    Batch batch = database!.batch();
    for (DictionaryEntry entry in userDictionary.dictionaryEntries) {
      lastRecordId += 1;
      batch.rawInsert(
          'INSERT INTO Vocab(id, dictionaryId, expression, reading, meaningTags, termTags, popularity, sequence) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
          [
            lastRecordId,
            dictionaryId,
            entry.term,
            entry.reading,
            entry.meaningTags.join(' '),
            entry.termTags.join(' '),
            entry.popularity,
            entry.sequence
          ]);
      for (String meaning in entry.meanings) {
        batch.rawInsert(
            'INSERT INTO VocabGloss(glossary, vocabId, dictionaryId) VALUES(?, ?, ?)',
            [meaning, lastRecordId, dictionaryId]);
      }
    }
    for (DictionaryMetaEntry metaEntry
        in userDictionary.dictionaryMetaEntries) {
      if (metaEntry.frequency != null) {
        batch.rawInsert(
            'INSERT INTO VocabFreq(expression, reading, frequency, dictionaryId) VALUES(?, ?, ?, ?)',
            [
              metaEntry.term,
              metaEntry.reading ?? '',
              metaEntry.frequency,
              dictionaryId
            ]);
      }
      if (metaEntry.pitches != null) {
        for (PitchData pitch in metaEntry.pitches!) {
          batch.rawInsert(
              'INSERT INTO VocabPitch(expression, reading, pitch, dictionaryId) VALUES(?, ?, ?, ?)',
              [
                metaEntry.term,
                pitch.reading,
                pitch.downstep.toString(),
                dictionaryId
              ]);
        }
      }
    }
    await batch.commit();
    if (dictionarySettingCache != null) {
      dictionarySettingCache!.add(DictionarySetting(
          id: dictionaryId,
          title: userDictionary.dictionaryName,
          enabled: true));
    }
  }
}

void onCreateStorageData(Database db, int version) async {
  Batch batch = await SqlRepository.insertTablesForDatabase(db, SettingsStorage.databaseName);
  batch = await insertDefaultSettings(batch);
  await batch.commit();
}

Future<Batch> insertDefaultSettings(Batch batch) async {
  ByteData bytes =
      await rootBundle.load(p.join("assets", "settings", "defaultConfig.json"));
  String jsonStr = const Utf8Decoder().convert(bytes.buffer.asUint8List());
  Map<String, Object?> json = jsonDecode(jsonStr);
  for (MapEntry<String, Object?> categoryEntry in json.entries) {
    Map<String, Object?> map = categoryEntry.value as Map<String, Object?>;
    for (MapEntry<String, Object?> entry in map.entries) {
      batch.rawInsert(
          "INSERT INTO Config(title, customValue, category) VALUES(?, ?, ?)",
          [entry.key, entry.value, categoryEntry.key]);
    }
  }
  return batch;
}
