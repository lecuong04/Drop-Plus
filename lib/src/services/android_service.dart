import "dart:io";

import "package:flutter/services.dart";

import "../../global.dart";

class AndroidService {
  static const _channel = MethodChannel(channelName);

  static Future<String?> copyToLocal({
    required String srcUri,
    required String dstParent,
  }) async {
    return await _channel.invokeMethod<String>("copyToLocal", {
      "srcUri": srcUri,
      "dstParent": dstParent,
    });
  }

  static Future<Directory?> publicDownloadFolder() async {
    final path = await _channel.invokeMethod<String>("publicDownloadFolder");
    return path != null ? Directory(path) : null;
  }
}
