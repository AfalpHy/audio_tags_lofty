#include "include/audio_tags_lofty/audio_tags_lofty_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "audio_tags_lofty_plugin.h"

void AudioTagsLoftyPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  audio_tags_lofty::AudioTagsLoftyPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
