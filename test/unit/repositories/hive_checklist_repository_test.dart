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

    test('reopens box and deserializes persisted checklist with items',
        () async {
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

      // Close and reopen the box to force deserialization via the
      // generated TypeAdapter.read methods.
      await box.close();
      box = await Hive.openBox<Checklist>('checklists');
      repository = HiveChecklistRepository(box);

      final result = await repository.getChecklistById('1');
      expect(result, isNotNull);
      expect(result!.name, 'Groceries');
      expect(result.createdAt, DateTime(2024));
      expect(result.items.length, 2);
      expect(result.items[0].title, 'Milk');
      expect(result.items[0].isChecked, false);
      expect(result.items[0].sortIndex, 0);
      expect(result.items[1].title, 'Eggs');
      expect(result.items[1].isChecked, true);
      expect(result.items[1].sortIndex, 1);
    });

    test('ChecklistAdapter equality and hashCode', () {
      final a = ChecklistAdapter();
      final b = ChecklistAdapter();

      expect(a == a, isTrue);
      expect(a == b, isTrue);
      // ignore: unrelated_type_equality_checks
      expect(a == 'not an adapter', isFalse);
      expect(a.hashCode, b.hashCode);
    });

    test('ChecklistItemAdapter equality and hashCode', () {
      final a = ChecklistItemAdapter();
      final b = ChecklistItemAdapter();

      expect(a == a, isTrue);
      expect(a == b, isTrue);
      // ignore: unrelated_type_equality_checks
      expect(a == 'not an adapter', isFalse);
      expect(a.hashCode, b.hashCode);
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
