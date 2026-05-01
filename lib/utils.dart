import "rust/types.dart";
import "src/models/tree_node.dart";

List<TreeNode> buildTree(List<BlobInfo> files) {
  final Map<String, TreeNode> roots = {};
  for (final file in files) {
    final parts = file.name.split("/");
    Map<String, TreeNode> currentLevel = roots;
    TreeNode? currentNode;
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isLast = i == parts.length - 1;
      if (isLast) {
        currentNode = currentLevel.putIfAbsent(
          part,
          () => TreeNode.file(part, file.size),
        );
      } else {
        currentNode = currentLevel.putIfAbsent(
          part,
          () => TreeNode.folder(part),
        );
      }
      currentLevel = currentNode.children;
    }
  }
  return roots.values.map((root) => root..computeSize()).toList();
}
