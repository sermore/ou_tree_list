import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';

class TreeListView<E extends TreeNode> extends StatelessWidget {
  final void Function(BuildContext context, E node)? onRemove;
  final void Function(BuildContext context, E parent, E node)? onAdd;
  final void Function(BuildContext context, E source, E? target, bool result)? onReorder;
  final String Function(E node) title;
  final String Function(E node)? subTitle;

  final ValueChanged<String>? onTapped;

  TreeListView({Key? key, this.onAdd, this.onRemove, this.onReorder, this.onTapped, required this.title, this.subTitle})
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
      if (model.editable) {
        return ReorderableListView.builder(
          key: const Key('EditableTreeList'),
          // padding: EdgeInsets.all(8.0),
          onReorder: (oldIndex, newIndex) => _onReorder(context, oldIndex, newIndex),
          itemCount: model.nodes.length,
          itemBuilder: (context, index) {
            final root = model.root;
            final int rootLevel = root != null ? root.level : 0;
            final node = model.nodes[index];
            // print(node);
            return Dismissible(
              key: Key('ModNodeItem__${node.id}'),
              onDismissed: (_) => _onRemove(context, node),
              child: ListTile(
                onTap: () => onTapped?.call(node.id),
                leading: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  IconButton(
                    icon: Icon(node.expanded ? Icons.arrow_drop_down : Icons.arrow_right),
                    onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false)
                        .toggleExpandNode(node),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => _onAdd(context, node)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _onRemove(context, node)),
                  Container(padding: EdgeInsets.symmetric(horizontal: (node.level - rootLevel) * 10.0)),
                  Icon(Icons.arrow_right),
                ]),
                title: Text(
                  title(node),
                ),
                subtitle: subTitle != null ? Text(subTitle?.call(node) ?? '') : null,
              ),
            );
          },
        );
      } else {
        return ListView.builder(
          key: const Key('TreeList'),
          // padding: EdgeInsets.all(8.0),
          itemCount: model.nodes.length,
          itemBuilder: (context, index) {
            final root = model.root;
            final int rootLevel = root?.level ?? 0;
            final node = model.nodes[index];
            // print(node);
            return ListTile(
              key: Key('NodeItem__${node.id}'),
              onTap: () => onTapped?.call(node.id),
              leading: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                IconButton(
                  icon: Icon(node.expanded ? Icons.arrow_drop_down : Icons.arrow_right),
                  onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false)
                      .toggleExpandNode(node),
                ),
                Container(padding: EdgeInsets.symmetric(horizontal: (node.level - rootLevel) * 10.0)),
                // Icon(Icons.arrow_right),
              ]),
              title: Text(title(node)),
            );
          },
        );
      }
    });
  }
}
