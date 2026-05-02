import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";

import "../../rust/progresses.dart";
import "../../rust/types.dart";
import "../services/transfer_service.dart";

sealed class SendState {
  const SendState();
}

final class SendInitial extends SendState {
  final bool isError;

  const SendInitial({this.isError = false});
}

final class SendImporting extends SendState {
  final List<ProgressState> progresses;
  const SendImporting({this.progresses = const []});
}

final class SendConnecting extends SendState {
  const SendConnecting();
}

final class SendReady extends SendState {
  final SendResult_Ok result;
  final List<ProgressState> progresses;

  SendReady({required this.result, this.progresses = const []});

  SendReady copyWith({SendResult_Ok? result, List<ProgressState>? progresses}) {
    return SendReady(
      result: result ?? this.result,
      progresses: progresses ?? this.progresses,
    );
  }
}

class SendCubit extends Cubit<SendState> {
  final TransferService _service;

  SendCubit(this._service) : super(const SendInitial());

  void startSend(
    List<String> paths, {
    String? ipv4Addr,
    String? ipv6Addr,
    int port = 0,
    RelayModeOption relay = const RelayModeOption.disabled(),
  }) {
    final progressSink = RustStreamSink<List<ProgressState>>();
    final resultSink = RustStreamSink<SendResult>();

    StreamSubscription? progressSub;
    StreamSubscription? resultSub;

    _service
        .send(
          paths: paths,
          ipv4Addr: ipv4Addr != null ? "$ipv4Addr:$port" : null,
          ipv6Addr: ipv6Addr != null ? "[$ipv6Addr]:$port" : null,
          relay: relay,
          stream: progressSink,
          result: resultSink,
        )
        .whenComplete(() async {
          await progressSub?.cancel();
          await resultSub?.cancel();
        });
    progressSub = progressSink.stream.listen((e) {
      if (e.any((p) => p.phase is Phase_Importing)) {
        emit(SendImporting(progresses: e));
      } else if (e.any((p) => p.phase is Phase_Uploading)) {
        final curState = (state as SendReady);

        final progresses = curState.progresses.where(
          (p) => !e
              .map((e) => (e.phase as Phase_Uploading).endpoint)
              .contains((p.phase as Phase_Uploading).endpoint),
        );
        emit((state as SendReady).copyWith(progresses: [...progresses, ...e]));
      } else if (e.any((p) => p.phase is Phase_Connecting)) {
        emit(const SendConnecting());
      }
    });
    resultSub = resultSink.stream.listen((result) {
      if (result is SendResult_Ok) {
        emit(SendReady(result: result));
      } else {
        emit(const SendInitial(isError: true));
      }
    });
  }

  Future<void> cancel() async {
    final curState = state;
    if (curState is SendReady) {
      try {
        await _service.cancelSend(curState.result.ticket);
        emit(const SendInitial());
      } catch (_) {
        emit(const SendInitial(isError: true));
        return;
      }
    }
  }

  void clearError() {
    final curState = state;
    if (curState is SendInitial && curState.isError) {
      emit(const SendInitial());
    }
  }
}
