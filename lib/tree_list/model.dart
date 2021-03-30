import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

abstract class TreeNode {
  final String id;
  final String? parentId;
  final int level;
  final bool selected;
  final bool expanded;

  TreeNode({this.parentId, String? id, this.level = 0, this.selected = false, this.expanded = true})
      : id = id ?? Uuid().v4();

  dynamic copy({bool parentIdNull = false, String? parentId, String id, int level, bool selected, bool expanded});

  @override
  int get hashCode => parentId.hashCode ^ id.hashCode ^ level.hashCode ^ selected.hashCode ^ expanded.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeNode &&
          runtimeType == other.runtimeType &&
          parentId == other.parentId &&
          id == other.id &&
          level == other.level &&
          selected == other.selected &&
          expanded == other.expanded;

  @override
  String toString() {
    return 'id: $id, parentId: $parentId, level: $level, selected: $selected, expanded: $expanded';
  }
}

class TreeListModel<E extends TreeNode> extends ChangeNotifier {

  static List<E> _buildVisibleNodes<E extends TreeNode>(List<E> nodes, E? root) {
    List<E> result = [];
    Queue<E> parentStack = ListQueue();
    // find root node position
    int start = root != null ? nodes.indexOf(root) + 1 : 0;
    int i;
    // start iterating the list beginning from the item next to the root
    for (i = start; i < nodes.length && (root != null ? nodes[i].level > root.level : true); i++) {
      E current = nodes[i];
      // discard all items on top of parent's stack for which there is no possible childrens, identifying the parent owning current item
      while (parentStack.isNotEmpty && parentStack.first.id != current.parentId) {
        parentStack.removeFirst();
      }
      if (parentStack.isEmpty || parentStack.first.expanded) {
        // if parent node is expanded, add the current item to result and add it to the top of the parent's stack
        result.add(current);
        parentStack.addFirst(current);
      } else {
        // parent node is not expanded, skip all current node's children
        while (i + 1 < nodes.length && nodes[i + 1].level > current.level) {
          i++;
        }
      }
    }
    print('rebuild visibileNodes start=$start, end=$i, length=${result.length}, root=$root');
    return result;
  }

  final Repository<E> repository;
  List<E> _nodes;
  List<E> _visibleNodes;
  E? _root;
  bool _isLoading;
  bool _editable;
  bool _forceReload;
  final E Function({E parent, int level}) create;

  TreeListModel(this.create, this.repository, {bool forceReload = false})
      : _isLoading = false,
        _editable = false,
        _forceReload = forceReload,
        _nodes = [],
        _root = null,
        _visibleNodes = [] {
    // repository.load().then((value) => this.nodes = value);
  }

  UnmodifiableListView<E> get nodes => UnmodifiableListView(_visibleNodes);

  set nodes(List<E> __nodes) {
    _nodes = __nodes;
    if (_root != null) {
      _root = __nodes.firstWhereOrNull((n) => n.id == _root!.id);
    }
    _updateVisibleNodes();
  }

  bool get isLoading => _isLoading;

  set isLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  E? get root => _root;

  set root(E? root) {
    print('set root $root');
    _root = root;
    _updateVisibleNodes();
    notifyListeners();
  }

  bool get editable => _editable;

  set editable(bool editable) {
    _editable = editable;
    notifyListeners();
  }

  int get totalLength => _nodes.length;

  void _reload() {
    print('reload');
    repository.load().then((list) => nodes = list);
  }

  void _updateVisibleNodes() {
    _visibleNodes = _buildVisibleNodes(_nodes, _root);
    _isLoading = false;
    notifyListeners();
  }

  Future<E> updateNode(E node) {
    print('update node $node');
    _isLoading = true;
    notifyListeners();
    return repository.update(node).then((updatedNode) {
      print('updatedNode $updatedNode');
      int replaceIndex = -1;
      var oldNode = _nodes.firstWhereIndexedOrNull((idx, it) {
        replaceIndex = idx;
        return it.id == node.id;
      });
      _nodes[replaceIndex] = updatedNode;
      if (_root == oldNode) {
        _root = updatedNode;
      }
      _updateVisibleNodes();
      return updatedNode;
    });
  }

  Future deleteNode(E node) {
    print('delete $node');
    _isLoading = true;
    return repository.deleteTree(node).then((res) {
      print('deleted $node');
      if (_forceReload) {
        _reload();
      } else {
        int i = _nodes.indexOf(node);
        _nodes.removeAt(i);
        // remove node's children
        while (i < _nodes.length && _nodes[i].level > node.level) {
          print('delete child ${_nodes[i]}');
          _nodes.removeAt(i);
        }
        if (_root == node) {
          _root = null;
        }
        _updateVisibleNodes();
      }
    });
  }

  Future<E> addNode(E? parent) {
    _isLoading = true;
    E newNode = parent == null ? create() : create(parent: parent, level: parent.level + 1);
    print('add node $newNode');
    return repository.add(newNode).then((node) {
      print('new node $node');
      if (_forceReload) {
        _reload();
      } else {
        int parentIndex = -1;
        if (parent == null) {
          _nodes.insert(0, node);
        } else {
          parentIndex = _nodes.indexOf(parent);
          _nodes.insert(parentIndex + 1, node);
        }
        // expand parent if closed, in order to show the child just created
        if (parent != null && !parent.expanded) {
          _nodes[parentIndex] = parent.copy(expanded: true) as E;
          if (_root == parent) {
            _root = _nodes[parentIndex];
          }
        }
        _updateVisibleNodes();
      }
      return node;
    });
  }

