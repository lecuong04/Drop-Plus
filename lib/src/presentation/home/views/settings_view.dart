import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../../../rust/types.dart";
import "../../../cubits/settings_cubit.dart";
import "../../logs_screen.dart";

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final bool _isSupportNetwork = {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }.contains(defaultTargetPlatform);

  static const double maxWidth = 600;

  bool _isPick = false;

  Future<void> _pickDownloadDirectory() async {
    setState(() => _isPick = true);
    final cubit = context.read<SettingsCubit>();
    final String? result = await FilePicker.getDirectoryPath(
      dialogTitle: "Select download folder",
      lockParentWindow: true,
    );
    if (result != null) {
      cubit.setDownloadFolder(result);
    }
    setState(() => _isPick = false);
  }

  Future<void> _showPortSelection() async {
    final cubit = context.read<SettingsCubit>();
    final controller = TextEditingController(text: cubit.state.port.toString());
    final res = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Port number",
              hintText: "0 for random port",
              helperText: "Range: 0 - 65535",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final port = int.tryParse(controller.text);
                if (port != null && port >= 0 && port <= 65535) {
                  Navigator.pop(context, port);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (res != null) {
      cubit.setPort(res);
    }
  }

  Future<void> _showRelaySelection() async {
    final cubit = context.read<SettingsCubit>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text("Disabled"),
                    subtitle: const Text("Direct connection only"),
                    trailing: state.relay.maybeMap(
                      disabled: (_) =>
                          Icon(Icons.check_circle, color: colorScheme.primary),
                      orElse: () => null,
                    ),
                    onTap: () {
                      cubit.setRelay(const RelayModeOption.disabled());
                      Navigator.pop(context);
                    },
                  ),
                ),
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text("Default"),
                    subtitle: const Text("Use iroh.network (N0)"),
                    trailing: state.relay.maybeMap(
                      n0: (_) =>
                          Icon(Icons.check_circle, color: colorScheme.primary),
                      orElse: () => null,
                    ),
                    onTap: () {
                      cubit.setRelay(const RelayModeOption.n0());
                      Navigator.pop(context);
                    },
                  ),
                ),
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text("Custom"),
                    subtitle: Text(
                      state.relay.maybeMap(
                        custom: (c) => c.url,
                        orElse: () => "Enter custom relay URL",
                      ),
                    ),
                    trailing: state.relay.maybeMap(
                      custom: (_) =>
                          Icon(Icons.check_circle, color: colorScheme.primary),
                      orElse: () => null,
                    ),
                    onTap: () async {
                      final controller = TextEditingController(
                        text: state.relay.maybeMap(
                          custom: (c) => c.url,
                          orElse: () => "",
                        ),
                      );
                      final url = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: "Relay URL",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, controller.text),
                                child: const Text("Save"),
                              ),
                            ],
                          );
                        },
                      );
                      if (url != null && url.isNotEmpty) {
                        cubit.setRelay(RelayModeOption.custom(url: url));
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddressSelection() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Card(
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.inbox, color: colorScheme.primary),
                        ),
                        title: const Text("Port"),
                        subtitle: Text(
                          state.port == 0
                              ? "Random port"
                              : state.port.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: _showPortSelection,
                      ),
                    ),
                    const Divider(height: 1, indent: 72),
                    _AddressOption(
                      title: "Auto selection",
                      subtitle: "Recommended (use all interfaces)",
                      icon: Icons.smart_button,
                      isSelected:
                          state.ipv4Addr == null && state.ipv6Addr == null,
                      onTap: () {
                        context.read<SettingsCubit>().clearAddrs();
                      },
                    ),
                    if (state.availableAddrs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          "Manual Selection",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...state.availableAddrs.entries.map((entry) {
                        final isIpv6 = entry.key.contains(":");
                        final isSelected = isIpv6
                            ? state.ipv6Addr == entry.key
                            : state.ipv4Addr == entry.key;

                        return _AddressOption(
                          title: entry.value,
                          subtitle: entry.key,
                          icon: Icons.lan,
                          isSelected: isSelected,
                          onTap: () {
                            final cubit = context.read<SettingsCubit>();
                            if (isIpv6) {
                              if (state.ipv6Addr == entry.key) {
                                cubit.removeAddrV6();
                              } else {
                                cubit.setAddrV6(entry.key);
                              }
                            } else {
                              if (state.ipv4Addr == entry.key) {
                                cubit.removeAddrV4();
                              } else {
                                cubit.setAddrV4(entry.key);
                              }
                            }
                          },
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _SettingsViewState.maxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: "Transfer Settings",
                        icon: Icons.swap_horiz,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildTransferCard(context, state),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: "Appearance",
                        icon: Icons.palette,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      _buildAppearanceCard(context, state),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: "System & Support",
                        icon: Icons.terminal,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(height: 16),
                      _buildSystemCard(context),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          "Drop Plus v1.0.0",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransferCard(BuildContext context, SettingsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.folder_open, color: colorScheme.primary),
            ),
            title: const Text("Download Directory"),
            subtitle: Text(
              state.downloadFolder ?? "Not set",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: !_isPick ? _pickDownloadDirectory : null,
          ),
          if (_isSupportNetwork) ...[
            const Divider(height: 1, indent: 72),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lan, color: colorScheme.primary),
              ),
              title: const Text("Network Configurations"),
              subtitle: Text(
                () {
                  final String portSuffix = state.port == 0
                      ? " (Random port)"
                      : ":${state.port}";
                  if (state.ipv4Addr == null && state.ipv6Addr == null) {
                    return "Auto selection";
                  }
                  final List<String> addrs = [];
                  if (state.ipv4Addr != null) {
                    addrs.add("${state.ipv4Addr}$portSuffix");
                  }
                  if (state.ipv6Addr != null) {
                    addrs.add("[${state.ipv6Addr}]$portSuffix");
                  }
                  return addrs.join("\n");
                }(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _showAddressSelection,
            ),
            const Divider(height: 1, indent: 72),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.share, color: colorScheme.primary),
              ),
              title: const Text("Relay Mode"),
              subtitle: Text(
                state.relay.maybeMap(
                  disabled: (_) => "Disabled",
                  n0: (_) => "Default (N0)",
                  custom: (c) => "Custom: ${c.url}",
                  orElse: () => "Unknown",
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _showRelaySelection,
            ),
          ],
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications, color: colorScheme.primary),
            ),
            title: const Text("Notifications"),
            subtitle: const Text("Show transfer progress in system tray"),
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, SettingsState state) {
    final cubit = context.read<SettingsCubit>();
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _ThemeOption(
            title: "System Default",
            icon: Icons.settings_suggest,
            isSelected: state.themeMode == ThemeMode.system,
            onTap: () => cubit.setThemeMode(ThemeMode.system),
          ),
          const Divider(height: 1, indent: 72),
          _ThemeOption(
            title: "Light Mode",
            icon: Icons.light_mode,
            isSelected: state.themeMode == ThemeMode.light,
            onTap: () => cubit.setThemeMode(ThemeMode.light),
          ),
          const Divider(height: 1, indent: 72),
          _ThemeOption(
            title: "Dark Mode",
            icon: Icons.dark_mode,
            isSelected: state.themeMode == ThemeMode.dark,
            onTap: () => cubit.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.history, color: colorScheme.tertiary),
            ),
            title: const Text("View Logs"),
            subtitle: const Text("Technical logs for debugging"),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.info, color: colorScheme.tertiary),
            ),
            title: const Text("About Drop Plus"),
            subtitle: const Text("Open source license and version info"),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Drop Plus",
                applicationVersion: "1.0.0",
                applicationIcon: const FlutterLogo(size: 40),
                applicationLegalese: "© 2024 Drop Plus Contributors",
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddressOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : null,
            color: isSelected ? colorScheme.primary : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.7)
                : null,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: colorScheme.primary, size: 24)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : null,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}
