import 'package:hive_ce/hive.dart';

import '../models/checklist.dart';
import 'checklist_repository.dart';

class HiveChecklistRepository implements ChecklistRepository {
  final Box<Checklist> _box;

  HiveChecklistRepository(this._box);

  @override
  Future<List<Checklist>> getAllChecklists() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveChecklist(Checklist checklist) async {
    await _box.put(checklist.id, checklist);
  }

  @override
  Future<void> deleteChecklist(String id) async {
    await _box.delete(id);
  }

  @override
  Future<Checklist?> getChecklistById(String id) async {
    return _box.get(id);
  }
}
