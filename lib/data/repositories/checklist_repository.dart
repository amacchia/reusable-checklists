import '../models/checklist.dart';

abstract interface class ChecklistRepository {
  Future<List<Checklist>> getAllChecklists();
  Future<void> saveChecklist(Checklist checklist);
  Future<void> deleteChecklist(String id);
  Future<Checklist?> getChecklistById(String id);
}
