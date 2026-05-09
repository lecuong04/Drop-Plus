import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

final isDesktop = {
  TargetPlatform.windows,
  TargetPlatform.linux,
  TargetPlatform.macOS,
}.contains(defaultTargetPlatform);

final navigatorKey = GlobalKey<NavigatorState>();
