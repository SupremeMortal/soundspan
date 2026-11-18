// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

#ifndef FLUTTER_PLUGIN_SOUNDSPAN_SMTC_PLUGIN_H_
#define FLUTTER_PLUGIN_SOUNDSPAN_SMTC_PLUGIN_H_

#include <windows.h>

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Media.h>

#include <atomic>
#include <deque>
#include <memory>
#include <mutex>

namespace soundspan_smtc {

// Events raised on WinRT threads, waiting for the platform thread. The
// plugin and the WinRT handlers share it, so a handler that runs while the
// plugin is being destroyed touches only the mailbox.
struct Mailbox {
  std::mutex mutex;
  std::deque<flutter::EncodableValue> events;
  HWND window = nullptr;
};

// The System Media Transport Controls of the process, over the method
// channel `soundspan_smtc` and the event channel `soundspan_smtc/events`.
//
// The controls come from a MediaPlayer whose command manager is disabled,
// so the session belongs to the process's app user model id and shows
// exactly what the Dart side sets. Every method runs on the platform
// thread; button and seek events are posted to a message-only window and
// sent from there.
class SoundspanSmtcPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit SoundspanSmtcPlugin(flutter::PluginRegistrarWindows* registrar);

  ~SoundspanSmtcPlugin() override;

  SoundspanSmtcPlugin(const SoundspanSmtcPlugin&) = delete;
  SoundspanSmtcPlugin& operator=(const SoundspanSmtcPlugin&) = delete;

  // Sends the events waiting in the mailbox to the event sink.
  void Drain();

  // Keeps the event sink the Dart side listens through, or none.
  void SetSink(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink);

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void Initialize();
  void Dispose();
  void SetButtons(const flutter::EncodableMap& args);
  void SetMetadata(const flutter::EncodableMap& args);
  void SetStatus(const flutter::EncodableMap& args);
  void SetTimeline(const flutter::EncodableMap& args);
  void Clear();

  std::shared_ptr<Mailbox> mailbox_ = std::make_shared<Mailbox>();
  std::shared_ptr<std::atomic<unsigned long long>> thumbnail_generation_ =
      std::make_shared<std::atomic<unsigned long long>>(0);
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  winrt::Windows::Media::Playback::MediaPlayer player_{nullptr};
  winrt::Windows::Media::SystemMediaTransportControls controls_{nullptr};
  winrt::event_token button_token_{};
  winrt::event_token seek_token_{};
};

}  // namespace soundspan_smtc

#endif  // FLUTTER_PLUGIN_SOUNDSPAN_SMTC_PLUGIN_H_
