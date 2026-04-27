class TreeNode {
  final String name;
  final bool isFile;
  BigInt? size;
  final Map<String, TreeNode> children = {};

  TreeNode.folder(this.name) : isFile = false, size = null;

  TreeNode.file(this.name, this.size) : isFile = true;

  BigInt computeSize() {
    if (isFile) return size ?? BigInt.zero;
    BigInt total = BigInt.zero;
    for (final child in children.values) {
      total += child.computeSize();
    }
    size = total;
    return total;
  }
}
