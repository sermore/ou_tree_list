import 'dart:async';
import 'dart:collection';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_screen.dart';
import 'list_screen.dart';
import 'orgunit.dart';
import 'tree_list/tree_list.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(OuEditorApp());
}

class OuEditorApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OuEditorAppState();
}

class _OuEditorAppState extends State<OuEditorApp> {
  _OuRouterDelegate _routerDelegate = _OuRouterDelegate();
  _OuRouteInformationParser _routeInformationParser = _OuRouteInformationParser();

  // TreeListModel<OrgUnit> _model;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => TreeListModel<OrgUnit>(
          // createNode: ({OrgUnit? parent, int level = 0}) => OrgUnit(
          //     name: parent == null ? AppLocalis.of(context)!.newRootItem : AppLocalizations.of(context)!.newChildItem(parent.name),
          //     parentId: parent?.id,
          //     level: level),
          repository: RestRepository<OrgUnit>(
              uri: 'localhost:8080',
              fromJson: OrgUnit.fromJson,
              onError: (ex, stackTrace) {
                print('error during repository operation $ex');
                throw ex;
              }),
          // NoOpRepository<OrgUnit>(() => Future.delayed(Duration(seconds: 2), () => generate(100))),
          //   forceReload: true,
        )..load(),
        child: MaterialApp.router(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', ''), // English, no country code
            const Locale('it', ''), // Italian, no country code
          ],

          onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.title,
          routerDelegate: _routerDelegate,
          routeInformationParser: _routeInformationParser,
        ));
  }
}

class _OuRouteInformationParser extends RouteInformationParser<_OuRoutePath> {
  @override
  Future<_OuRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);
    // Handle '/'
    if (uri.pathSegments.length == 0) {
      return _OuRoutePath.home();
    }

    // Handle '/ou/:id'
    if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] != 'ou') return _OuRoutePath.unknown();
      var id = uri.pathSegments[1];
      // if (id == null) return _OuRoutePath.unknown();
      return _OuRoutePath.details(id);
    }

    // Handle unknown routes
    return _OuRoutePath.unknown();
  }

  @override
  RouteInformation? restoreRouteInformation(_OuRoutePath path) {
    if (path.isUnknown) {
      return RouteInformation(location: '/404');
    }
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isDetailsPage) {
      return RouteInformation(location: '/ou/${path.id}');
    }
    return null;
  }
}

