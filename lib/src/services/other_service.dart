import "package:flutter/foundation.dart";

import "../../rust/ffi.dart" as ffi;

class OtherService {
  Future<Uint8List> qrReader(List<int> image) async {
    return await ffi.qrReader(image: image);
  }

  Future<Map<String, String>> getAddrs() async {
    return await ffi.getAddrs();
  }
}
