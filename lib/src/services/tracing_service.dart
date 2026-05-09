import "../../rust/ffi.dart" as ffi;
import "../../rust/types.dart";

class TracingService {
  Stream<LogEntry> initTracing() {
    return ffi.initTracing();
  }
}
