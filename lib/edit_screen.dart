import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'orgunit.dart';
import 'tree_list/button_bar.dart';
import 'tree_list/list_view.dart';
import 'tree_list/model.dart';

class OuEditScreen extends StatefulWidget {
  final String id;
  final void Function(BuildContext context, OrgUnit node) onRemove;
  final void Function(BuildContext context, OrgUnit parent, OrgUnit node) onAdd;
  final void Function(BuildContext context, OrgUnit source, OrgUnit? target, bool result) onReorder;
  final ValueChanged<String> onTapped;
  final void Function(BuildContext context, OrgUnit orgUnit, String msg) showSnackbar;

  const OuEditScreen({
    required this.id,
    required this.onRemove,
    required this.onAdd,
    required this.onReorder,
    required this.onTapped,
    required this.showSnackbar,
  }) : super(key: const Key('EditorScreen'));

  @override
  _OuEditScreenState createState() => _OuEditScreenState();
}

class _OuEditScreenState extends State<OuEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late TextEditingController _nameController;
  late bool _active;

  @override
  void initState() {
    print('init state edit');
    OrgUnit ou = Provider.of<TreeListModel<OrgUnit>>(context, listen: false).findNodeById(widget.id)!;
    _nameController = TextEditingController(text: ou.name);
    _active = ou.active;
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TreeListModel<OrgUnit>>(builder: (context, model, _) {
      final OrgUnit? ou = model.findNodeById(widget.id);
      if (ou == null) {
        // avoid rebuild the whole widget in case the root element has been deleted
        return SizedBox();
      }
      final OrgUnit orgUnit = ou;
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Organizational unit'),
          actions: [
            IconButton(icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                Provider.of<TreeListModel<OrgUnit>>(context, listen: false).deleteNode(orgUnit).then((res) {
                  widget.onRemove(context, orgUnit);
                  Navigator.pop(context);
                });
              },
            )
          ],
        ),
        body: Column(
          children: [
            Card(
              margin: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column( children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Edit properties', style: Theme.of(context).textTheme.headline6)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Parent', style: Theme.of(context).textTheme.button),
                              ),
                              Expanded(child: Text(orgUnit.parentId == null
                                  ? 'Root Element'
                                  : model.findNodeById(orgUnit.parentId!)!.name)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('Level', style: Theme.of(context).textTheme.button)),
                              Text(orgUnit.level.toString()),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Name', style: Theme.of(context).textTheme.button),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  key: const Key('NameField'),
                                  decoration: InputDecoration(
                                    hintText: "Organizational unit's name",
                                  ),
                                  validator: (val) {
                                    return val!.trim().isEmpty ? 'Please enter some text' : null;
                                  },
                                ),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Active', style: Theme.of(context).textTheme.button),
                              ),
                              Switch(
                                value: _active,
                                onChanged: (value) {
                                  setState(() {
                                    _active = value;
                                  });
                                },
                              )
                            ],
                          ),
                        ])),
                  ),
                  // ButtonBar(
                  //   children: [
                  //     ElevatedButton.icon(
                  //       icon: const Icon(Icons.save_rounded),
                  //       label: Text('Save'),
                  //       onPressed: () {
                  //         if (_formKey.currentState!.validate()) {
                  //           _formKey.currentState!.save();
                  //           OrgUnit modifiedOu = orgUnit.copy(name: _nameController.text, active: _active);
                  //           Provider.of<TreeListModel<OrgUnit>>(context, listen: false).updateNode(modifiedOu);
                  //           widget.showSnackbar(context, modifiedOu, 'Organizational unit ${modifiedOu.name} saved');
                  //         }
                  //       },
                  //     ),
                  //     ElevatedButton.icon(
                  //       icon: const Icon(Icons.delete),
                  //       label: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
                  //       onPressed: () {
                  //         print('deleted $orgUnit');
                  //         Provider.of<TreeListModel<OrgUnit>>(context, listen: false).deleteNode(orgUnit);
                  //         widget.showSnackbar(
                  //             context, orgUnit, 'Organizational unit ${orgUnit.name} and its children deleted');
                  //         return Navigator.pop(context);
                  //       },
                  //     ),
                  //   ],
                  // )
                ],
              ),
            ),
            if (MediaQuery.of(context).size.height > 400)
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Children sub-tree', style: Theme.of(context).textTheme.headline6))),
            if (MediaQuery.of(context).size.height > 400)
            Padding(
                padding: EdgeInsets.all(8.0),
                child: TreeListButtonBar<OrgUnit>(
                    key: const Key('OUButtonBar'),
                    title: (ou) => ou.name,
                    onAdd: (context, parent, node) => widget.onAdd(context, parent!, node),
                )),
            if (MediaQuery.of(context).size.height > 400)
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TreeListView<OrgUnit>(
                        title: (ou) => ou.name,
                        onAdd: widget.onAdd,
                        onRemove: widget.onRemove,
                        onReorder: widget.onReorder,
                        onTapped: widget.onTapped,
)))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('OUSave'),
          tooltip: 'Save changes',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              OrgUnit modifiedOu = orgUnit.copy(name: _nameController.text, active: _active);
              Provider.of<TreeListModel<OrgUnit>>(context, listen: false).updateNode(modifiedOu).then((node) {
                widget.showSnackbar(context, modifiedOu, 'Organizational unit ${modifiedOu.name} saved');
                Navigator.pop(context);
              });
            }
          },
          child: const Icon(Icons.check),
        ),
      );
    });
  }
}
