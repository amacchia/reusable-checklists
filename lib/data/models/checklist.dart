import 'package:hive_ce/hive.dart';

import 'checklist_item.dart';

part 'checklist.g.dart';

@HiveType(typeId: 0)
class Checklist {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  List<ChecklistItem> items;

  Checklist({
    required this.id,
    required this.name,
    required this.createdAt,
    List<ChecklistItem>? items,
  }) : items = items ?? [];

  int get checkedCount => items.where((i) => i.isChecked).length;

  bool get isAllChecked => items.isNotEmpty && checkedCount == items.length;

  Checklist copyWith({
    String? name,
    List<ChecklistItem>? items,
  }) {
    return Checklist(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      items: items ?? List.of(this.items),
    );
  }
}
