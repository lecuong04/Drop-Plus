import "package:flutter/services.dart";

import "../../global.dart";

class AndroidService {
  static const _channel = MethodChannel(channelName);

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
