import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_tags_lofty_platform_interface.dart';

/// An implementation of [AudioTagsLoftyPlatform] that uses method channels.
class MethodChannelAudioTagsLofty extends AudioTagsLoftyPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audio_tags_lofty');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
