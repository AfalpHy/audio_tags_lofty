import 'dart:typed_data';

import 'package:audio_tags_lofty/src/loffy_ffi.dart';

class AudioTags {
  static final AudioTags _instance = AudioTags._internal();

  factory AudioTags() => _instance;

  AudioTags._internal();

  String? readMetadata(String path, {bool needPicture = false}) {
    return getAudioMetadata(path, needPicture).toString();
  }

  Uint8List? readPicture(String path) {
    return getAudioPicture(path);
  }
}
