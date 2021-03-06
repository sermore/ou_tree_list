import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'model.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TreeListView<E extends TreeNode> extends StatelessWidget {

  TreeListView({
    Key? key,
    this.onReorder,
    this.dismissibleTile = true,
    required this.treeListTileCfg
  }) : super(key: key);

  final TreeListTileCfg treeListTileCfg;
  final void Function(BuildContext context, E source, E? target, bool result)? onReorder;
  final bool dismissibleTile;

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
      itemBuilder: (context, index) => treeListTileCfg.build(context, model, model.nodes[index], model.root?.level ?? 0),
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
          final rootLevel = model.root?.level ?? 0;
          // print(node);
          if (dismissibleTile) {
            return Dismissible(
              key: Key('__ModNodeItem__${node.id}__'),
              onDismissed: (_) => treeListTileCfg._onRemove(context, model, node, rootLevel),
              child: treeListTileCfg.build(context, model, node, rootLevel),
            );
          } else {
            return treeListTileCfg.build(context, model, node, rootLevel);
          }
        });
  }

}

class TreeListButtonBar<E extends TreeNode> extends StatelessWidget {

  const TreeListButtonBar({Key? key, required this.treeListTileCfg}) : super(key: key);

  final TreeListTileCfg treeListTileCfg;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TreeListModel<E>>(context, listen: true);
    final int totalLength = model.totalLength;
    final int subTreeLength = model.root != null ? model.subTreeLength(model.root!) : -1;
    return ButtonBar(
      key: const Key('__TreeListButtonBar__'),
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: AppLocalizations.of(context)!.tlToggleTooltip,
            onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpansion()
        ),
        IconButton(
          onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).load(),
          icon: Icon(Icons.autorenew, semanticLabel: AppLocalizations.of(context)!.tlReload),
          tooltip: AppLocalizations.of(context)!.tlReload,
        ),
        if (model.editable)
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppLocalizations.of(context)!.tlAddTooltip,
              onPressed: () {
                final model = Provider.of<TreeListModel<E>>(context, listen: false);
                treeListTileCfg._onAdd(context, model, model.root, model.root?.level ?? 0);
              }
          ),
        Tooltip(
            message: AppLocalizations.of(context)!.tlSwitchTooltip,
            child: Switch(
              value: model.editable,
              onChanged: (value) {
                model.editable = value;
              },
            )),
        Text(subTreeLength > -1 ? '${AppLocalizations.of(context)!.tlLength} $subTreeLength ($totalLength)' : '${AppLocalizations.of(context)!.tlLength} $totalLength')
      ],
    );
  }
}

class TreeListTileCfg<E extends TreeNode> {

  TreeListTileCfg({
    required this.createNode,
      this.levelPadding,
      this.isThreeLine,
      this.dense,
      this.visualDensity,
      this.shape,
      this.enabled,
      this.mouseCursor,
      this.selected,
      this.focusColor,
      this.hoverColor,
      this.focusNode,
      this.autofocus,
      this.tileColor,
      this.selectedTileColor,
      this.enableFeedback,
      this.horizontalTitleGap,
      this.minVerticalPadding,
      this.minLeadingWidth,
      this.onRemove,
      this.onAdd,
      this.onTap,
      required this.title,
      this.subtitle,
      this.leading,
      this.contentPadding,
      this.trailing,
  });

  final E Function({required BuildContext context, E? parent}) createNode;

  final double Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? levelPadding;

  final bool Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? isThreeLine;

  final bool? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? dense;

  final VisualDensity? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? visualDensity;

  final ShapeBorder? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? shape;

  final bool Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? enabled;

  // GestureLongPressCallback? onLongPress;
  final MouseCursor? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? mouseCursor;

  final bool Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? selected;

  /// The color for the tile's [Material] when it has the input focus.
  final Color? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? focusColor;

  /// {@macro flutter.material.ListTile.hoverColor}
  final Color? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? hoverColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? autofocus;

  /// {@macro flutter.material.ListTile.tileColor}
  final Color? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? tileColor;

  /// {@macro flutter.material.ListTile.selectedTileColor}
  final Color? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? selectedTileColor;

  final bool? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? enableFeedback;

  final double? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? horizontalTitleGap;

  final double? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? minVerticalPadding;

  final double? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? minLeadingWidth;

  final void Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? onRemove;

  final void Function(BuildContext context, TreeListModel<E> model, E? node, int rootLevel, E newNode)? onAdd;

  final void Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? onTap;

