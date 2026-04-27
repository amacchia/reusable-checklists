import 'dart:convert';
import 'dart:math' as math;

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

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadChecklists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAllChecklists();
      _sort(result);
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
      final topSortIndex = _checklists.isEmpty
          ? 0
          : _checklists.map((c) => c.sortIndex).reduce(math.min) - 1;
      final checklist = Checklist(
        id: _uuid.v4(),
        name: name,
        createdAt: DateTime.now(),
        sortIndex: topSortIndex,
      );
      await _repository.saveChecklist(checklist);
      _checklists = [checklist, ..._checklists];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> reorderChecklists(int oldIndex, int newIndex) async {
    _errorMessage = null;
    try {
      if (newIndex > oldIndex) newIndex--;
      final reordered = List<Checklist>.from(_checklists);
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);
      for (var i = 0; i < reordered.length; i++) {
        reordered[i].sortIndex = i;
      }
      _checklists = reordered;
      notifyListeners();
      for (final checklist in reordered) {
        await _repository.saveChecklist(checklist);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _sort(List<Checklist> list) {
    list.sort((a, b) {
      final cmp = a.sortIndex.compareTo(b.sortIndex);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });
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
      final updated = [
        checklist,
        ..._checklists.where((c) => c.id != checklist.id),
      ];
      _sort(updated);
      _checklists = updated;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String exportAsJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'checklists': _checklists.map((c) => c.toJson()).toList(),
    });
  }

  Future<int> importFromJson(String json) async {
    _errorMessage = null;
    final decoded = jsonDecode(json);
    if (decoded is! Map || decoded['checklists'] is! List) {
      throw const FormatException('Invalid checklist export format');
    }
    final parsed = (decoded['checklists'] as List)
        .map((e) => Checklist.fromJson(e as Map<String, dynamic>))
        .toList();

    final existingIds = _checklists.map((c) => c.id).toSet();
    var nextSortIndex = _checklists.isEmpty
        ? 0
        : _checklists.map((c) => c.sortIndex).reduce(math.min) - 1;

    try {
      for (final imported in parsed) {
        final toSave = existingIds.contains(imported.id)
            ? Checklist(
                id: _uuid.v4(),
                name: imported.name,
                createdAt: imported.createdAt,
                items: imported.items,
                sortIndex: nextSortIndex--,
              )
            : imported.copyWith(sortIndex: nextSortIndex--);
        await _repository.saveChecklist(toSave);
      }
      await loadChecklists();
      return parsed.length;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
