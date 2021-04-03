import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';

class TreeListButtonBar<E extends TreeNode> extends StatelessWidget {
  final void Function(BuildContext context, E? parent, E node)? onAdd;
  final String Function(E node) title;

  const TreeListButtonBar({Key? key, required this.title, this.onAdd}) : super(key: key);

  void _onAdd(BuildContext context) {
    final model = Provider.of<TreeListModel<E>>(context, listen: false);
    model.addNode(model.root).then((newNode) => onAdd?.call(context, model.root, newNode));
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TreeListModel<E>>(context, listen: true);
    final int totalLength = model.totalLength;
    final int subTreeLength = model.root != null ? model.subTreeLength(model.root!) : -1;
    return ButtonBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Toggle tree expansion',
            onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpansion()
        ),
        IconButton(
            onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).load(),
            icon: const Icon(Icons.autorenew, semanticLabel: "Reload",),
            tooltip: "Reload",
        ),
        if (model.editable)
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add a root item',
              onPressed: () => _onAdd(context)
          ),
        Tooltip(
            message: 'Enable Editable mode',
            child: Switch(
              value: model.editable,
              onChanged: (value) {
                model.editable = value;
              },
            )),
        Text(subTreeLength > -1 ? 'Sub-tree length $subTreeLength (Total $totalLength)' : 'Total length $totalLength')
      ],
    );
  }
}
