import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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
        id: Uuid().v4(),
        parentId: parentStack.isNotEmpty ? parentStack.first.id : null,
        name: 'o[$i],' +
            (parentStack.isNotEmpty ? parentStack.first.name.split(',').last : '') +
            ' ' +
            generateWordPairs().take(1).join(' '),
        level: parentStack.length);
    list.add(ou);
    parentStack.addFirst(ou);
  }
  return list;
}

class OrgUnit with TreeNode {
  final String? parentId;
  final String id;
  final int level;
  final bool selected;
  final bool expanded;
  final String name;
  final bool active;

  OrgUnit(
      {this.parentId,
      String? id,
      this.name = '',
      this.active = true,
      this.level = 0,
      this.selected = false,
      this.expanded = true})
      : id = id ?? Uuid().v4();

  static OrgUnit fromJson(Map<String, dynamic> json) {
    return OrgUnit(
      parentId: json['parentId'],
      id: json['id'],
      name: json['name'],
      active: json['active'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() => {'parentId': parentId, 'id': id, 'level': level, 'name': name, 'active': active};

  @override
  OrgUnit copy(
      {bool parentIdNull = false,
        String? parentId,
        String? id,
        int? level,
        bool? selected,
        bool? expanded,
        String? name,
        bool? active}) {
    return OrgUnit(
        parentId: parentIdNull ? null : parentId ?? this.parentId,
        id: id ?? this.id,
        name: name ?? this.name,
        active: active ?? this.active,
        level: level ?? this.level,
        selected: selected ?? this.selected,
        expanded: expanded ?? this.expanded);
  }

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
}

class RestRepository<E extends TreeNode> implements Repository<E> {
  final String uri;
  final E Function(Map<String, dynamic> json) fromJson;
  final Function(Object e, Object stackTrace) onError;

  RestRepository({required this.uri, required this.fromJson, required this.onError});

  @override
  Future<List<E>> load() async {
    print('load from server');
    var response = await http.get(Uri.http(uri, '/api/ou/1/descendants')).catchError(onError);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      List<E> nodes = List<E>.from(l.map((json) => fromJson(json)));
      return nodes;
    }
    print('error loading data');
    return [];
  }

  @override
  Future<E> add(E node) {
    return http
        .post(
          Uri.http(uri, '/api/ou/1/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(node),
        )
        .then((response) => fromJson(jsonDecode(response.body)))
        .catchError(onError);
  }

  @override
  Future<void> deleteSubTree(E node) {
    print('delete node $node');
    return http.delete(
      Uri.http(uri, '/api/ou/1/${node.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ).then((response) {
      print('deleted node $node');
      return response.statusCode == 200;
    }).catchError(onError);
  }

  @override
  Future<E> update(E node) {
    return http
        .put(
          Uri.http(uri, '/api/ou/1/${node.id}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(node),
        )
        .then((response) => fromJson(jsonDecode(response.body)))
        .catchError(onError);
  }
}
