import "dart:io";

import "package:flutter/foundation.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

import "android_service.dart";

class PlatformService {
  static Future<String?> getPublicTransferFolder() async {
    final path = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => (await getDownloadsDirectory()),
      TargetPlatform.android => await AndroidService.publicDownloadFolder(),
      _ => (await getApplicationDocumentsDirectory()),
    };
    if (path != null) {
      final res = Directory(p.join(path.path, "Droplus"));
      if (!res.existsSync()) {
        res.createSync(recursive: true);
      }
      return res.path;
    }
    return null;
  }
}
