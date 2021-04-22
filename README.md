# ou_tree_list

A simple application to view and modify hierarchical data.
Features:
* hierarchical list view using *ListView builder* and customizable *ListTile*, appropriate for a large number of children;
* navigation into sub-trees
* collapse / expand whole dataset
* use a simple repository interface to interact with a remote datasource
* editable mode
  * drag and drop to move whole sub-trees into different parent nodes
  * node addition
  * sub-tree removal
  * node modification

Data handling is implemented by two components:
* *TreeListView*
* *TreeListButtonBar*
and a data model
* *TreeListModel*

Data must fulfill these requirements:
* The data item must implement the *TreeNode* mixin which defines a set of getter for required properties;
* hierarchical items must follow *breadth first* order; the library expects to receive already ordered data;
* the whole dataset must be loaded;

This application showcase the following flutter features:
* Flutter 2 navigation system
* Null safety
* Provider-based state management
* Localization


## Reference Documentation

- [Architectural overview](https://flutter.dev/docs/resources/architectural-overview)
- [Learning Flutter’s new navigation and routing system](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade)
- [Architecture samples](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider)
- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)
- [online documentation](https://flutter.dev/docs)


## TODO
- problems after reload: the position in the tree and the state of expanded nodes are lost
- test
