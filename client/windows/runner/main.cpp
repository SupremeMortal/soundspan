#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shobjidl.h>
#include <windows.h>

#include "flutter_window.h"
#include "single_instance.h"
#include "utils.h"

namespace {

// Hands this launch's command line to the first instance's window through
// WM_COPYDATA and brings that window forward. Waits up to five seconds for
// the first instance to create its window.
void ForwardToFirstInstance(const std::vector<std::string>& args) {
  HWND window = nullptr;
  for (int attempt = 0; attempt < 50 && window == nullptr; attempt++) {
    window = ::FindWindowW(kRunnerWindowClassName, nullptr);
    if (window == nullptr) {
      ::Sleep(100);
    }
  }
  if (window == nullptr) {
    return;
  }
  std::string payload = EncodeArguments(args);
  COPYDATASTRUCT data;
  data.dwData = kSingleInstanceCopyDataId;
  data.cbData = static_cast<DWORD>(payload.size());
  data.lpData = payload.empty() ? nullptr : payload.data();
  ::SendMessageTimeoutW(window, WM_COPYDATA, 0,
                        reinterpret_cast<LPARAM>(&data), SMTO_ABORTIFHUNG,
                        5000, nullptr);
  ::SetForegroundWindow(window);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // A second launch forwards its command line (a soundspan:// link) to the
  // first instance and exits without starting a Flutter engine. The first
  // instance keeps the mutex until it exits.
  HANDLE instance_mutex =
      ::CreateMutexW(nullptr, FALSE, kSingleInstanceMutexName);
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    ForwardToFirstInstance(GetCommandLineArguments());
    ::CloseHandle(instance_mutex);
    return EXIT_SUCCESS;
  }

  // The app user model id names the process to the shell, so the media
  // flyout (System Media Transport Controls) shows soundspan's name and
  // icon. It must be set before any window is created.
  ::SetCurrentProcessExplicitAppUserModelID(L"io.soundspan.app");

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"soundspan", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex != nullptr) {
    ::CloseHandle(instance_mutex);
  }
  return EXIT_SUCCESS;
}
