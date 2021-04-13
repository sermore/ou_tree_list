import 'package:flutter/material.dart';
import 'package:ou_tree_list/tree_list/model.dart';

import 'orgunit.dart';
import 'tree_list/tree_list.dart';

class OuListScreen extends StatelessWidget {
  OuListScreen({
    required this.treeListTileCfg,
    required this.onReorder,
  });

  final TreeListTileCfg<OrgUnit> treeListTileCfg;
  final void Function(
          BuildContext context, OrgUnit source, OrgUnit? target, bool result)
      onReorder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          title: Text('Organizational units Editor'),
        ),
        body: Column(
          children: [
            TreeListButtonBar<OrgUnit>(treeListTileCfg: treeListTileCfg),
            const Divider(),
            Expanded(
                child: TreeListView<OrgUnit>(
              onReorder: onReorder,
              treeListTileCfg: treeListTileCfg,
            ))
          ],
        ));
  }
}
