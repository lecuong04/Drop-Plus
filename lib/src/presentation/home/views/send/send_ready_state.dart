import "dart:ui" as ui;

import "package:file_picker/file_picker.dart";
import "package:file_sizes/file_sizes.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:pretty_qr_code/pretty_qr_code.dart";

import "../../../../../exts.dart";
import "../../../../../rust/progresses.dart";
import "../../../../../rust/types.dart";
import "../../../../cubits/send_cubit.dart";

class SendReadyStateWidget extends StatelessWidget {
  final SendResult_Ok result;
  final List<ProgressState> progresses;

  const SendReadyStateWidget({
    super.key,
    required this.result,
    required this.progresses,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderSection(size: result.size),
            const SizedBox(height: 32),
            _QrCodeSection(ticket: result.ticket),
            const SizedBox(height: 32),
            _TransferCodeSection(ticketCode: result.ticket),
            _ConnectionAddressesSection(addrs: result.addrs),
            if (progresses.any((p) => p.phase is Phase_Uploading))
              _ActiveTransfersSection(
                progresses: progresses,
                size: result.size,
              ),
            const SizedBox(height: 24),
            const _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _ConnectionAddressesSection extends StatelessWidget {
  final List<String> addrs;

  const _ConnectionAddressesSection({required this.addrs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Connection Options",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: addrs.map((addr) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      addr,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActiveTransfersSection extends StatefulWidget {
  final List<ProgressState> progresses;
  final BigInt size;

  const _ActiveTransfersSection({required this.progresses, required this.size});

  @override
  State<_ActiveTransfersSection> createState() =>
      _ActiveTransfersSectionState();
}

class _ActiveTransfersSectionState extends State<_ActiveTransfersSection> {
  final Set<String> _dismissedIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final grouped = widget.progresses.fold<Map<String, ProgressState>>({}, (
      map,
      progress,
    ) {
      final phase = progress.phase;
      if (phase is Phase_Uploading && !_dismissedIds.contains(phase.endpoint)) {
        map[phase.endpoint] = progress;
      }
      return map;
    });

    if (grouped.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Active Transfers",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${grouped.values.where((p) => !(p.phase as Phase_Uploading).isCompleted && !(p.phase as Phase_Uploading).isFailed).length} active",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...grouped.entries.map((entry) {
            final connectionId = entry.key;
            final progress = entry.value;
            final phase = progress.phase as Phase_Uploading;

            final percent =
                progress.position.toDouble() / widget.size.toDouble();
            final statusText = "${(percent * 100).toStringAsFixed(1)}%";

            var statusColor = colorScheme.primary;
            var statusIcon = Icons.sync;

            if (phase.isCompleted) {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (phase.isFailed) {
              statusColor = colorScheme.error;
              statusIcon = Icons.error;
            }

            return Dismissible(
              direction: phase.isCompleted || phase.isFailed
                  ? DismissDirection.horizontal
                  : DismissDirection.none,
              key: ValueKey(connectionId),
              onDismissed: (_) =>
                  setState(() => _dismissedIds.add(connectionId)),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#$connectionId",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: phase.isCompleted ? 1.0 : percent,
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final BigInt size;

  const _HeaderSection({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Ready to Share",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            FileSize.getSize(size),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Scan the QR code or copy the transfer code to start receiving on another device.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _QrCodeSection extends StatelessWidget {
  final String ticket;

  const _QrCodeSection({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLargeQr(context),
          onLongPress: () => _saveQrCode(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
            child: _qrView(theme, key: const ValueKey("qr_main")),
          ),
        ),
      ),
    );
  }

  void _showLargeQr(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Scan to Receive",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 400,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _qrView(theme, key: const ValueKey("qr_dialog")),
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
                  _saveQrCode(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text("Save Image"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveQrCode(BuildContext context) async {
    try {
      final image = await _toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final path = await FilePicker.saveFile(
        dialogTitle: "Save QR Code",
        lockParentWindow: true,
        fileName: "qr_code.png",
        type: FileType.image,
        bytes: pngBytes,
      );

      if (path != null && context.mounted) {
        context.showSuccessSnackBar("QR Code saved successfully");
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar("Failed to save QR Code: $e");
      }
    }
  }

  Widget _qrView(ThemeData theme, {Key? key}) {
    return PrettyQrView.data(
      key: key,
      data: ticket,
      decoration: const PrettyQrDecoration(
        background: Colors.white,
        shape: PrettyQrSmoothSymbol(roundFactor: 0.8),
      ),
    );
  }

  Future<ui.Image> _toImage() async {
    final qrImage = QrImage(
      QrCode.fromData(data: ticket, errorCorrectLevel: QrErrorCorrectLevel.M),
    );
    return await qrImage.toImage(
      size: 512,
      decoration: const PrettyQrDecoration(
        background: Colors.white,
        shape: PrettyQrSmoothSymbol(roundFactor: 0.8),
      ),
    );
  }
}

class _TransferCodeSection extends StatelessWidget {
  final String ticketCode;

  const _TransferCodeSection({required this.ticketCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.content_copy,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Transfer Code",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tap to copy to clipboard",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: ticketCode));
    context.showSuccessSnackBar("Code copied to clipboard");
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextButton.icon(
          onPressed: context.read<SendCubit>().cancel,
          icon: const Icon(Icons.close),
          label: const Text("Cancel Transfer"),
          style: TextButton.styleFrom(
            iconColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
