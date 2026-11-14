#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

#include <windows.h>

#include <string>
#include <vector>

// The named mutex the first instance holds for its lifetime.
constexpr const wchar_t kSingleInstanceMutexName[] =
    L"Local\\io.soundspan.app.instance";

// The class of the runner's top-level window, distinctive so a second
// instance can find the first instance's window.
constexpr const wchar_t kRunnerWindowClassName[] = L"SOUNDSPAN_APP_WINDOW";

// Identifies a forwarded command line in COPYDATASTRUCT::dwData ("SSAP").
constexpr ULONG_PTR kSingleInstanceCopyDataId = 0x53534150;

// The method channel and method on which a forwarded launch reaches Dart
// (lib/platform/desktop_shell/desktop_shell.dart).
constexpr const char kSingleInstanceChannel[] =
    "io.soundspan.app/single_instance";
constexpr const char kSecondInstanceMethod[] = "secondInstance";

// Joins UTF-8 arguments with NUL separators for WM_COPYDATA.
inline std::string EncodeArguments(const std::vector<std::string>& args) {
  std::string payload;
  for (const std::string& arg : args) {
    payload.append(arg);
    payload.push_back('\0');
  }
  return payload;
}

// Splits a payload of EncodeArguments back into arguments.
inline std::vector<std::string> DecodeArguments(const char* data,
                                                size_t size) {
  std::vector<std::string> args;
  std::string current;
  for (size_t i = 0; i < size; i++) {
    if (data[i] == '\0') {
      args.push_back(current);
      current.clear();
    } else {
      current.push_back(data[i]);
    }
  }
  if (!current.empty()) {
    args.push_back(current);
  }
  return args;
}

#endif  // RUNNER_SINGLE_INSTANCE_H_
