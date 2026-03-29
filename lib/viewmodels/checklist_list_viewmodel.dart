import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/checklist.dart';
import '../data/repositories/checklist_repository.dart';

class ChecklistListViewModel extends ChangeNotifier {
  final ChecklistRepository _repository;
  final Uuid _uuid;

  ChecklistListViewModel(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  List<Checklist> _checklists = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Checklist> get checklists => List.unmodifiable(_checklists);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadChecklists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAllChecklists();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _checklists = result;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createChecklist(String name) async {
    _errorMessage = null;
    try {
      final checklist = Checklist(
        id: _uuid.v4(),
        name: name,
        createdAt: DateTime.now(),
      );
      await _repository.saveChecklist(checklist);
      _checklists = [checklist, ..._checklists];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteChecklist(String id) async {
    _errorMessage = null;
    try {
      await _repository.deleteChecklist(id);
      _checklists = _checklists.where((c) => c.id != id).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveChecklist(Checklist checklist) async {
    _errorMessage = null;
    try {
      await _repository.saveChecklist(checklist);
      _checklists = [checklist, ..._checklists.where((c) => c.id != checklist.id)];
      _checklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
