import 'package:hive_ce/hive.dart';

part 'checklist_item.g.dart';

@HiveType(typeId: 1)
class ChecklistItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isChecked;

  @HiveField(3)
  int sortIndex;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isChecked = false,
    required this.sortIndex,
  });

  ChecklistItem copyWith({
    String? title,
    bool? isChecked,
    int? sortIndex,
  }) {
    return ChecklistItem(
      id: id,
      title: title ?? this.title,
      isChecked: isChecked ?? this.isChecked,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isChecked': isChecked,
        'sortIndex': sortIndex,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        title: json['title'] as String,
        isChecked: json['isChecked'] as bool? ?? false,
        sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
      );
}