  Future<Tuple3<E, E?, bool>> moveSubTree(int oldIndex, int newIndex) {
    print('moveSubTree $oldIndex => $newIndex');
    final source = _visibleNodes[oldIndex];
    int sourceIndex = _nodes.indexOf(source);
    // newIndex = 0 means before the first item, i.e. child of current root or at root level
    final target = newIndex == 0 ? _root : _visibleNodes[newIndex-1];

    final targetIndex = target == null ? -1 : _nodes.indexOf(target);
    int end = sourceIndex + 1;
    while (end < _nodes.length && _nodes[end].level > source.level) {
      end++;
    }
    // trying to drop a parent into its subtree
    if (targetIndex >= sourceIndex && targetIndex < end) {
      print('reject, trying to move an item into its own subtree');
      return Future.value(Tuple3<E, E?, bool>(source, target, false));
    }
    final newSource = source.copy(parentId: target?.id, parentIdNull: target == null);
    return repository.update(newSource).then((node) {
      print('moveSubTree $oldIndex[${source.id}] as child of $newIndex[${target?.id}] => update $node');
      if (_forceReload) {
        _reload();
      } else {
        _nodes[sourceIndex] = node;
        if(_root == source) {
          _root = node;
        }
        // extract source sub-tree and recalculate its levels in order to match target's level
        final subList =
        _nodes.sublist(sourceIndex, end).map((el) => el.copy(level: (target == null ? 0 : target.level + 1) + el.level - source.level) as E);
        _nodes.removeRange(sourceIndex, end);
        _nodes.insertAll(targetIndex < sourceIndex ? targetIndex + 1 : targetIndex + 1 - (end - sourceIndex), subList);
        _updateVisibleNodes();
      }
      return Tuple3<E, E?, bool>(node, target, true);
    });
  }

  E? findNodeById(String id) {
    return _nodes.firstWhereOrNull((it) => it.id == id);
  }

  int subTreeLength(E rootNode) {
    int start = _nodes.indexOf(rootNode) + 1;
    int end = start;
    while (end < _nodes.length && _nodes[end].level > rootNode.level) {
      end++;
    }
    return end - start;
  }

  void selectAll(bool selected) {
    _nodes = _nodes.map((ou) => ou.copy(selected: selected) as E).toList();
    _updateVisibleNodes();
  }

  void toggleExpandNode(node) {
    final i = _nodes.indexOf(node);
    final newNode = node.copy(expanded: !node.expanded);
    _nodes[i] = newNode;
    _updateVisibleNodes();
  }

  void toggleExpansion() {
    if (_root != null) {
      _toggleSubTreeExpansion(_root!);
    } else {
      _toggleExpansion();
    }
    _updateVisibleNodes();
  }

  void _toggleExpansion() {
    bool expand = _nodes.length / 2 > _nodes.where((node) => node.expanded).length;
    _nodes = _nodes.map((node) => node.copy(expanded: expand) as E).toList();
  }

  void _toggleSubTreeExpansion(E rootNode) {
    int start = _nodes.indexOf(rootNode) + 1;
    int end = start;
    while (end < _nodes.length && _nodes[end].level > rootNode.level) {
      end++;
    }
    List<E> list = _nodes.sublist(start, end);
    bool expand = list.length / 2 > list.where((element) => element.expanded).length;
    _nodes.replaceRange(start, end, list.map((ou) => ou.copy(expanded: expand) as E).toList());
  }

  deleteSelected() {
    E? node;
    do {
      node = _nodes.firstWhereOrNull((n) => n.selected);
      if (node != null) {
        deleteNode(node);
      }
    } while (node != null);
    _updateVisibleNodes();
  }

  @override
  int get hashCode => _root.hashCode ^ _nodes.hashCode ^ _isLoading.hashCode ^ _editable.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeListModel &&
          runtimeType == other.runtimeType &&
          _root == other._root &&
          _nodes == other._nodes &&
          _isLoading == other._isLoading &&
          _editable == other._editable;

  @override
  String toString() {
    return 'TreeListModel{root: $_root, nodes: $_nodes, isLoading: $_isLoading, visibleNodes: $_visibleNodes, editable: $_editable}';
  }
}

abstract class Repository<E extends TreeNode> {
  final Function(Object e, Object stackTrace) onError;

  Repository(this.onError);

  Future<List<E>> load();
  Future<E> add(E node);
  Future<E> update(E node);
  Future deleteTree(E rootNode);
}

class SimpleRepository<E extends TreeNode> extends Repository<E> {

  final List<E> Function() generate;

  SimpleRepository(this.generate, {onError}) : super(onError);

  @override
  Future<E> add(E node) {
    print('repo: add node=$node');
    return Future.value(node).catchError(onError);
  }

  @override
  Future deleteTree(E rootNode) {
    print('repo: deleteTree root=$rootNode');
    return Future.value();
  }

  @override
  Future<List<E>> load() {
    return Future.delayed(Duration(seconds: 2) , () => generate());
  }

  @override
  Future<E> update(E node) {
    return Future.value(node);
  }

}

class RestRepository<E extends TreeNode> extends Repository<E> {
  final String uri;
  final E Function(Map<String, dynamic> json) fromJson;

  RestRepository(this.uri, this.fromJson, onError) : super(onError);

  @override
  Future<List<E>> load() async {
    var response = await http.get(Uri.http(uri, '/api/ou/1/descendants')).catchError(onError);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      List<E> nodes = List<E>.from(l.map((json) => fromJson(json)));
      return nodes;
    }
    return [];
  }

  @override
  Future<E> add(E node) {
    return http.post(
      Uri.http(uri, '/api/ou/1/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(node),
    ).then((response) => fromJson(jsonDecode(response.body))).catchError(onError);
  }

  @override
  Future deleteTree(E node) {
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
    return http.put(
      Uri.http(uri, '/api/ou/1/${node.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(node),
    ).then((response) => fromJson(jsonDecode(response.body))).catchError(onError);
  }
}
