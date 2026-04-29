import "dart:async";
import "dart:convert";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";
import "../../rust/progress.dart";
import "../../rust/types.dart";
import "../services/transfer_service.dart";

sealed class ReceiveState {
  const ReceiveState();
}

final class ReceiveInitial extends ReceiveState {
  final bool isError;

  const ReceiveInitial({this.isError = false});
}

final class ReceiveConnecting extends ReceiveState {
  final List<int> ticket;

  const ReceiveConnecting(this.ticket);
}

final class ReceivePending extends ReceiveState {
  final bool isWaiting;
  final List<int> ticket;
  final List<BlobInfo> files;

  const ReceivePending({
    required this.ticket,
    this.files = const [],
    this.isWaiting = false,
  });
}

final class ReceiveValidating extends ReceiveState {
  const ReceiveValidating();
}

final class ReceiveTransferring extends ReceiveState {
  final List<int> ticket;
  final List<ProgressState> progresses;

  const ReceiveTransferring({required this.progresses, required this.ticket});
}

final class ReceiveExporting extends ReceiveState {
  final List<ProgressState> progresses;

  const ReceiveExporting(this.progresses);
}

final class ReceiveSuccess extends ReceiveState {
  final ReceiveResult_Ok result;

  const ReceiveSuccess(this.result);
}

class ReceiveCubit extends Cubit<ReceiveState> {
  final TransferService _service;

  ReceiveCubit(this._service) : super(const ReceiveInitial());

  Future<void> startReceive(String downloadDir, String ticket) async {
    final data = base64Decode(ticket);
    final progressSink = RustStreamSink<List<ProgressState>>();
    final resultSink = RustStreamSink<ReceiveResult>();

    StreamSubscription? progressSub;
    StreamSubscription? resultSub;

    _service
        .receive(
          ticket: data,
          downloadDir: downloadDir,
          stream: progressSink,
          result: resultSink,
        )
        .whenComplete(() async {
          await progressSub?.cancel();
          await resultSub?.cancel();
        });
    progressSub = progressSink.stream.listen((progresses) {
      if (progresses.any((e) => e.phase is Phase_Pending)) {
        emit(ReceivePending(ticket: data, isWaiting: true));
      } else if (progresses.any((e) => e.phase is Phase_Connecting)) {
        emit(ReceiveConnecting(data));
      } else if (progresses.any((e) => e.phase is Phase_Validating)) {
        emit(const ReceiveValidating());
      } else if (progresses.any((e) => e.phase is Phase_Downloading)) {
        emit(ReceiveTransferring(progresses: progresses, ticket: data));
      } else if (progresses.any((e) => e.phase is Phase_Exporting)) {
        emit(ReceiveExporting(progresses));
      }
    });
    resultSub = resultSink.stream.listen((result) {
      if (result is ReceiveResult_Ok) {
        emit(ReceiveSuccess(result));
      } else if (result is ReceiveResult_Pending) {
        emit(ReceivePending(files: result.files, ticket: data));
      } else {
        emit(const ReceiveInitial(isError: true));
      }
    });
  }

  Future<void> reject() async {
    final curState = state;
    switch (curState) {
      case ReceivePending():
        {
          try {
            await _service.rejectReceive(curState.ticket);
            emit(const ReceiveInitial());
          } catch (_) {
            emit(const ReceiveInitial(isError: true));
          }
          break;
        }
      default:
        {}
    }
  }

  Future<void> accept() async {
    final curState = state;
    switch (curState) {
      case ReceivePending():
        {
          try {
            await _service.acceptReceive(curState.ticket);
          } catch (_) {
            emit(const ReceiveInitial(isError: true));
          }
          break;
        }
      default:
        {}
    }
  }

  Future<void> cancel() async {
    final curState = state;
    switch (curState) {
      case ReceiveConnecting():
        {
          try {
            await _service.cancelReceive(curState.ticket);
            emit(const ReceiveInitial());
          } catch (_) {
            emit(const ReceiveInitial(isError: true));
          }
          break;
        }
      case ReceiveTransferring():
        {
          try {
            await _service.cancelReceive(curState.ticket);
            emit(const ReceiveInitial());
          } catch (_) {
            emit(const ReceiveInitial(isError: true));
          }
          break;
        }
      default:
        {}
    }
  }

  void back() {
    final curState = state;
    if (curState is ReceiveSuccess) {
      emit(const ReceiveInitial());
    }
  }

  void clearError() {
    final curState = state;
    if (curState is ReceiveInitial && curState.isError) {
      emit(const ReceiveInitial());
    }
  }
}
