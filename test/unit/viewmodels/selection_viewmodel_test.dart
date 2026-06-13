import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/viewmodels/selection_viewmodel.dart';

void main() {
  group('SelectionNotifier', () {
    late SelectionNotifier selection;

    setUp(() {
      selection = SelectionNotifier();
    });

    tearDown(() {
      selection.dispose();
    });

    test('starts with no selection and not in selection mode', () {
      expect(selection.isSelectionMode, false);
      expect(selection.selectedIds, isEmpty);
      expect(selection.isSelected('any'), false);
    });

    test('enterSelectionMode enables selection mode without selecting', () {
      selection.enterSelectionMode();
      expect(selection.isSelectionMode, true);
      expect(selection.selectedIds, isEmpty);
    });

    test('enterSelectionMode is idempotent', () {
      selection.enterSelectionMode();
      selection.enterSelectionMode();
      expect(selection.isSelectionMode, true);
      expect(selection.selectedIds, isEmpty);
    });

    test('startSelection selects an item and enters selection mode', () {
      selection.startSelection('id1');
      expect(selection.isSelectionMode, true);
      expect(selection.isSelected('id1'), true);
      expect(selection.selectedIds, {'id1'});
    });

    test('startSelection clears previous selection', () {
      selection.startSelection('id1');
      selection.startSelection('id2');
      expect(selection.isSelected('id2'), true);
      expect(selection.isSelected('id1'), false);
      expect(selection.selectedIds, {'id2'});
    });

    test('toggleSelection adds an item when not selected', () {
      selection.enterSelectionMode();
      selection.toggleSelection('id1');
      expect(selection.isSelected('id1'), true);
      expect(selection.selectedIds, {'id1'});
    });

    test('toggleSelection removes an item when already selected', () {
      selection.startSelection('id1');
      selection.toggleSelection('id1');
      expect(selection.isSelected('id1'), false);
      expect(selection.isSelectionMode, false);
    });

    test('toggleSelection exits selection mode when last item removed', () {
      selection.startSelection('id1');
      selection.toggleSelection('id1');
      expect(selection.isSelectionMode, false);
      expect(selection.selectedIds, isEmpty);
    });

    test('toggleSelection stays in selection mode with remaining items', () {
      selection.startSelection('id1');
      selection.toggleSelection('id2');
      selection.toggleSelection('id1');
      expect(selection.isSelectionMode, true);
      expect(selection.selectedIds, {'id2'});
    });

    test('clearSelection resets everything', () {
      selection.startSelection('id1');
      selection.toggleSelection('id2');
      selection.clearSelection();
      expect(selection.isSelectionMode, false);
      expect(selection.selectedIds, isEmpty);
    });

    test('clearSelection is safe when already empty', () {
      selection.clearSelection();
      expect(selection.isSelectionMode, false);
      expect(selection.selectedIds, isEmpty);
    });

    test('selectedIds returns unmodifiable set', () {
      selection.startSelection('id1');
      final ids = selection.selectedIds;
      expect(() => ids.add('id2'), throwsUnsupportedError);
    });

    test('notifies listeners on enterSelectionMode', () {
      var notifyCount = 0;
      selection.addListener(() => notifyCount++);
      selection.enterSelectionMode();
      expect(notifyCount, 1);
    });

    test('notifies listeners on startSelection', () {
      var notifyCount = 0;
      selection.addListener(() => notifyCount++);
      selection.startSelection('id1');
      expect(notifyCount, 1);
    });

    test('notifies listeners on toggleSelection', () {
      var notifyCount = 0;
      selection.addListener(() => notifyCount++);
      selection.startSelection('id1');
      selection.toggleSelection('id2');
      expect(notifyCount, 2);
    });

    test('notifies listeners on clearSelection', () {
      var notifyCount = 0;
      selection.addListener(() => notifyCount++);
      selection.startSelection('id1');
      selection.clearSelection();
      expect(notifyCount, 2);
    });
  });
}
