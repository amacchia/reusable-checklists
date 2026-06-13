import 'package:flutter/foundation.dart';

class SelectionNotifier extends ChangeNotifier {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  bool get isSelectionMode => _isSelectionMode;

  bool isSelected(String id) => _selectedIds.contains(id);

  void enterSelectionMode() {
    if (_isSelectionMode) return;
    _isSelectionMode = true;
    notifyListeners();
  }

  void startSelection(String id) {
    _selectedIds
      ..clear()
      ..add(id);
    _isSelectionMode = true;
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    _isSelectionMode = _selectedIds.isNotEmpty;
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }
}
