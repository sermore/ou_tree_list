import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'orgunit.dart';
import 'tree_list/button_bar.dart';
import 'tree_list/list_view.dart';
import 'tree_list/model.dart';

class OuListScreen extends StatelessWidget {
  final void Function(BuildContext context, OrgUnit node) onRemove;
  final void Function(BuildContext context, OrgUnit? parent, OrgUnit node) onAdd;
  final void Function(BuildContext context, OrgUnit source, OrgUnit? target, bool result) onReorder;
  final ValueChanged<String> onTapped;
  final void Function(BuildContext context, OrgUnit orgUnit, String msg)
      showSnackbar;

  OuListScreen({
    required this.onRemove,
    required this.onAdd,
    required this.onReorder,
    required this.onTapped,
    required this.showSnackbar});

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
        body: Selector<TreeListModel<OrgUnit>, bool>(
            selector: (context, model) => model.isLoading,
            builder: (context, isLoading, _) {
              return Stack(
                children: [
              if (isLoading) Center(
                  child: CircularProgressIndicator(
                    key: const Key('OULoading'),
                  ),
                ),
              Column(
                children: [
                  TreeListButtonBar<OrgUnit>(
                    title: (ou) => ou.name,
                    onAdd: onAdd
                  ),
                  const Divider(),
                  Expanded(
                      child: TreeListView<OrgUnit>(
                        title: (ou) => ou.name,
                        onTapped: onTapped,
                        onAdd: onAdd,
                        onRemove: onRemove,
                        onReorder: onReorder,
                  ))
                ],
              )
            ]);}));
  }
}
