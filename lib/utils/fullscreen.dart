// lib/utils/fullscreen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'web_eval_stub.dart' if (dart.library.js_interop) 'fullscreen_web.dart' as js;

import 'package:window_manager/window_manager.dart';

class FullscreenService {
  static void enter() {
    if (kIsWeb) {
      try {
        js.eval(
          "if (document.documentElement.requestFullscreen) { document.documentElement.requestFullscreen(); } else if (document.documentElement.mozRequestFullScreen) { document.documentElement.mozRequestFullScreen(); } else if (document.documentElement.webkitRequestFullscreen) { document.documentElement.webkitRequestFullscreen(); } else if (document.documentElement.msRequestFullscreen) { document.documentElement.msRequestFullscreen(); }"
        );
      } catch (e) {
        debugPrint('Fullscreen error (Web): $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.linux || 
               defaultTargetPlatform == TargetPlatform.macOS || 
               defaultTargetPlatform == TargetPlatform.windows) {
      windowManager.setFullScreen(true);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  static void exit() {
    if (kIsWeb) {
      try {
        js.eval(
          "if (document.exitFullscreen) { document.exitFullscreen(); } else if (document.mozCancelFullScreen) { document.mozCancelFullScreen(); } else if (document.webkitExitFullscreen) { document.webkitExitFullscreen(); } else if (document.msExitFullscreen) { document.msExitFullscreen(); }"
        );
      } catch (e) {
        debugPrint('Exit Fullscreen error (Web): $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.linux || 
               defaultTargetPlatform == TargetPlatform.macOS || 
               defaultTargetPlatform == TargetPlatform.windows) {
      windowManager.setFullScreen(false);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
