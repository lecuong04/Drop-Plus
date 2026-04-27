import "dart:ui" as ui;

import "package:file_picker/file_picker.dart";
import "package:file_sizes/file_sizes.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:pretty_qr_code/pretty_qr_code.dart";

import "../../../../../exts.dart";
import "../../../../../rust/progress.dart";
import "../../../../cubits/send_cubit.dart";

class SendReadyStateWidget extends StatelessWidget {
  final List<ProgressState> progresses;
  final (List<int>, String) ticket;
  final BigInt size;

  const SendReadyStateWidget({
    super.key,
    required this.ticket,
    required this.size,
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
            _HeaderSection(size: size),
            const SizedBox(height: 32),
            _QrCodeSection(ticket: ticket),
            const SizedBox(height: 32),
            _TransferCodeSection(ticketCode: ticket.$2),
            if (progresses.any((p) => p.phase is Phase_Uploading)) ...[
              const SizedBox(height: 32),
              _ActiveTransfersSection(progresses: progresses, size: size),
            ],
            const SizedBox(height: 24),
            const _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _ActiveTransfersSection extends StatelessWidget {
  final BigInt size;
  late final Map<BigInt, ProgressState> grouped;

  _ActiveTransfersSection({
    required List<ProgressState> progresses,
    required this.size,
  }) {
    grouped = progresses.fold<Map<BigInt, ProgressState>>({}, (map, progress) {
      final phase = progress.phase;
      if (phase is Phase_Uploading) {
        map[phase.connectionId] = progress;
      }
      return map;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${grouped.length} connected",
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
          final percent = entry.value.position.toDouble() / size.toDouble();

          return Card(
            key: ValueKey(connectionId),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Symbols.package, color: colorScheme.primary),
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
                      "${(percent * 100).toStringAsFixed(1)}%",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                subtitle: LinearProgressIndicator(
                  value: percent,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }),
      ],
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
            Symbols.check_circle,
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
  final (List<int>, String) ticket;

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
                    Icon(Symbols.download, size: 20),
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
      data: ticket.$2,
      decoration: const PrettyQrDecoration(
        background: Colors.white,
        shape: PrettyQrSmoothSymbol(roundFactor: 0.8),
      ),
    );
  }

  Future<ui.Image> _toImage() async {
    final qrImage = QrImage(
      QrCode.fromUint8List(
        data: Uint8List.fromList(ticket.$1),
        errorCorrectLevel: QrErrorCorrectLevel.M,
      ),
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
                  Symbols.content_copy,
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
                Symbols.chevron_right,
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
          icon: const Icon(Symbols.close),
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
