import 'package:flutter/material.dart';

import 'orgunit.dart';
import 'tree_list/tree_list.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          title: Text(AppLocalizations.of(context)!.lsTitle),
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