class _OuRouterDelegate extends RouterDelegate<_OuRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<_OuRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;
  final Queue<String> _selectedOu = ListQueue();
  late TreeListModel<OrgUnit> _model;
  bool show404 = false;

  _OuRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  _OuRoutePath get currentConfiguration {
    if (show404) {
      return _OuRoutePath.unknown();
    }
    return _selectedOu.isEmpty ? _OuRoutePath.home() : _OuRoutePath.details(_selectedOu.first);
  }

  @override
  Widget build(BuildContext context) {
    _model = Provider.of<TreeListModel<OrgUnit>>(context, listen: true);
    _model.createNode = ({OrgUnit? parent, int level = 0}) => OrgUnit(
        name: parent == null ? AppLocalizations.of(context)!.newRootItem : AppLocalizations.of(context)!.newChildItem(parent.name),
        parentId: parent?.id,
        level: level);
    final treeListTileCfg = TreeListTileCfg(
        createNode: ({required BuildContext context, OrgUnit? parent, int level = 0}) => OrgUnit(
            name: parent == null ? AppLocalizations.of(context)!.newRootItem : AppLocalizations.of(context)!.newChildItem(parent.name),
            parentId: parent?.id,
            level: level),
        levelPadding: (BuildContext context, TreeListModel<OrgUnit> model, OrgUnit node, int rootLevel) => 30,
        title: (BuildContext context, TreeListModel<OrgUnit> model, OrgUnit node, int rootLevel) => Text(node.name),
        subtitle: (BuildContext context, TreeListModel<OrgUnit> model, OrgUnit node, int rootLevel) => Text('id = ${node.id}, parentId = ${node.parentId}'),
        onAdd: (BuildContext context, TreeListModel<OrgUnit> model, OrgUnit? node, int rootLevel, OrgUnit newNode) {
          Router r = Router.of(context);
          _OuRouterDelegate routerDelegate = r.routerDelegate as _OuRouterDelegate;
          routerDelegate._onAdd(context, node, newNode);
        },
        onRemove: (BuildContext context, TreeListModel<OrgUnit> model, OrgUnit node, int rootLevel) {
          Router r = Router.of(context);
          _OuRouterDelegate routerDelegate = r.routerDelegate as _OuRouterDelegate;
          routerDelegate._onRemove(context, node);
        },
        onTap: (BuildContext context, TreeListModel<OrgUnit> model, OrgUnit node, int rootLevel) {
          Router r = Router.of(context);
          _OuRouterDelegate routerDelegate = r.routerDelegate as _OuRouterDelegate;
          routerDelegate._handleOuTapped(node.id);
        }
    );
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: ValueKey('OuListPage'),
          child: OuListScreen(
            onAdd: _onAdd,
            onReorder: _onReorder,
            treeListTileCfg: treeListTileCfg,
          ),
        ),
        if (show404)
          MaterialPage(key: ValueKey('UnknownPage'), child: _UnknownScreen())
        else if (_selectedOu.isNotEmpty)
          MaterialPage(
            key: ValueKey(_selectedOu.first),
            child: OuEditScreen(
              treeListTileCfg: treeListTileCfg,
              onReorder: _onReorder,
              onSave: _onSave,
              id: _selectedOu.first,
            ),
          )
      ],
      onPopPage: (route, result) {
        print('onPopPage route=$route, result=$result');
        if (!route.didPop(result)) {
          return false;
        }

        if (_selectedOu.isNotEmpty) {
          _selectedOu.removeFirst();
        }
        _model.root = _selectedOu.isNotEmpty ? _model.findNodeById(_selectedOu.first) : null;
        show404 = false;
        notifyListeners();

        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(_OuRoutePath path) async {
    print('setNewRoutePath path=$path');
    if (path.isUnknown) {
      _selectedOu.clear();
      _model.root = null;
      show404 = true;
      return;
    }

    if (path.isDetailsPage) {
      OrgUnit? ou = _model.findNodeById(path.id!);
      if (ou == null) {
        show404 = true;
        return;
      }

      _selectedOu.addFirst(path.id!);
      _model.root = ou;
    } else if (_selectedOu.isNotEmpty) {
      // } else {
      _selectedOu.clear();
      _model.root = null;
    }

    show404 = false;
  }

  void _onReorder(BuildContext context, OrgUnit source, OrgUnit? target, bool result) {
    final msg = result
        ? 'Moved ${source.name} under ${target?.name ?? "root"}'
        : 'Unable to move ${source.name} under one of its descendants ${target!.name}';
    _showSnackbar(context, source, msg);
  }

  void _handleOuTapped(String id) {
    print('tapped on $id');
    _selectedOu.addFirst(id);
    _model.root = _model.findNodeById(id);
    notifyListeners();
  }

  void _onRemove(context, node) {
    print('deleted $node');
    _showSnackbar(context, node, 'Organizational unit ${node.name} and its children deleted');
  }

  void _onSave(context, node) {
    print('updated $node');
    _showSnackbar(context, node, 'Organizational unit ${node.name} saved');
  }

  void _onAdd(context, parent, newNode) {
    print('created $newNode as child of $parent');
    _showSnackbar(context, newNode, 'Created new Organizational unit ${newNode.name}');
  }

  void _showSnackbar(BuildContext context, OrgUnit orgUnit, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('OUSnackbar'),
        duration: const Duration(seconds: 4),
        content: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(key: Key('__snackbar_action_${orgUnit.id}__'), label: 'Undo', onPressed: () => {}),
      ),
    );
  }

}

class _OuRoutePath {
  final String? id;
  final bool isUnknown;

  _OuRoutePath.home()
      : id = null,
        isUnknown = false;

  _OuRoutePath.details(this.id) : isUnknown = false;

  _OuRoutePath.unknown()
      : id = null,
        isUnknown = true;

  bool get isHomePage => id == null;

  bool get isDetailsPage => id != null;
}

class _UnknownScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('404!'),
      ),
    );
  }
}
