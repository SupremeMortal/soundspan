// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

#include "soundspan_smtc_plugin.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Storage.h>

#include <chrono>
#include <cstdint>
#include <string>
#include <utility>

namespace soundspan_smtc {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Foundation::IAsyncOperation;
using winrt::Windows::Foundation::TimeSpan;
using winrt::Windows::Media::MediaPlaybackStatus;
using winrt::Windows::Media::MediaPlaybackType;
using winrt::Windows::Media::PlaybackPositionChangeRequestedEventArgs;
using winrt::Windows::Media::SystemMediaTransportControls;
using winrt::Windows::Media::SystemMediaTransportControlsButton;
using winrt::Windows::Media::SystemMediaTransportControlsButtonPressedEventArgs;
using winrt::Windows::Media::SystemMediaTransportControlsTimelineProperties;
using winrt::Windows::Media::Playback::MediaPlayer;
using winrt::Windows::Storage::StorageFile;
using winrt::Windows::Storage::Streams::RandomAccessStreamReference;

constexpr wchar_t kWindowClass[] = L"SoundspanSmtcMessageWindow";
constexpr UINT kEventMessage = WM_APP + 0x10;

LRESULT CALLBACK MessageWindowProc(HWND window, UINT message, WPARAM wparam,
                                   LPARAM lparam) {
  if (message == kEventMessage) {
    auto* plugin = reinterpret_cast<SoundspanSmtcPlugin*>(
        ::GetWindowLongPtrW(window, GWLP_USERDATA));
    if (plugin != nullptr) {
      plugin->Drain();
    }
    return 0;
  }
  return ::DefWindowProcW(window, message, wparam, lparam);
}

// A message-only window on the platform thread: events raised on WinRT
// threads are posted to it and sent to Dart from its window procedure.
HWND CreateMessageWindow(SoundspanSmtcPlugin* plugin) {
  HINSTANCE instance = ::GetModuleHandleW(nullptr);
  WNDCLASSW window_class{};
  window_class.lpfnWndProc = MessageWindowProc;
  window_class.hInstance = instance;
  window_class.lpszClassName = kWindowClass;
  ::RegisterClassW(&window_class);  // Fails harmlessly once registered.
  HWND window = ::CreateWindowExW(0, kWindowClass, L"", 0, 0, 0, 0, 0,
                                  HWND_MESSAGE, nullptr, instance, nullptr);
  if (window != nullptr) {
    ::SetWindowLongPtrW(window, GWLP_USERDATA,
                        reinterpret_cast<LONG_PTR>(plugin));
  }
  return window;
}

void PostEvent(const std::shared_ptr<Mailbox>& mailbox, EncodableValue event) {
  HWND window = nullptr;
  {
    std::lock_guard<std::mutex> lock(mailbox->mutex);
    mailbox->events.push_back(std::move(event));
    window = mailbox->window;
  }
  if (window != nullptr) {
    ::PostMessageW(window, kEventMessage, 0, 0);
  }
}

const EncodableValue* Find(const EncodableMap& args, const char* key) {
  auto it = args.find(EncodableValue(std::string(key)));
  if (it == args.end() || it->second.IsNull()) {
    return nullptr;
  }
  return &it->second;
}

bool GetBool(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Find(args, key);
  const bool* flag = value == nullptr ? nullptr : std::get_if<bool>(value);
  return flag != nullptr && *flag;
}

std::string GetString(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Find(args, key);
  const std::string* text =
      value == nullptr ? nullptr : std::get_if<std::string>(value);
  return text == nullptr ? std::string() : *text;
}

TimeSpan GetMilliseconds(const EncodableMap& args, const char* key,
                         TimeSpan fallback) {
  const EncodableValue* value = Find(args, key);
  if (value == nullptr) {
    return fallback;
  }
  return std::chrono::milliseconds(value->LongValue());
}

const char* ButtonName(SystemMediaTransportControlsButton button) {
  switch (button) {
    case SystemMediaTransportControlsButton::Play:
      return "play";
    case SystemMediaTransportControlsButton::Pause:
      return "pause";
    case SystemMediaTransportControlsButton::Next:
      return "next";
    case SystemMediaTransportControlsButton::Previous:
      return "previous";
    case SystemMediaTransportControlsButton::Stop:
      return "stop";
    case SystemMediaTransportControlsButton::FastForward:
      return "fastForward";
    case SystemMediaTransportControlsButton::Rewind:
      return "rewind";
    default:
      return nullptr;
  }
}

}  // namespace

