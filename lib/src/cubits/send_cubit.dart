import "dart:async";
import "dart:convert";

import "../../rust/progress.dart";
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
  late final (List<int>, String) ticket;
  final List<ProgressState> progresses;
  final BigInt size;

  SendReady({
    required List<int> ticket,
    required this.size,
    this.progresses = const [],
  }) {
    this.ticket = (ticket, base64Encode(ticket));
  }

  SendReady copyWith({
    BigInt? size,
    List<int>? ticket,
    List<ProgressState>? progresses,
  }) {
    return SendReady(
      ticket: ticket ?? this.ticket.$1,
      size: size ?? this.size,
      progresses: progresses ?? this.progresses,
    );
  }
}

class SendCubit extends Cubit<SendState> {
  final TransferService _service;

  SendCubit(this._service) : super(const SendInitial());

  void startSend(List<String> paths) {
    final progressSink = RustStreamSink<List<ProgressState>>();
    final resultSink = RustStreamSink<SendResult>();

    StreamSubscription? progressSub;
    StreamSubscription? resultSub;

    _service
        .send(paths: paths, stream: progressSink, result: resultSink)
        .whenComplete(() async {
          await progressSub?.cancel();
          await resultSub?.cancel();
        });
    progressSub = progressSink.stream.listen((e) {
      if (e.any((p) => p.phase is Phase_Importing)) {
        emit(SendImporting(progresses: e));
      } else if (e.any((p) => p.phase is Phase_Uploading)) {
        emit((state as SendReady).copyWith(progresses: e));
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
        await _service.cancelSend(curState.ticket.$1);
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
