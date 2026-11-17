# The soundspan_smtc plugin: the Windows System Media Transport Controls
# through C++/WinRT (docs/designs/flutter-client/06-playback.md, Spike S4
# finding).
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "soundspan_smtc")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "soundspan_smtc_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/soundspan_smtc/soundspan_smtc_plugin_c_api.h"
  "soundspan_smtc_plugin_c_api.cpp"
  "soundspan_smtc_plugin.cpp"
  "soundspan_smtc_plugin.h"
)

# The runner's APPLY_STANDARD_SETTINGS, except that C++/WinRT needs C++20
# (standard coroutines in its headers) and keeps the standard library's
# exceptions: it reports failures as winrt::hresult_error.
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_20)
target_compile_options(${PLUGIN_NAME} PRIVATE /W4 /WX /wd4100 /EHsc /bigobj)
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  "$<$<CONFIG:Debug>:_DEBUG>" NOMINMAX WIN32_LEAN_AND_MEAN)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter flutter_wrapper_plugin windowsapp)

set(soundspan_smtc_bundled_libraries
  ""
  PARENT_SCOPE
)
