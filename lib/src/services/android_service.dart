import "package:flutter/services.dart";

class AndroidService {
  static const _channel = MethodChannel("native");

  static Future<String?> copyToLocal({
    required String srcUri,
    required String dstParent,
  }) async {
    return _channel.invokeMethod<String>("copyToLocal", {
      "srcUri": srcUri,
      "dstParent": dstParent,
    });
  }
}
