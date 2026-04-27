import "../../rust/ffi.dart" as ffi;
import "../../rust/progress.dart";
import "../../rust/types.dart";
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";

class TransferService {
  Future<void> send({
    required List<String> paths,
    required RustStreamSink<List<ProgressState>> stream,
    required RustStreamSink<SendResult> result,
  }) async {
    await ffi.send(paths: paths, stream: stream, result: result);
  }

  Future<void> cancelSend(List<int> ticket) async {
    await ffi.cancelSend(ticket: ticket);
  }

  Future<void> receive({
    String? relay,
    required List<int> ticket,
    required String downloadDir,
    required RustStreamSink<List<ProgressState>> stream,
    required RustStreamSink<ReceiveResult> result,
  }) async {
    await ffi.receive(
      relay: relay,
      ticket: ticket,
      downloadDir: downloadDir,
      stream: stream,
      result: result,
    );
  }

  Future<void> acceptReceive(List<int> ticket) async {
    await ffi.acceptReceive(ticket: ticket);
  }

  Future<void> rejectReceive(List<int> ticket) async {
    await ffi.rejectReceive(ticket: ticket);
  }

  Future<void> cancelReceive(List<int> ticket) async {
    await ffi.cancelReceive(ticket: ticket);
  }
}
