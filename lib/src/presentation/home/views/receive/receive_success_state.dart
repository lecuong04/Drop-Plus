import "package:file_sizes/file_sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";

import "../../../../../rust/types.dart";
import "../../../../cubits/receive_cubit.dart";

class ReceiveSuccessStateWidget extends StatelessWidget {
  final ReceiveResult_Ok result;

  const ReceiveSuccessStateWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final duration = Duration(seconds: result.elapsedSecs.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final timeStr = minutes > 0 ? "${minutes}m ${seconds}s" : "${seconds}s";

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.check_circle,
                size: 48,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Transfer Successful",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    context,
                    Symbols.file_copy,
                    "Files Received",
                    result.totalFiles.toString(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryRow(
                    context,
                    Symbols.data_usage,
                    "Total Size",
                    FileSize.getSize(result.payloadSize),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryRow(
                    context,
                    Symbols.timer,
                    "Time Elapsed",
                    timeStr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => context.read<ReceiveCubit>().back(),
              icon: const Icon(Symbols.arrow_back),
              label: const Text("Done"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
