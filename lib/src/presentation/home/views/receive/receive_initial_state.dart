import "dart:convert";

import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:mobile_scanner/mobile_scanner.dart";

import "../../../../../exts.dart";
import "../../../../cubits/receive_cubit.dart";
import "../../../../cubits/settings_cubit.dart";
import "../../../../services/other_service.dart";

class ReceiveInitialStateWidget extends StatefulWidget {
  const ReceiveInitialStateWidget({super.key});

  @override
  State<ReceiveInitialStateWidget> createState() =>
      _ReceiveInitialStateWidgetState();
}

class _ReceiveInitialStateWidgetState extends State<ReceiveInitialStateWidget> {
  final bool _isSupportScanner = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.iOS,
  }.contains(defaultTargetPlatform);
  final TextEditingController _ticketController = TextEditingController();

  bool _isPick = false;

  String? _downloadDir;

  @override
  void initState() {
    super.initState();
    _downloadDir = context.read<SettingsCubit>().state.downloadFolder;
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  void _handlePickDir() async {
    final res = await FilePicker.getDirectoryPath(
      dialogTitle: "Select download folder",
      lockParentWindow: true,
    );
    if (res != null) {
      setState(() => _downloadDir = res);
    }
  }

  void _handleResetDir() {
    setState(() {
      _downloadDir = context.read<SettingsCubit>().state.downloadFolder;
    });
  }

  void _handleScanQR() async {
    if (_isSupportScanner) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Scan QR Code"),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      Navigator.pop(context, code);
                    }
                  }
                },
              ),
            ),
          );
        },
      );
      if (result != null) {
        setState(() => _ticketController.text = result);
      }
    } else {
      setState(() => _isPick = true);
      try {
        final res = await FilePicker.pickFiles(
          lockParentWindow: true,
          allowMultiple: false,
          type: FileType.image,
        );
        if (res != null && res.count != 0 && mounted) {
          try {
            final qr = (await context.read<OtherService>().qrReader(
              await res.xFiles.first.readAsBytes(),
            ));
            setState(() => _ticketController.text = utf8.decode(qr));
          } catch (e) {
            if (mounted) {
              context.showInfoSnackBar("No QR code found in the image");
            }
          }
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar("Error reading QR code: $e");
        }
      } finally {
        if (mounted) setState(() => _isPick = false);
      }
    }
  }

  void _handleReceive() {
    if (_downloadDir != null && _ticketController.text.isNotEmpty) {
      context.read<ReceiveCubit>().startReceive(
        _downloadDir!,
        _ticketController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultDownloadFolder = context
        .watch<SettingsCubit>()
        .state
        .downloadFolder;

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.download_for_offline,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Receive Files",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter a transfer code or scan a QR code to start receiving files.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ticketController,
              decoration: InputDecoration(
                labelText: "Transfer Code",
                hintText: "Enter the code here",
                prefixIcon: const Icon(Symbols.vpn_key),
                suffixIcon: IconButton(
                  icon: const Icon(Symbols.qr_code_scanner),
                  onPressed: !_isPick ? _handleScanQR : null,
                  tooltip: "Scan QR Code",
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Material(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _handlePickDir,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Symbols.folder_open,
                          size: 20,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Saving to",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _downloadDir ?? "Select destination",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: _downloadDir != null
                                    ? FontWeight.bold
                                    : null,
                                color: _downloadDir == null
                                    ? colorScheme.error
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_downloadDir != defaultDownloadFolder)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _handleResetDir,
                          icon: const Icon(Symbols.restart_alt, size: 20),
                          tooltip: "Reset to default",
                        ),
                      const Icon(Symbols.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed:
                  (_downloadDir != null && _ticketController.text.isNotEmpty)
                  ? _handleReceive
                  : null,
              icon: const Icon(Symbols.download),
              label: const Text("Receive Now"),
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
}
