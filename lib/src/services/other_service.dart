import "dart:typed_data";

import "../../rust/ffi.dart" as ffi;

class OtherService {
  Future<Uint8List> qrReader(List<int> image) async {
    return await ffi.qrReader(image: image);
  }
}
