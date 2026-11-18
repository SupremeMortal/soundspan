// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

#include "include/soundspan_smtc/soundspan_smtc_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "soundspan_smtc_plugin.h"

void SoundspanSmtcPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  soundspan_smtc::SoundspanSmtcPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
