import "package:flutter_rust_bridge/flutter_rust_bridge.dart";

import "../../rust/ffi.dart" as ffi;
import "../../rust/progresses.dart";
import "../../rust/types.dart";

class TransferService {
  Future<void> send({
    required List<String> paths,
    required String? addr,
    required RustStreamSink<List<ProgressState>> stream,
    required RustStreamSink<SendResult> result,
  }) async {
    await ffi.send(paths: paths, addr: addr, stream: stream, result: result);
  }

  Future<void> cancelSend(String ticket) async {
    await ffi.cancelSend(ticket: ticket);
  }

  Future<void> receive({
    String? relay,
    required String ticket,
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

  Future<void> acceptReceive(String ticket) async {
    await ffi.acceptReceive(ticket: ticket);
  }

  Future<void> rejectReceive(String ticket) async {
    await ffi.rejectReceive(ticket: ticket);
  }

  Future<void> cancelReceive(String ticket) async {
    await ffi.cancelReceive(ticket: ticket);
  }
}
