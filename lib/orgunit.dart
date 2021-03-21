import 'dart:collection';
import 'dart:math';

import 'package:english_words/english_words.dart';

import 'tree_list/model.dart';

List<OrgUnit> generate(int len) {
  Random random = Random();
  List<OrgUnit> list = [];
  Queue<OrgUnit> parentStack = ListQueue();
  for (int i = 0; i < len; i++) {
    // choose the parent to which the next item will be added
    while (parentStack.isNotEmpty && random.nextBool()) {
      parentStack.removeFirst();
    }
    OrgUnit ou = OrgUnit(
        parentId: parentStack.isNotEmpty ? parentStack.first.id : null,
        name: 'o[$i],' + (parentStack.isNotEmpty ? parentStack.first.name.split(',').last : '') + ' ' + generateWordPairs().take(1).join(' '),
        level: parentStack.length);
    list.add(ou);
    parentStack.addFirst(ou);
  }
  return list;
}

/// Loads remote data
///
/// Call this initially and when the user manually refreshes
Future<void> load(TreeListModel<OrgUnit> model) {
  model.isLoading = true;
  model.nodes = generate(120);
  return Future.delayed(Duration(seconds: 2), () {
    model.isLoading = false;
    print('initialized');
  });
}

class OrgUnit extends TreeNode {
  String name;
  bool active;

  OrgUnit(
      {String? parentId,
      String? id,
      this.name = '',
      this.active = true,
      int level = 0,
      bool selected = false,
      bool expanded = true})
      : super(parentId: parentId, id: id, level: level, selected: selected, expanded: expanded);

  @override
  int get hashCode => super.hashCode ^ name.hashCode ^ active.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgUnit &&
          runtimeType == other.runtimeType &&
          super == other &&
          name == other.name &&
          active == other.active;

  @override
  String toString() {
    return 'OrgUnit{${super.toString()}, name: $name, active: $active}';
  }

  OrgUnitEntity toEntity() {
    return OrgUnitEntity(parentId, id, name, active, level);
  }

  static OrgUnit fromEntity(OrgUnitEntity entity) {
    return OrgUnit(
        parentId: entity.parentId, id: entity.id, name: entity.name, active: entity.active, level: entity.level);
  }

  @override
  OrgUnit copy({String? parentId, String? id, int? level, bool? selected, bool? expanded, String? name, bool? active}) {
    return OrgUnit(
      parentId: parentId ?? this.parentId,
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      level: level ?? this.level,
      selected: selected ?? this.selected,
      expanded: expanded ?? this.expanded
    );
  }

  // OrgUnit copy({String parentId, String id, int level, bool selected, bool expanded, String name, bool active}) {
  //   return OrgUnit(
  //       parentId: parentId ?? this.parentId,
  //       id: id ?? this.id,
  //       // name: name ?? this.name,
  //       // active: active ?? this.active,
  //       level: level ?? this.level,
  //       selected: selected ?? this.selected,
  //       expanded: expanded ?? this.expanded
  //   );
  // }

}

class OrgUnitEntity {
  final String? parentId;
  final String id;
  final String name;
  final bool active;
  final int level;

  OrgUnitEntity(this.parentId, this.id, this.name, this.active, this.level);

  @override
  int get hashCode => parentId.hashCode ^ name.hashCode ^ id.hashCode ^ active.hashCode ^ level.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgUnitEntity &&
          runtimeType == other.runtimeType &&
          parentId == other.parentId &&
          name == other.name &&
          active == other.active &&
          id == other.id &&
          level == other.level;

  Map<String, Object?> toJson() {
    return {'parentId': parentId, 'id': id, 'name': name, 'active': active, 'level': level};
  }

  @override
  String toString() {
    return 'OrgUnitEntity{id: $id, parentId: $parentId, name: $name, active: $active, level: $level}';
  }

  static OrgUnitEntity fromJson(Map<String, Object> json) {
    return OrgUnitEntity(json['parentId'] as String, json['id'] as String, json['name'] as String,
        json['active'] as bool, json['level'] as int);
  }
}
