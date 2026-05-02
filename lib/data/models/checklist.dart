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

  @HiveField(4)
  int sortIndex;

  Checklist({
    required this.id,
    required this.name,
    required this.createdAt,
    List<ChecklistItem>? items,
    this.sortIndex = 0,
  }) : items = items ?? [];

  int get checkedCount => items.where((i) => i.isChecked).length;

  bool get isAllChecked => items.isNotEmpty && checkedCount == items.length;

  Checklist copyWith({
    String? name,
    List<ChecklistItem>? items,
    int? sortIndex,
  }) {
    return Checklist(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      items: items ?? List.of(this.items),
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'sortIndex': sortIndex,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Checklist.fromJson(Map<String, dynamic> json) => Checklist(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List?)
            ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