// static
void SoundspanSmtcPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto methods =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          registrar->messenger(), "soundspan_smtc",
          &flutter::StandardMethodCodec::GetInstance());
  auto events = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "soundspan_smtc/events",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SoundspanSmtcPlugin>(registrar);
  SoundspanSmtcPlugin* pointer = plugin.get();

  methods->SetMethodCallHandler([pointer](const auto& call, auto result) {
    pointer->HandleMethodCall(call, std::move(result));
  });
  events->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [pointer](const EncodableValue* arguments,
                    std::unique_ptr<flutter::EventSink<EncodableValue>>&& sink)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            pointer->SetSink(std::move(sink));
            return nullptr;
          },
          [pointer](const EncodableValue* arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            pointer->SetSink(nullptr);
            return nullptr;
          }));

  registrar->AddPlugin(std::move(plugin));
}

SoundspanSmtcPlugin::SoundspanSmtcPlugin(
    flutter::PluginRegistrarWindows* registrar) {
  HWND window = CreateMessageWindow(this);
  std::lock_guard<std::mutex> lock(mailbox_->mutex);
  mailbox_->window = window;
}

SoundspanSmtcPlugin::~SoundspanSmtcPlugin() {
  try {
    Dispose();
  } catch (...) {
    // The session goes with the process.
  }
  HWND window = nullptr;
  {
    std::lock_guard<std::mutex> lock(mailbox_->mutex);
    window = mailbox_->window;
    mailbox_->window = nullptr;
    mailbox_->events.clear();
  }
  if (window != nullptr) {
    ::SetWindowLongPtrW(window, GWLP_USERDATA, 0);
    ::DestroyWindow(window);
  }
}

void SoundspanSmtcPlugin::SetSink(
    std::unique_ptr<flutter::EventSink<EncodableValue>> sink) {
  sink_ = std::move(sink);
}

void SoundspanSmtcPlugin::Drain() {
  std::deque<EncodableValue> events;
  {
    std::lock_guard<std::mutex> lock(mailbox_->mutex);
    events.swap(mailbox_->events);
  }
  if (!sink_) {
    return;
  }
  for (const auto& event : events) {
    sink_->Success(event);
  }
}

void SoundspanSmtcPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  static const EncodableMap kNoArguments;
  const auto* map = std::get_if<EncodableMap>(call.arguments());
  const EncodableMap& args = map == nullptr ? kNoArguments : *map;
  const std::string& method = call.method_name();
  try {
    if (method == "initialize") {
      Initialize();
    } else if (method == "dispose") {
      Dispose();
    } else if (!controls_) {
      result->Error("not_initialized", "initialize was not called");
      return;
    } else if (method == "setButtons") {
      SetButtons(args);
    } else if (method == "setMetadata") {
      SetMetadata(args);
    } else if (method == "setStatus") {
      SetStatus(args);
    } else if (method == "setTimeline") {
      SetTimeline(args);
    } else if (method == "clear") {
      Clear();
    } else {
      result->NotImplemented();
      return;
    }
  } catch (const winrt::hresult_error& error) {
    result->Error("smtc_failed", winrt::to_string(error.message()));
    return;
  }
  result->Success();
}

void SoundspanSmtcPlugin::Initialize() {
  if (controls_) {
    return;
  }
  player_ = MediaPlayer();
  player_.CommandManager().IsEnabled(false);
  controls_ = player_.SystemMediaTransportControls();
  controls_.IsEnabled(true);
  controls_.IsPlayEnabled(false);
  controls_.IsPauseEnabled(false);
  controls_.IsNextEnabled(false);
  controls_.IsPreviousEnabled(false);
  controls_.IsStopEnabled(false);
  controls_.IsFastForwardEnabled(false);
  controls_.IsRewindEnabled(false);
  controls_.PlaybackStatus(MediaPlaybackStatus::Closed);

  std::shared_ptr<Mailbox> mailbox = mailbox_;
  button_token_ = controls_.ButtonPressed(
      [mailbox](const SystemMediaTransportControls& sender,
                const SystemMediaTransportControlsButtonPressedEventArgs&
                    args) {
        const char* name = ButtonName(args.Button());
        if (name != nullptr) {
          PostEvent(mailbox,
                    EncodableValue(EncodableMap{
                        {EncodableValue("button"),
                         EncodableValue(std::string(name))}}));
        }
      });
  seek_token_ = controls_.PlaybackPositionChangeRequested(
      [mailbox](const SystemMediaTransportControls& sender,
                const PlaybackPositionChangeRequestedEventArgs& args) {
        auto milliseconds =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                args.RequestedPlaybackPosition())
                .count();
        PostEvent(mailbox,
                  EncodableValue(EncodableMap{
                      {EncodableValue("seekMs"),
                       EncodableValue(static_cast<int64_t>(milliseconds))}}));
      });
}

