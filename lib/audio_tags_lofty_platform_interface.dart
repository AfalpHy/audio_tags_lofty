import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_tags_lofty_method_channel.dart';

abstract class AudioTagsLoftyPlatform extends PlatformInterface {
  /// Constructs a AudioTagsLoftyPlatform.
  AudioTagsLoftyPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioTagsLoftyPlatform _instance = MethodChannelAudioTagsLofty();

  /// The default instance of [AudioTagsLoftyPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioTagsLofty].
  static AudioTagsLoftyPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioTagsLoftyPlatform] when
  /// they register themselves.
  static set instance(AudioTagsLoftyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
