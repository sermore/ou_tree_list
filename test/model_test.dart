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
      repository: NoOpRepository<OrgUnit>(() => Future.value(generate(10))),
    );

    expect(await model.load(), hasLength(20));
    final o1 = OrgUnit(name: 'o1');
    OrgUnit? n1;
    expect(await model.addNode(null, o1), predicate<OrgUnit>((node) {
      n1 = node;
      return node.parentId == null && node.name == o1.name;
    }));
    expect(n1, o1);
    expect(model.totalLength, 21);
    expect(model.root, isNull);
    final o2 = OrgUnit(name: 'o2', parentId: o1.parentId, level: 1);
    // find a node with children and set it as root
    // model.root = model.nodes.firstWhere((n) => model.nodes.firstWhereOrNull((c) => c.parentId == n.id) != null);
    final totalLength = model.totalLength;
    final subTreeLength = model.subTreeLength(model.root!);
    expect(subTreeLength, greaterThan(0));
    model.deleteSubTree(model.root!).then((res) {
      expect(model.totalLength, totalLength - 1 - subTreeLength);
      expect(model.root, isNull);
    });
  });
}