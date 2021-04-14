import 'package:collection/collection.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:ou_tree_list/orgunit.dart';
import 'package:ou_tree_list/tree_list/model.dart';

void main() {
  test('Model behaves correctly', () async {
    final TreeListModel model = TreeListModel<OrgUnit>(
      // createNode: ({OrgUnit? parent, int level = 0}) => OrgUnit(
      //     name: parent == null ? 'A new root item' : 'A new child of ${parent.name}',
      //     parentId: parent?.id,
      //     level: level),
      // repository: RestRepository<OrgUnit>(
      //     uri: 'localhost:8080',
      //     fromJson: OrgUnit.fromJson,
      //     onError: (ex, stackTrace) {
      //       print('error during repository operation $ex');
      //       throw ex;
      //     }),
      repository: NoOpRepository<OrgUnit>(() => Future.value(generate(100))),
    );

    expect(await model.load(), hasLength(100));
    final n = OrgUnit(name: 'o1');
    expect(await model.addNode(null, n), predicate<TreeNode>((node) => node.parentId == null));
    expect(model.totalLength, 101);
    expect(model.root, isNull);
    model.root = model.nodes.firstWhere((n) => model.nodes.firstWhereOrNull((c) => c.parentId == n.id) != null);
    final totalLength = model.totalLength;
    final subTreeLength = model.subTreeLength(model.root!);
    model.deleteSubTree(model.root!).then((res) {
      expect(model.totalLength, totalLength - 1 - subTreeLength);
      expect(model.root, isNull);
    });
  });
}