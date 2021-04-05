import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';

abstract class TreeListTile<E extends TreeNode> extends StatelessWidget {
  final E node;
  final int rootLevel;
  final double levelPadding;
  final IconData nodeExpandedIcon;
  final IconData nodeCollapsedIcon;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final void Function(BuildContext context, E node)? onRemove;
  final void Function(BuildContext context, E parent, E node)? onAdd;

  TreeListTile({this.title, this.subtitle, this.leading,
      this.levelPadding = 10.0,
      this.nodeExpandedIcon = Icons.arrow_drop_down,
      this.nodeCollapsedIcon = Icons.arrow_right,
      this.onRemove,
      this.onAdd,
      required this.node,
      required this.rootLevel}) : super(
  );

  Widget buildTitle(BuildContext context, TreeListModel<E> model);

  Widget buildSubtitle(BuildContext context, TreeListModel<E> model);

  Widget buildLeading(BuildContext context, TreeListModel<E> model) {
    if (model.editable) {
      return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        IconButton(
          icon: Icon(node.expanded ? nodeExpandedIcon : nodeCollapsedIcon),
          onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
        ),
        Container(padding: EdgeInsets.symmetric(horizontal: (node.level - rootLevel) * levelPadding)),
      ]);
    } else {
      return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        IconButton(
          icon: Icon(node.expanded ? nodeExpandedIcon : nodeCollapsedIcon),
          onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: () => _onAdd(context, node)),
        IconButton(icon: const Icon(Icons.delete), onPressed: () => _onRemove(context, node)),
        Container(padding: EdgeInsets.symmetric(horizontal: (node.level - rootLevel) * levelPadding)),
        Icon(nodeCollapsedIcon),
      ]);
    }
    // Icon(Icons.arrow_right),
  }

  void _onAdd(BuildContext context, E parent) {
    Provider.of<TreeListModel<E>>(context, listen: false)
        .addNode(parent)
        .then((node) => onAdd?.call(context, parent, node));
  }

  void _onRemove(BuildContext context, E node) {
    Provider.of<TreeListModel<E>>(context, listen: false)
        .deleteSubTree(node)
        .then((value) => onRemove?.call(context, node));
  }
}

class TreeListView<E extends TreeNode> extends StatelessWidget {
  final void Function(BuildContext context, E node)? onRemove;
  final void Function(BuildContext context, E parent, E node)? onAdd;
  final void Function(BuildContext context, E source, E? target, bool result)? onReorder;
  final ListTile? listTile;
  final ListTile? editListTile;
  final String Function(E node) title;
  final String Function(E node)? subTitle;

  final ValueChanged<String>? onTapped;

  TreeListView(
      {Key? key,
      this.onAdd,
      this.onRemove,
      this.onReorder,
      this.onTapped,
      required this.title,
      this.subTitle,
      this.listTile,
        this.editListTile
      }
        )
      : super(key: key);

  void _onAdd(BuildContext context, E parent) {
    Provider.of<TreeListModel<E>>(context, listen: false)
        .addNode(parent)
        .then((node) => onAdd?.call(context, parent, node));
  }

  void _onRemove(BuildContext context, E node) {
    Provider.of<TreeListModel<E>>(context, listen: false)
        .deleteSubTree(node)
        .then((value) => onRemove?.call(context, node));
  }

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

  ListView buildListView(TreeListModel<dynamic> model) {
    return ListView.builder(
      key: const Key('__TreeList__'),
      // padding: EdgeInsets.all(8.0),
      itemCount: model.nodes.length,
      itemBuilder: (context, index) {
        final root = model.root;
        final int rootLevel = root?.level ?? 0;
        final node = model.nodes[index];
        // print(node);
        return listTile ?? buildListTile(node, context, rootLevel);
      },
    );
  }

  ReorderableListView buildReorderableListView(BuildContext context, TreeListModel<dynamic> model) {
    return ReorderableListView.builder(
      key: const Key('__EditableTreeList__'),
      // padding: EdgeInsets.all(8.0),
      onReorder: (oldIndex, newIndex) => _onReorder(context, oldIndex, newIndex),
      itemCount: model.nodes.length,
      itemBuilder: (context, index) {
        final root = model.root;
        final int rootLevel = root != null ? root.level : 0;
        final node = model.nodes[index];
        // print(node);
        return Dismissible(
          key: Key('__ModNodeItem__${node.id}__'),
          onDismissed: (_) => _onRemove(context, node),
          child: editListTile ?? buildEditListTile(context, node, rootLevel),
        );
      },
    );
  }

  ListTile buildListTile(node, BuildContext context, int rootLevel) {
    return ListTile(
        key: Key('__NodeItem__${node.id}__'),
        onTap: () => onTapped?.call(node.id),
        // leading: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        //   IconButton(
        //     icon: Icon(node.expanded ? Icons.arrow_drop_down : Icons.arrow_right),
        //     onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
        //   ),
        //   Container(padding: EdgeInsets.symmetric(horizontal: (node.level - rootLevel) * 10.0)),
        //   // Icon(Icons.arrow_right),
        // ]),
        leading: IconButton(
          icon: Icon(node.expanded ? Icons.indeterminate_check_box_outlined : Icons.add_box_outlined),
          onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
        ),
        title: Text(title(node)),
        subtitle: subTitle != null ? Text(subTitle?.call(node) ?? '') : null,
        contentPadding: EdgeInsets.only(left: (node.level - rootLevel) * 12.0),
      );
  }

  ListTile buildEditListTile(BuildContext context, E node, int rootLevel) {
    return ListTile(
          onTap: () => onTapped?.call(node.id),
          leading:IconButton(
            icon: Icon(node.expanded ? Icons.indeterminate_check_box_outlined : Icons.add_box_outlined),
          onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
        ),
          contentPadding: EdgeInsets.only(left: (node.level - rootLevel) * 12.0),
          trailing: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, mainAxisSize: MainAxisSize.min, children: <Widget>[
            IconButton(icon: const Icon(Icons.add), onPressed: () => _onAdd(context, node)),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _onRemove(context, node)),
            if (kIsWeb) Padding(padding: EdgeInsets.only(left: 40.0))
          ]),
          // leading: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          //   IconButton(
          //     icon: Icon(node.expanded ? Icons.arrow_drop_down : Icons.arrow_right),
          //     onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
          //   ),
          //   IconButton(icon: const Icon(Icons.add), onPressed: () => _onAdd(context, node)),
          //   IconButton(icon: const Icon(Icons.delete), onPressed: () => _onRemove(context, node)),
          //   Container(padding: EdgeInsets.symmetric(horizontal: (node.level - rootLevel) * 10.0)),
          //   Icon(Icons.arrow_right),
          // ]),
          title: Text(
            title(node),
          ),
          subtitle: subTitle != null ? Text(subTitle?.call(node) ?? '') : null,
        );
  }
}
