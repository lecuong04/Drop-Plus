import "../../rust/types.dart";
import "../../rust/ffi.dart" as ffi;

class TracingService {
  Stream<LogEntry> initTracing() {
    return ffi.initTracing();
  }
}
