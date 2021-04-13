import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'orgunit.dart';
import 'tree_list/tree_list.dart';

class OuEditScreen extends StatefulWidget {
  const OuEditScreen({
    required this.id,
    required this.treeListTileCfg,
    required this.onReorder,
    required this.onSave,
  }) : super(key: const Key('EditorScreen'));

  final String id;
  final TreeListTileCfg<OrgUnit> treeListTileCfg;
  final void Function(
          BuildContext context, OrgUnit source, OrgUnit? target, bool result)
      onReorder;
  final void Function(BuildContext context, OrgUnit node) onSave;

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
    OrgUnit ou = Provider.of<TreeListModel<OrgUnit>>(context, listen: false)
        .findNodeById(widget.id)!;
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
      final OrgUnit? nullableNode = model.findNodeById(widget.id);
      if (nullableNode == null) {
        // avoid rebuild the whole widget in case the root element has been deleted
        return SizedBox();
      }
      final OrgUnit rootNode = nullableNode;
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Organizational unit'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                Provider.of<TreeListModel<OrgUnit>>(context, listen: false)
                    .deleteSubTree(rootNode)
                    .then((res) {
                  widget.treeListTileCfg.onRemove
                      ?.call(context, model, rootNode, 0);
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
                        child: Column(children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Edit properties',
                                    style:
                                        Theme.of(context).textTheme.headline6)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Parent',
                                    style: Theme.of(context).textTheme.button),
                              ),
                              Expanded(
                                  child: Text(rootNode.parentId == null
                                      ? 'Root Element'
                                      : model
                                          .findNodeById(rootNode.parentId!)!
                                          .name)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('Level',
                                      style:
                                          Theme.of(context).textTheme.button)),
                              Text(rootNode.level.toString()),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Name',
                                    style: Theme.of(context).textTheme.button),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  key: const Key('NameField'),
                                  decoration: InputDecoration(
                                    hintText: "Organizational unit's name",
                                  ),
                                  validator: (val) {
                                    return val!.trim().isEmpty
                                        ? 'Please enter some text'
                                        : null;
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
                                child: Text('Active',
                                    style: Theme.of(context).textTheme.button),
                              ),
                              Switch(
                                value: _active,
                                onChanged: (value) => setState(() {
                                  _active = value;
                                }),
                              )
                            ],
                          ),
                        ])),
                  ),
                ],
              ),
            ),
            if (MediaQuery.of(context).size.height > 400)
              TreeListButtonBar<OrgUnit>(
                key: const Key('OUButtonBar'),
                treeListTileCfg: widget.treeListTileCfg,
              ),
            if (MediaQuery.of(context).size.height > 400) Divider(),
            if (MediaQuery.of(context).size.height > 400)
              Expanded(
                  child: TreeListView<OrgUnit>(
                treeListTileCfg: widget.treeListTileCfg,
                onReorder: widget.onReorder,
              ))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('OUSave'),
          tooltip: 'Save changes',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              OrgUnit modNode =
                  rootNode.copy(name: _nameController.text, active: _active);
              Provider.of<TreeListModel<OrgUnit>>(context, listen: false)
                  .updateNode(modNode)
                  .then((node) {
                widget.onSave(context, node);
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
