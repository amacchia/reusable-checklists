import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/checklist.dart';
import '../data/models/checklist_item.dart';
import '../data/repositories/checklist_repository.dart';

class ChecklistDetailViewModel extends ChangeNotifier {
  final ChecklistRepository _repository;
  final Uuid _uuid;

  ChecklistDetailViewModel(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  Checklist? _checklist;
  String? _errorMessage;

  Checklist? get checklist => _checklist;
  String? get errorMessage => _errorMessage;

  List<ChecklistItem> get sortedItems {
    if (_checklist == null) return [];
    final items = List<ChecklistItem>.from(_checklist!.items);
    items.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return items;
  }

  List<ChecklistItem> get uncheckedItems =>
      sortedItems.where((i) => !i.isChecked).toList();

  List<ChecklistItem> get checkedItems =>
      sortedItems.where((i) => i.isChecked).toList();

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadChecklist(String id) async {
    _errorMessage = null;
    try {
      _checklist = await _repository.getChecklistById(id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> renameChecklist(String newName) async {
    if (_checklist == null) return;
    _errorMessage = null;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == _checklist!.name) return;
    try {
      _checklist!.name = trimmed;
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> editItem(String itemId, String newTitle) async {
    if (_checklist == null) return;
    _errorMessage = null;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    try {
      final item = _checklist!.items.firstWhere((i) => i.id == itemId);
      if (item.title == trimmed) return;
      item.title = trimmed;
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addItem(String title) async {
    if (_checklist == null) return;
    _errorMessage = null;
    try {
      final item = ChecklistItem(
        id: _uuid.v4(),
        title: title,
        sortIndex: _checklist!.items.length,
      );
      _checklist!.items.add(item);
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_checklist == null) return;
    _errorMessage = null;
    try {
      _checklist!.items.removeWhere((i) => i.id == itemId);
      _reindexItems();
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleItem(String itemId) async {
    if (_checklist == null) return;
    _errorMessage = null;
    try {
      final item = _checklist!.items.firstWhere((i) => i.id == itemId);
      item.isChecked = !item.isChecked;
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkAll() async {
    if (_checklist == null) return;
    _errorMessage = null;
    try {
      for (final item in _checklist!.items) {
        item.isChecked = true;
      }
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> uncheckAll() async {
    if (_checklist == null) return;
    _errorMessage = null;
    try {
      for (final item in _checklist!.items) {
        item.isChecked = false;
      }
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (_checklist == null) return;
    _errorMessage = null;
    try {
      final unchecked = uncheckedItems;
      final checked = checkedItems;
      if (newIndex > oldIndex) newIndex--;
      final movedItem = unchecked.removeAt(oldIndex);
      unchecked.insert(newIndex, movedItem);
      final combined = [...unchecked, ...checked];
      for (var i = 0; i < combined.length; i++) {
        combined[i].sortIndex = i;
      }
      _checklist!.items = combined;
      await _repository.saveChecklist(_checklist!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _reindexItems() {
    final items = sortedItems;
    for (var i = 0; i < items.length; i++) {
      items[i].sortIndex = i;
    }
    _checklist!.items = items;
  }
}
