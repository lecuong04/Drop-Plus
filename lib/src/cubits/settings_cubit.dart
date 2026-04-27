import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// The state of the [SettingsCubit].
final class SettingsState {
  /// The current theme mode.
  final ThemeMode themeMode;

  /// The current download folder path.
  final String? downloadFolder;

  /// Creates a new [SettingsState].
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.downloadFolder,
  });

  /// Creates a copy of this [SettingsState] with the given fields replaced by the new values.
  SettingsState copyWith({
    ThemeMode? themeMode,
    String? downloadFolder,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      downloadFolder: downloadFolder ?? this.downloadFolder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          downloadFolder == other.downloadFolder;

  @override
  int get hashCode => themeMode.hashCode ^ downloadFolder.hashCode;
}

/// A [Cubit] that manages the application settings.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates a new [SettingsCubit].
  SettingsCubit() : super(const SettingsState());

  /// Sets the theme mode.
  void setThemeMode(ThemeMode themeMode) {
    emit(state.copyWith(themeMode: themeMode));
  }

  /// Sets the download folder path.
  void setDownloadFolder(String? downloadFolder) {
    emit(state.copyWith(downloadFolder: downloadFolder));
  }
}
