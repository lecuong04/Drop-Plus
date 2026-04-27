import "package:file_sizes/file_sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";

import "../../../../../rust/progress.dart";
import "../../../../cubits/receive_cubit.dart";

class ReceiveTransferringStateWidget extends StatelessWidget {
  final List<ProgressState> progresses;

  const ReceiveTransferringStateWidget({super.key, required this.progresses});

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
              color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.downloading,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Receiving Files",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Downloading files to your device securely.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: progresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final progress = progresses[index];
                final phase = progress.phase;
                final name = phase is Phase_Exporting
                    ? phase.name
                    : "Downloading...";
                final position = progress.position;
                final length = progress.length;
                final percent = (length != null && length > BigInt.zero)
                    ? position.toDouble() / length.toDouble()
                    : null;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Symbols.description,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (percent != null)
                            Text(
                              "${(percent * 100).toStringAsFixed(1)}%",
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (percent != null)
                        LinearProgressIndicator(
                          value: percent,
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 8,
                        )
                      else
                        const LinearProgressIndicator(minHeight: 8),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FileSize.getSize(position),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (length != null)
                            Text(
                              FileSize.getSize(length),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
            child: FilledButton.tonalIcon(
              onPressed: () => context.read<ReceiveCubit>().cancel(),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Symbols.cancel, size: 20),
              label: const Text("Stop Receiving"),
            ),
          ),
        ],
      ),
    );
  }
}
