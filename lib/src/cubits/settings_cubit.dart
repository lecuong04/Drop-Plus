import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../services/other_service.dart";

final class SettingsState {
  final ThemeMode themeMode;
  final String? downloadFolder;
  final String? addr;
  final Map<String, String> availableAddrs;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.downloadFolder,
    this.addr,
    this.availableAddrs = const {},
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? downloadFolder,
    String? addr,
    Map<String, String>? availableAddrs,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      downloadFolder: downloadFolder ?? this.downloadFolder,
      addr: addr ?? this.addr,
      availableAddrs: availableAddrs ?? this.availableAddrs,
    );
  }

  SettingsState clearAddr() {
    return SettingsState(
      themeMode: themeMode,
      availableAddrs: availableAddrs,
      downloadFolder: downloadFolder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          downloadFolder == other.downloadFolder &&
          addr == other.addr &&
          availableAddrs == other.availableAddrs;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      downloadFolder.hashCode ^
      addr.hashCode ^
      availableAddrs.hashCode;
}

class SettingsCubit extends Cubit<SettingsState> {
  late final StreamSubscription _subscription;

  final OtherService _service;
  final void Function(String addr)? onConnectivityLost;

  SettingsCubit(this._service, {this.onConnectivityLost})
    : super(const SettingsState()) {
    _service.getAddrs().then((addrs) {
      emit(
        state.copyWith(
          availableAddrs: Map.fromEntries(
            addrs.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
          ),
        ),
      );
    });
    _subscription = Connectivity().onConnectivityChanged.listen((e) async {
      final availableAddrs = await _service.getAddrs();
      if (state.addr != null &&
          !availableAddrs.keys.any((e) => e == state.addr)) {
        onConnectivityLost?.call(state.addr!);
        emit(state.clearAddr());
      }
      emit(
        state.copyWith(
          availableAddrs: Map.fromEntries(
            availableAddrs.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value)),
          ),
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  void setThemeMode(ThemeMode themeMode) {
    emit(state.copyWith(themeMode: themeMode));
  }

  void setDownloadFolder(String? downloadFolder) {
    emit(state.copyWith(downloadFolder: downloadFolder));
  }

  void setAddress(String addr) {
    emit(state.copyWith(addr: addr));
  }

  void clearAddr() {
    emit(state.clearAddr());
  }

  Future<void> refresh() async {
    final availableAddrs = await _service.getAddrs();
    emit(
      state.copyWith(
        availableAddrs: Map.fromEntries(
          availableAddrs.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value)),
        ),
      ),
    );
  }
}
