import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

const String channelName = "vn.lecuong04.drop_plus";

final bool isDesktop = {
  TargetPlatform.windows,
  TargetPlatform.linux,
  TargetPlatform.macOS,
}.contains(defaultTargetPlatform);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
