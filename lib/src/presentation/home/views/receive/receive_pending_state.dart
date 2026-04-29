import "package:file_sizes/file_sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:two_dimensional_scrollables/two_dimensional_scrollables.dart";

import "../../../../../rust/types.dart";
import "../../../../../utils.dart";
import "../../../../cubits/receive_cubit.dart";
import "../../../../models/tree_node.dart";

class ReceivePendingStateWidget extends StatefulWidget {
  final List<BlobInfo> files;
  final bool isWaiting;

  const ReceivePendingStateWidget({
    super.key,
    required this.files,
    this.isWaiting = false,
  });

  @override
  State<ReceivePendingStateWidget> createState() =>
      _ReceivePendingStateWidgetState();
}

class _ReceivePendingStateWidgetState extends State<ReceivePendingStateWidget> {
  late BigInt _totalSize;
  late int _length;
  late List<TreeViewNode<TreeNode>> _tree;

  final TreeViewController _controller = TreeViewController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  bool _isClick = false;

  @override
  void initState() {
    super.initState();
    _calculateValues();
  }

  @override
  void didUpdateWidget(ReceivePendingStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files != widget.files) {
      _calculateValues();
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    _length = widget.files.length;
    _totalSize = widget.files.fold(
      BigInt.zero,
      (prev, element) => prev + element.size,
    );
    _tree = _toSliverRoots(buildTree(widget.files));
  }

  TreeViewNode<TreeNode> _toSliverNode(TreeNode node) {
    final children = node.children.values.map(_toSliverNode).toList();
    return TreeViewNode<TreeNode>(node, children: children);
  }

  List<TreeViewNode<TreeNode>> _toSliverRoots(List<TreeNode> roots) {
    return roots.map(_toSliverNode).toList();
  }

  static Widget _treeNodeBuilder(
    BuildContext context,
    TreeViewNode<TreeNode> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFolder = !node.content.isFile;

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: TreeView.wrapChildToToggleNode(
        node: node,
        child: Row(
          spacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFolder
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isFolder
                  ? Icon(
                      node.isExpanded ? Symbols.folder_open : Symbols.folder,
                      size: 18,
                      color: isFolder
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    )
                  : const Icon(Symbols.description, size: 18),
            ),
            Text(
              node.content.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isFolder ? FontWeight.bold : FontWeight.normal,
                color: colorScheme.onSurface,
              ),
            ),
            Badge(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              backgroundColor: theme.colorScheme.outlineVariant,
              textColor: theme.primaryColor,
              label: Text(FileSize.getSize(node.content.size ?? 0)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: widget.isWaiting
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(
                    Symbols.file_download,
                    size: 32,
                    color: colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isWaiting ? "Waiting for metadata..." : "Incoming Files",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.isWaiting
                  ? "Retrieving information about the files being sent."
                  : "Someone wants to send you $_length ${_length == 1 ? "file" : "files"} (${FileSize.getSize(_totalSize)}).",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (!widget.isWaiting) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _horizontalController,
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _verticalController,
                    child: TreeView(
                      verticalDetails: ScrollableDetails.vertical(
                        controller: _verticalController,
                      ),
                      horizontalDetails: ScrollableDetails.horizontal(
                        controller: _horizontalController,
                      ),
                      tree: _tree,
                      controller: _controller,
                      treeNodeBuilder: _treeNodeBuilder,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: !_isClick
                          ? () {
                              setState(() => _isClick = true);
                              context.read<ReceiveCubit>().reject();
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: !_isClick
                          ? () {
                              setState(() => _isClick = true);
                              context.read<ReceiveCubit>().accept();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Accept"),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}