  /// {@macro flutter.material.ListTile.title}
  final Widget Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel) title;

  final Widget? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? subtitle;

  /// {@macro flutter.material.ListTile.leading}
  final Widget Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? leading;

  final EdgeInsets Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? contentPadding;

  final Widget? Function(BuildContext context, TreeListModel<E> model, E node, int rootLevel)? trailing;

  void _onAdd(BuildContext context, TreeListModel<E> model, E? parent, int rootLevel) {
    print('onAdd parent=$parent');
    E node = createNode(context: context, parent: parent);
    // Provider.of<TreeListModel<E>>(context, listen: false).addNode(node).then((newNode) => onAdd?.call(context, model, node, rootLevel, newNode));
    model.addNode(parent, node).then((newNode) => onAdd?.call(context, model, parent, rootLevel, newNode));
  }

  void _onRemove(BuildContext context, TreeListModel<E> model, E node, int rootLevel) {
    print('onRemove $node');
    // Provider.of<TreeListModel<E>>(context, listen: false).deleteSubTree(node).then((value) => onRemove?.call(context, model, node, rootLevel));
    model.deleteSubTree(node).then((value) => onRemove?.call(context, model, node, rootLevel));
  }

  double buildLevelPadding(BuildContext context, TreeListModel<E> model, E node, int rootLevel) => 24;

  Widget buildLeading(BuildContext context, TreeListModel<E> model, E node, int rootLevel) {
    return IconButton(
      icon: Icon(node.expanded ? Icons.indeterminate_check_box_outlined : Icons.add_box_outlined),
      onPressed: () => Provider.of<TreeListModel<E>>(context, listen: false).toggleExpandNode(node),
    );
  }

  Widget? buildTrailing(BuildContext context, TreeListModel<E> model, E node, int rootLevel) {
    return model.editable
        ? Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
      IconButton(icon: const Icon(Icons.add), onPressed: () => _onAdd(context, model, node, rootLevel)),
      IconButton(icon: const Icon(Icons.delete), onPressed: () => _onRemove(context, model, node, rootLevel)),
      if (kIsWeb) Padding(padding: EdgeInsets.only(left: 40.0))
    ])
        : null;
  }

  EdgeInsets buildContentPadding(BuildContext context, TreeListModel<E> model, E node, int rootLevel) => EdgeInsets.only(left: (node.level - rootLevel) * (levelPadding?.call(context, model, node, rootLevel) ?? buildLevelPadding(context, model, node, rootLevel)));

  Widget build(BuildContext context, TreeListModel<E> model, E node, int rootLevel) {
    return ListTile(
      key: Key('__TreeNode_${node.id}__'),
      onTap: () => onTap?.call(context, model, node, rootLevel),
      title: title(context, model, node, rootLevel),
      subtitle: subtitle?.call(context, model, node, rootLevel),
      leading: leading?.call(context, model, node, rootLevel) ?? buildLeading(context, model, node, rootLevel),
      trailing: trailing?.call(context, model, node, rootLevel) ?? buildTrailing(context, model, node, rootLevel),
      contentPadding: contentPadding?.call(context, model, node, rootLevel) ?? buildContentPadding(context, model, node, rootLevel),
      isThreeLine: isThreeLine?.call(context, model, node, rootLevel) ?? false,
      dense: dense?.call(context, model, node, rootLevel),
      visualDensity: visualDensity?.call(context, model, node, rootLevel),
      shape: shape?.call(context, model, node, rootLevel),
      enabled: enabled?.call(context, model, node, rootLevel) ?? true,
      mouseCursor: mouseCursor?.call(context, model, node, rootLevel),
      selected: selected?.call(context, model, node, rootLevel) ?? false,
      focusColor: focusColor?.call(context, model, node, rootLevel),
      hoverColor: hoverColor?.call(context, model, node, rootLevel),
      focusNode: focusNode?.call(context, model, node, rootLevel),
      autofocus: autofocus?.call(context, model, node, rootLevel) ?? false,
      tileColor: tileColor?.call(context, model, node, rootLevel),
      selectedTileColor: selectedTileColor?.call(context, model, node, rootLevel),
      enableFeedback: enableFeedback?.call(context, model, node, rootLevel),
      horizontalTitleGap: horizontalTitleGap?.call(context, model, node, rootLevel),
      minVerticalPadding: minVerticalPadding?.call(context, model, node, rootLevel),
      minLeadingWidth: minLeadingWidth?.call(context, model, node, rootLevel),
    );
  }

}
