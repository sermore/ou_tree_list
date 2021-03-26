import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

abstract class TreeNode {
  final String id;
  final String? parentId;
  final int level;
  final bool selected;
  final bool expanded;

  TreeNode({this.parentId, String? id, this.level = 0, this.selected = false, this.expanded = true})
      : id = id ?? Uuid().v4();

  dynamic copy({String parentId, String id, int level, bool selected, bool expanded});

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

  List<E> _nodes;
  List<E> _visibleNodes;
  E? _root;
  bool _isLoading;
  bool _editable;
  final E Function({E parent, int level}) create;

  TreeListModel(this.create, [this._nodes = const [], this._root])
      : _isLoading = false,
        _editable = false,
        _visibleNodes = _buildVisibleNodes(_nodes, _root);

  UnmodifiableListView<E> get nodes => UnmodifiableListView(_visibleNodes);

  set nodes(List<E> __nodes) {
    _isLoading = true;
    _nodes = __nodes;
    if (root != null) {
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
    _isLoading = true;
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

  void _updateVisibleNodes() {
    _visibleNodes = _buildVisibleNodes(_nodes, _root);
    _isLoading = false;
    notifyListeners();
  }

  void updateNode(E node) {
    int replaceIndex = -1;
    var oldNode = _nodes.firstWhereIndexedOrNull((idx, it) {
      replaceIndex = idx;
      return it.id == node.id;
    });
    _nodes[replaceIndex] = node;
    if (_root == oldNode) {
      _root = node;
    }
    _updateVisibleNodes();
    // _uploadItems();
  }

  void deleteNode(E node) {
    int i = _nodes.indexOf(node);
    print('delete $node');
    _nodes.removeAt(i);
    // remove node's children
    while (i < _nodes.length && _nodes[i].level > node.level) {
      print('delete ${_nodes[i]}');
      _nodes.removeAt(i);
    }
    if (_root == node) {
      _root = null;
    }
    _updateVisibleNodes();
    // _uploadItems();
  }

  E addNode(E? parent) {
    E newNode;
    int parentIndex = -1;
    if (parent == null) {
      newNode = create();
      _nodes.insert(0, newNode);
    } else {
      newNode = create(
        parent: parent,
        level: parent.level + 1,
      );
      parentIndex = _nodes.indexOf(parent);
      _nodes.insert(parentIndex + 1, newNode);
    }
    // expand parent if closed, in order to show the child just created
    if (parent != null && !parent.expanded) {
      _nodes[parentIndex] = parent.copy(expanded: true) as E;
      if (_root == parent) {
        _root = _nodes[parentIndex];
      }
    }
    _updateVisibleNodes();
    // _uploadItems();
    return newNode;
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

  Tuple3<E, E, bool> moveSubTree(int oldIndex, int newIndex) {
    final source = _visibleNodes[oldIndex];
    int start = _nodes.indexOf(source);
    final target = _visibleNodes[newIndex];
    final targetIndex = _nodes.indexOf(target);
    int end = start + 1;
    while (end < _nodes.length && _nodes[end].level > source.level) {
      end++;
    }
    // trying to drop a parent into its subtree
    if (targetIndex >= start && targetIndex <= end) {
      return Tuple3<E, E, bool>(source, target, false);
    }
    // extract source sub-tree and recalculate its levels in order to match target's level
    final subList =
        _nodes.sublist(start, end).map((el) => el.copy(level: target.level + 1 + el.level - source.level) as E);
    _nodes.removeRange(start, end);
    _nodes.insertAll(targetIndex < start ? targetIndex + 1 : targetIndex + 1 - (end - start), subList);
    _updateVisibleNodes();
    return Tuple3<E, E, bool>(source, target, true);
  }

  void selectAll(bool selected) {
    _nodes = _nodes.map((ou) => ou.copy(selected: selected) as E).toList();
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
  Future<List<E>> load();
  Future<bool> add(E node);
  Future update(E node);
  Future<bool> deleteTree(E rootNode);
}

class RestRepository<E> extends Repository<E> {
  final
  @override
  Future<List<E>> load() async {
    final response = await http.get

  }
}
