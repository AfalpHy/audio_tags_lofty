
import 'audio_tags_lofty_platform_interface.dart';

class AudioTagsLofty {
  Future<String?> getPlatformVersion() {
    return AudioTagsLoftyPlatform.instance.getPlatformVersion();
  }
}
