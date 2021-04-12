import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'model.dart';

class TreeListView<E extends TreeNode> extends StatelessWidget {

  TreeListView({
    Key? key,
    this.onReorder,
    this.dismissibleTile = true,
    required this.listTileBuilder,
  }) : super(key: key);

  final void Function(BuildContext context, E source, E? target, bool result)? onReorder;
  final bool dismissibleTile;
  final TreeListTileBuilder<E> Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)
  listTileBuilder;

  void _onReorder(BuildContext context, int oldIndex, int newIndex) {
    Provider.of<TreeListModel<E>>(context, listen: false)
        .moveSubTree(oldIndex, newIndex)
        .then((res) => onReorder?.call(context, res.item1, res.item2, res.item3));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TreeListModel<E>>(builder: (context, model, _) {
      if (model.isLoading) {
        return Stack(children: [
          Center(
            child: CircularProgressIndicator(
              key: const Key('__TreeListLoading__'),
            ),
          ),
          buildTreeList(context, model)
        ]);
      } else {
        return buildTreeList(context, model);
      }
    });
  }

  Widget buildTreeList(BuildContext context, TreeListModel<E> model) {
    if (model.editable) {
      return buildReorderableListView(context, model);
    } else {
      return buildListView(model);
    }
  }

  ListView buildListView(TreeListModel<E> model) {
    return ListView.builder(
      key: const Key('__TreeList__'),
      // padding: EdgeInsets.all(8.0),
      itemCount: model.nodes.length,
      itemBuilder: (context, index) => listTileBuilder(context, model, model.nodes[index], model.root?.level ?? 0).build(),
    );
  }

  ReorderableListView buildReorderableListView(BuildContext context, TreeListModel<E> model) {
    return ReorderableListView.builder(
        key: const Key('__EditableTreeList__'),
        // padding: EdgeInsets.all(8.0),
        onReorder: (oldIndex, newIndex) => _onReorder(context, oldIndex, newIndex),
        itemCount: model.nodes.length,
        itemBuilder: (context, index) {
          final node = model.nodes[index];
          final treeListTileBuilder = listTileBuilder(context, model, node, model.root?.level ?? 0);
          // print(node);
          if (dismissibleTile) {
            return Dismissible(
              key: Key('__ModNodeItem__${node.id}__'),
              onDismissed: (_) => treeListTileBuilder._onRemove(),
              child: treeListTileBuilder.build(),
            );
          } else {
            return treeListTileBuilder.build();
          }
        });
  }

}

abstract class TreeListTileBuilder<E extends TreeNode> {
  TreeListTileBuilder(this.context, this.model, this.node, this.rootLevel);

  final BuildContext context;
  final TreeListModel<E> model;
  final E node;
  final int rootLevel;

  double get levelPadding => 24;

  bool get isThreeLine => false;

  bool? get dense => null;

  VisualDensity? get visualDensity => null;

  ShapeBorder? get shape => null;

  bool get enabled => true;

  // GestureLongPressCallback? onLongPress;
  MouseCursor? get mouseCursor => null;

  bool get selected => false;

  /// The color for the tile's [Material] when it has the input focus.
  Color? get focusColor => null;

  /// {@macro flutter.material.ListTile.hoverColor}
  Color? get hoverColor => null;

  /// {@macro flutter.widgets.Focus.focusNode}
  FocusNode? get focusNode => null;

  /// {@macro flutter.widgets.Focus.autofocus}
  bool get autofocus => false;

  /// {@macro flutter.material.ListTile.tileColor}
  Color? get tileColor => null;

  /// {@macro flutter.material.ListTile.selectedTileColor}
  Color? get selectedTileColor => null;

  bool? get enableFeedback => null;

  double? get horizontalTitleGap => null;

  double? get minVerticalPadding => null;

  double? get minLeadingWidth => null;

  void onRemove() {}

  void onAdd(E newNode) {}

  void onTap() {}

  void _onAdd() {
    print('onAdd parent=$node');
    Provider.of<TreeListModel<E>>(context, listen: false).addNode(node).then((newNode) => onAdd(newNode));
  }

  void _onRemove() {
    print('onRemove $node');
    Provider.of<TreeListModel<E>>(context, listen: false).deleteSubTree(node).then((value) => onRemove());
  }

  /// {@macro flutter.material.ListTile.title}
  Widget title();

  Widget? subtitle() => null;

  /// {@macro flutter.material.ListTile.leading}
  Widget leading() {
    return IconButton(
      icon: Icon(node.expanded ? Icons.indeterminate_check_box_outlined : Icons.add_box_outlined),
      onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
    );
  }

  EdgeInsets contentPadding() => EdgeInsets.only(left: (node.level - rootLevel) * levelPadding);

  Widget? trailing() {
    return model.editable
        ? Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
      IconButton(icon: const Icon(Icons.add), onPressed: _onAdd),
      IconButton(icon: const Icon(Icons.delete), onPressed: _onRemove),
      if (kIsWeb) Padding(padding: EdgeInsets.only(left: 40.0))
    ])
        : null;
  }

  Widget build() {
    return ListTile(
      key: Key('__TreeNode_${node.id}__'),
      onTap: onTap,
      title: title(),
      subtitle: subtitle(),
      leading: leading(),
      trailing: trailing(),
      contentPadding: contentPadding(),
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      enabled: enabled,
      mouseCursor: mouseCursor,
      selected: selected,
      focusColor: focusColor,
      hoverColor: hoverColor,
      focusNode: focusNode,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
    );
  }
}
