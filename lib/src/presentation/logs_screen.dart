import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";

import "../../rust/types.dart";
import "../cubits/tracing_cubit.dart";
import "../models/limited_queue.dart";

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String? _selectedLevel;
  final List<String> _levels = ["ERROR", "WARN", "INFO", "DEBUG", "TRACE"];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isFilterExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search logs...",
                  isDense: true,
                  visualDensity: VisualDensity(vertical: -3),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (_) => setState(() {}),
              )
            : const Text("System Logs"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Symbols.close : Symbols.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
            tooltip: _isSearching ? "Clear search" : "Search logs",
          ),
          IconButton(
            icon: const Icon(Symbols.delete_sweep),
            color: theme.colorScheme.error,
            onPressed: () => context.read<TracingCubit>().clear(),
            tooltip: "Clear logs",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<TracingCubit, LimitedQueue<LogEntry>>(
              builder: (context, logs) {
                var items = logs.items.reversed.toList();
                if (_selectedLevel != null) {
                  items = items
                      .where(
                        (log) =>
                            log.level.toUpperCase() ==
                            _selectedLevel!.toUpperCase(),
                      )
                      .toList();
                }
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  items = items.where((log) {
                    final message = log.data["message"]?.toLowerCase() ?? "";
                    final target = log.target.toLowerCase();
                    final data = log.data.values.join(" ").toLowerCase();
                    return message.contains(query) ||
                        target.contains(query) ||
                        data.contains(query);
                  }).toList();
                }
                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final log = items[index];
                    return _LogEntryWidget(log: log, key: ValueKey(log.time));
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFilterExpanded) ...[
            FilterChip(
              label: const Text("ALL"),
              selected: _selectedLevel == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedLevel = null;
                    _isFilterExpanded = false;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            ..._levels.map((level) {
              final isSelected = _selectedLevel == level;
              final levelColor = _getLevelColor(level, colorScheme);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilterChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLevel = selected ? level : null;
                      _isFilterExpanded = false;
                    });
                  },
                  selectedColor: levelColor.withValues(alpha: 0.2),
                  checkmarkColor: levelColor,
                  labelStyle: TextStyle(
                    color: isSelected ? levelColor : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              );
            }),
          ],
          FloatingActionButton(
            heroTag: "filter_toggle",
            onPressed: () =>
                setState(() => _isFilterExpanded = !_isFilterExpanded),
            tooltip: "Filter logs",
            child: Badge(
              label: _selectedLevel != null ? Text(_selectedLevel![0]) : null,
              isLabelVisible: _selectedLevel != null && !_isFilterExpanded,
              child: Icon(
                _isFilterExpanded ? Symbols.close : Symbols.filter_list,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.terminal,
            size: 48,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? "No logs matching \"${_searchController.text}\""
                : (_selectedLevel == null
                      ? "Log buffer is empty"
                      : "No $_selectedLevel logs found"),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level, ColorScheme colorScheme) {
    switch (level.toUpperCase()) {
      case "ERROR":
        return colorScheme.error;
      case "WARN":
        return Colors.orange;
      case "INFO":
        return colorScheme.primary;
      case "DEBUG":
        return colorScheme.secondary;
      case "TRACE":
        return colorScheme.outline;
      default:
        return colorScheme.onSurface;
    }
  }
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry log;

  const _LogEntryWidget({required this.log, super.key});

  Color _getLevelColor(String level, ColorScheme colorScheme) {
    switch (level.toUpperCase()) {
      case "ERROR":
        return colorScheme.error;
      case "WARN":
        return Colors.orange;
      case "INFO":
        return colorScheme.primary;
      case "DEBUG":
        return colorScheme.secondary;
      case "TRACE":
        return colorScheme.outline;
      default:
        return colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelColor = _getLevelColor(log.level, colorScheme);

    final time = DateTime.fromMillisecondsSinceEpoch(log.time.toInt());
    final timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}";

    final message = log.data["message"] ?? "";
    final extraData = Map<String, String>.from(log.data)..remove("message");

    return InkWell(
      onTap: () {
        // Optional: show details in a dialog or expand
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              timeStr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: Text(
                log.level.padRight(5),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: levelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.3,
                        color: log.level == "ERROR" ? colorScheme.error : null,
                      ),
                    ),
                  if (extraData.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: extraData.entries.map((e) {
                          return Text(
                            "${e.key}=${e.value}",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      log.target,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
