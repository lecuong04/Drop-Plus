import "dart:collection";
import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";

import "../../../../cubits/send_cubit.dart";

class SendInitialStateWidget extends StatefulWidget {
  const SendInitialStateWidget({super.key});

  @override
  State<SendInitialStateWidget> createState() => _SendInitialStateWidgetState();
}

class _SendInitialStateWidgetState extends State<SendInitialStateWidget> {
  final HashMap<String, bool> _selectedPath = HashMap<String, bool>();

  bool _isPick = false;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInQuart,
        switchOutCurve: Curves.easeOutExpo,
        child: _selectedPath.isEmpty
            ? _buildEmptyState(context)
            : _buildFileListView(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Symbols.upload_file,
              size: 56,
              weight: 300,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Ready to Send?",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Select the files or folders you'd like to share with nearby devices.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _isPick ? null : _handlePickFiles,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Symbols.add_box),
                  label: const Text("Select Files"),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _isPick ? null : _handlePickDir,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Symbols.create_new_folder),
                  label: const Text("Select Folder"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Icon(
                Symbols.task_alt,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                "Selected Items",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPath.length.toString(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _selectedPath.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final key = _selectedPath.keys.elementAt(index);
              final segments = key.split(Platform.pathSeparator);
              final isFile = _selectedPath.values.elementAt(index);
              final name = segments.last;
              final parentPath = segments.length > 1
                  ? segments
                        .getRange(0, segments.length - 1)
                        .join(Platform.pathSeparator)
                  : "";

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isFile ? Symbols.description : Symbols.folder,
                            color: theme.colorScheme.primary,
                            size: 24,
                            weight: 300,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (parentPath.isNotEmpty)
                                Text(
                                  parentPath,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Symbols.close, size: 20),
                          onPressed: () {
                            setState(() => _selectedPath.remove(key));
                          },
                          color: theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selectedPath.clear()),
                icon: const Icon(Symbols.delete_sweep, size: 20),
                label: const Text("Clear All"),
                style: TextButton.styleFrom(
                  iconColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  context.read<SendCubit>().startSend(
                    _selectedPath.keys.toList(),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Symbols.send),
                label: const Text("Share Now"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handlePickFiles() async {
    setState(() => _isPick = true);
    final res = await FilePicker.pickFiles(
      dialogTitle: "Select files to share",
      allowMultiple: true,
      lockParentWindow: true,
    );
    for (final path in res?.xFiles.map((e) => e.path).toList() ?? <String>[]) {
      _selectedPath[path] = true;
    }
    setState(() => _isPick = false);
  }

  void _handlePickDir() async {
    setState(() => _isPick = true);
    final res = await FilePicker.getDirectoryPath(
      dialogTitle: "Select folder to share",
      lockParentWindow: true,
    );
    if (res != null) {
      _selectedPath[res] = false;
    }
    setState(() => _isPick = false);
  }
}
