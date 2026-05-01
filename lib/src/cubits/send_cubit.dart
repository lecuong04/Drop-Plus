import "dart:async";

import "../../rust/progresses.dart";
import "../../rust/types.dart";
import "../services/transfer_service.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";

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

final class SendReady extends SendState {
  final String ticket;
  final List<ProgressState> progresses;
  final BigInt size;

  SendReady({
    required this.ticket,
    required this.size,
    this.progresses = const [],
  });

  SendReady copyWith({
    BigInt? size,
    String? ticket,
    List<ProgressState>? progresses,
  }) {
    return SendReady(
      ticket: ticket ?? this.ticket,
      size: size ?? this.size,
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
      }
    });
    resultSub = resultSink.stream.listen((result) {
      if (result is SendResult_Ok) {
        emit(SendReady(ticket: result.ticket, size: result.size));
      } else {
        emit(const SendInitial(isError: true));
      }
    });
  }

  Future<void> cancel() async {
    final curState = state;
    if (curState is SendReady) {
      try {
        await _service.cancelSend(curState.ticket);
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