void SoundspanSmtcPlugin::Dispose() {
  if (!controls_) {
    return;
  }
  ++*thumbnail_generation_;
  controls_.ButtonPressed(button_token_);
  controls_.PlaybackPositionChangeRequested(seek_token_);
  controls_.DisplayUpdater().ClearAll();
  controls_.DisplayUpdater().Update();
  controls_.PlaybackStatus(MediaPlaybackStatus::Closed);
  controls_.IsEnabled(false);
  controls_ = nullptr;
  player_.Close();
  player_ = nullptr;
}

void SoundspanSmtcPlugin::SetButtons(const EncodableMap& args) {
  controls_.IsPlayEnabled(GetBool(args, "play"));
  controls_.IsPauseEnabled(GetBool(args, "pause"));
  controls_.IsNextEnabled(GetBool(args, "next"));
  controls_.IsPreviousEnabled(GetBool(args, "previous"));
  controls_.IsStopEnabled(GetBool(args, "stop"));
  controls_.IsFastForwardEnabled(GetBool(args, "fastForward"));
  controls_.IsRewindEnabled(GetBool(args, "rewind"));
}

void SoundspanSmtcPlugin::SetMetadata(const EncodableMap& args) {
  auto updater = controls_.DisplayUpdater();
  updater.Type(MediaPlaybackType::Music);
  auto music = updater.MusicProperties();
  music.Title(winrt::to_hstring(GetString(args, "title")));
  music.Artist(winrt::to_hstring(GetString(args, "artist")));
  music.AlbumTitle(winrt::to_hstring(GetString(args, "album")));
  music.AlbumArtist(winrt::to_hstring(GetString(args, "artist")));
  updater.Thumbnail(nullptr);
  updater.Update();

  // A file URI left no thumbnail in the spike's read-back, so the file is
  // opened as a StorageFile. A newer item's metadata wins over a thumbnail
  // still opening.
  const unsigned long long generation = ++*thumbnail_generation_;
  const std::string path = GetString(args, "thumbnailPath");
  if (path.empty()) {
    return;
  }
  auto counter = thumbnail_generation_;
  auto open = StorageFile::GetFileFromPathAsync(winrt::to_hstring(path));
  open.Completed([counter, generation, updater](
                     const IAsyncOperation<StorageFile>& operation,
                     AsyncStatus status) {
    if (status != AsyncStatus::Completed || counter->load() != generation) {
      return;
    }
    try {
      updater.Thumbnail(
          RandomAccessStreamReference::CreateFromFile(operation.GetResults()));
      updater.Update();
    } catch (...) {
      // The item shows without artwork.
    }
  });
}

void SoundspanSmtcPlugin::SetStatus(const EncodableMap& args) {
  const std::string status = GetString(args, "status");
  MediaPlaybackStatus value = MediaPlaybackStatus::Closed;
  if (status == "playing") {
    value = MediaPlaybackStatus::Playing;
  } else if (status == "paused") {
    value = MediaPlaybackStatus::Paused;
  } else if (status == "stopped") {
    value = MediaPlaybackStatus::Stopped;
  } else if (status == "changing") {
    value = MediaPlaybackStatus::Changing;
  }
  controls_.PlaybackStatus(value);
}

void SoundspanSmtcPlugin::SetTimeline(const EncodableMap& args) {
  const TimeSpan zero{0};
  const TimeSpan position = GetMilliseconds(args, "positionMs", zero);
  const TimeSpan end = GetMilliseconds(args, "durationMs", position);
  SystemMediaTransportControlsTimelineProperties timeline;
  timeline.StartTime(zero);
  timeline.EndTime(end);
  timeline.MinSeekTime(zero);
  timeline.MaxSeekTime(end);
  timeline.Position(position);
  controls_.UpdateTimelineProperties(timeline);
}

void SoundspanSmtcPlugin::Clear() {
  ++*thumbnail_generation_;
  controls_.DisplayUpdater().ClearAll();
  controls_.DisplayUpdater().Update();
}

}  // namespace soundspan_smtc
