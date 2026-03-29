import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:reusable_checklists/data/models/checklist.dart';
import 'package:reusable_checklists/data/models/checklist_item.dart';
import 'package:reusable_checklists/data/repositories/hive_checklist_repository.dart';
import 'package:reusable_checklists/hive_registrar.g.dart';

void main() {
  late Directory tempDir;
  late Box<Checklist> box;
  late HiveChecklistRepository repository;

  setUpAll(() {
    Hive.registerAdapters();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Checklist>('checklists');
    repository = HiveChecklistRepository(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveChecklistRepository', () {
    test('getAllChecklists returns empty list initially', () async {
      final result = await repository.getAllChecklists();
      expect(result, isEmpty);
    });

    test('saveChecklist stores and retrieves a checklist', () async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );
      await repository.saveChecklist(checklist);

      final result = await repository.getAllChecklists();
      expect(result.length, 1);
      expect(result.first.name, 'Groceries');
    });

    test('saveChecklist updates existing checklist', () async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );
      await repository.saveChecklist(checklist);

      checklist.name = 'Updated Groceries';
      await repository.saveChecklist(checklist);

      final result = await repository.getAllChecklists();
      expect(result.length, 1);
      expect(result.first.name, 'Updated Groceries');
    });

    test('deleteChecklist removes checklist', () async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );
      await repository.saveChecklist(checklist);
      await repository.deleteChecklist('1');

      final result = await repository.getAllChecklists();
      expect(result, isEmpty);
    });

    test('deleteChecklist with non-existent id does nothing', () async {
      await repository.deleteChecklist('non-existent');
      final result = await repository.getAllChecklists();
      expect(result, isEmpty);
    });

    test('getChecklistById returns checklist when found', () async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
      );
      await repository.saveChecklist(checklist);

      final result = await repository.getChecklistById('1');
      expect(result, isNotNull);
      expect(result!.name, 'Groceries');
    });

    test('getChecklistById returns null when not found', () async {
      final result = await repository.getChecklistById('non-existent');
      expect(result, isNull);
    });

    test('persists checklist with items', () async {
      final checklist = Checklist(
        id: '1',
        name: 'Groceries',
        createdAt: DateTime(2024),
        items: [
          ChecklistItem(id: 'a', title: 'Milk', sortIndex: 0),
          ChecklistItem(
            id: 'b',
            title: 'Eggs',
            sortIndex: 1,
            isChecked: true,
          ),
        ],
      );
      await repository.saveChecklist(checklist);

      final result = await repository.getChecklistById('1');
      expect(result!.items.length, 2);
      expect(result.items[1].isChecked, true);
      expect(result.items[0].title, 'Milk');
    });
  });
}
