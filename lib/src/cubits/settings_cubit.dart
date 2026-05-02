import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../rust/types.dart";
import "../services/other_service.dart";

final class SettingsState {
  final ThemeMode themeMode;
  final String? downloadFolder;
  final String? ipv4Addr;
  final String? ipv6Addr;
  final int port;
  final Map<String, String> availableAddrs;
  final RelayModeOption relay;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.downloadFolder,
    this.ipv4Addr,
    this.ipv6Addr,
    this.port = 0,
    this.availableAddrs = const {},
    this.relay = const RelayModeOption.disabled(),
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? downloadFolder,
    String? ipv4Addr,
    String? ipv6Addr,
    int? port,
    Map<String, String>? availableAddrs,
    RelayModeOption? relay,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      downloadFolder: downloadFolder ?? this.downloadFolder,
      ipv4Addr: ipv4Addr ?? this.ipv4Addr,
      ipv6Addr: ipv6Addr ?? this.ipv6Addr,
      port: port ?? this.port,
      availableAddrs: availableAddrs ?? this.availableAddrs,
      relay: relay ?? this.relay,
    );
  }

  SettingsState clearAddrs() {
    return SettingsState(
      themeMode: themeMode,
      port: port,
      relay: relay,
      availableAddrs: availableAddrs,
      downloadFolder: downloadFolder,
    );
  }

  SettingsState removeAddrV4() {
    return SettingsState(
      themeMode: themeMode,
      port: port,
      relay: relay,
      ipv6Addr: ipv6Addr,
      availableAddrs: availableAddrs,
      downloadFolder: downloadFolder,
    );
  }

  SettingsState removeAddrV6() {
    return SettingsState(
      themeMode: themeMode,
      port: port,
      relay: relay,
      ipv4Addr: ipv4Addr,
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
          port == other.port &&
          relay == other.relay &&
          downloadFolder == other.downloadFolder &&
          ipv4Addr == other.ipv4Addr &&
          ipv6Addr == other.ipv6Addr &&
          availableAddrs == other.availableAddrs;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      port.hashCode ^
      relay.hashCode ^
      downloadFolder.hashCode ^
      ipv4Addr.hashCode ^
      ipv6Addr.hashCode ^
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
      var curState = state;
      if (state.ipv4Addr != null &&
          !availableAddrs.keys.any((e) => e == state.ipv4Addr)) {
        onConnectivityLost?.call(state.ipv4Addr!);
        curState = curState.removeAddrV4();
      }
      if (state.ipv6Addr != null &&
          !availableAddrs.keys.any((e) => e == state.ipv6Addr)) {
        onConnectivityLost?.call(state.ipv6Addr!);
        curState = curState.removeAddrV6();
      }
      emit(
        curState.copyWith(
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

  void setPort(int port) {
    emit(state.copyWith(port: port));
  }

  void setRelay(RelayModeOption relay) {
    emit(state.copyWith(relay: relay));
  }

  void setDownloadFolder(String? downloadFolder) {
    emit(state.copyWith(downloadFolder: downloadFolder));
  }

  void setAddrV4(String addr) {
    emit(state.copyWith(ipv4Addr: addr));
  }

  void setAddrV6(String addr) {
    emit(state.copyWith(ipv6Addr: addr));
  }

  void removeAddrV4() {
    emit(state.removeAddrV4());
  }

  void removeAddrV6() {
    emit(state.removeAddrV6());
  }

  void clearAddrs() {
    emit(state.clearAddrs());
  }
}
