import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";

import "../../rust/types.dart";
import "../models/limited_queue.dart";
import "../services/tracing_service.dart";

class TracingCubit extends Cubit<LimitedQueue<LogEntry>> {
  final TracingService _service;
  late final StreamSubscription<LogEntry> _subscription;

  TracingCubit(this._service, {int maxSize = 2000})
    : super(LimitedQueue(maxSize)) {
    _subscription = _service.initTracing().listen((e) {
      emit(state..add(e));
    });
  }

  void clear() => emit(state..clear());

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
