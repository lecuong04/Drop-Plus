import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "../../../cubits/settings_cubit.dart";
import "../../logs_screen.dart";

class SettingsView extends StatelessWidget {
  static const double maxWidth = 600;

  const SettingsView({super.key});

  Future<void> _pickDownloadDirectory(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final String? result = await FilePicker.getDirectoryPath(
      dialogTitle: "Select download folder",
      lockParentWindow: true,
    );
    if (result != null) {
      cubit.setDownloadFolder(result);
    }
  }

  Future<void> _showAddressSelection(BuildContext context) async {
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

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Network Addresses",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<SettingsCubit>().refresh(),
                            icon: const Icon(Symbols.refresh),
                            tooltip: "Refresh",
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _AddressOption(
                            title: "Auto selection",
                            subtitle: "Recommended (use all interfaces)",
                            icon: Symbols.magic_button,
                            isSelected:
                                state.addr == null || state.addr!.isEmpty,
                            onTap: () {
                              context.read<SettingsCubit>().clearAddr();
                              Navigator.pop(context);
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
                              return _AddressOption(
                                title: entry.value,
                                subtitle: entry.key,
                                icon: Symbols.lan,
                                isSelected: state.addr == entry.key,
                                onTap: () {
                                  context.read<SettingsCubit>().setAddress(
                                    entry.key,
                                  );
                                  Navigator.pop(context);
                                },
                              );
                            }),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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
                    maxWidth: SettingsView.maxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: "Transfer Settings",
                        icon: Symbols.swap_horiz,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildTransferCard(context, state),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: "Appearance",
                        icon: Symbols.palette,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      _buildAppearanceCard(context, state),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: "System & Support",
                        icon: Symbols.terminal,
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
              child: Icon(Symbols.folder_open, color: colorScheme.primary),
            ),
            title: const Text("Download Directory"),
            subtitle: Text(
              state.downloadFolder ?? "Not set",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => _pickDownloadDirectory(context),
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
              child: Icon(Symbols.lan, color: colorScheme.primary),
            ),
            title: const Text("Network Addresses"),
            subtitle: Text(
              state.addr == null || state.addr!.isEmpty
                  ? "Auto selection"
                  : state.addr!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => _showAddressSelection(context),
          ),
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
              child: Icon(Symbols.notifications, color: colorScheme.primary),
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
            icon: Symbols.settings_suggest,
            isSelected: state.themeMode == ThemeMode.system,
            onTap: () => cubit.setThemeMode(ThemeMode.system),
          ),
          const Divider(height: 1, indent: 72),
          _ThemeOption(
            title: "Light Mode",
            icon: Symbols.light_mode,
            isSelected: state.themeMode == ThemeMode.light,
            onTap: () => cubit.setThemeMode(ThemeMode.light),
          ),
          const Divider(height: 1, indent: 72),
          _ThemeOption(
            title: "Dark Mode",
            icon: Symbols.dark_mode,
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
              child: Icon(Symbols.history, color: colorScheme.tertiary),
            ),
            title: const Text("View Logs"),
            subtitle: const Text("Technical logs for debugging"),
            trailing: const Icon(Symbols.chevron_right, size: 20),
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
              child: Icon(Symbols.info, color: colorScheme.tertiary),
            ),
            title: const Text("About Drop Plus"),
            subtitle: const Text("Open source license and version info"),
            trailing: const Icon(Symbols.chevron_right, size: 20),
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

    return ListTile(
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
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.7) : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Symbols.check_circle, color: colorScheme.primary, size: 24)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          ? Icon(Symbols.check_circle, color: colorScheme.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }
}
