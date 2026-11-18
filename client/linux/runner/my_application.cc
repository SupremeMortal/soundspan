#include "my_application.h"

#include <errno.h>
#include <flutter_linux/flutter_linux.h>

#include "flutter/generated_plugin_registrant.h"

// The method channel on which a later launch is forwarded to Dart
// (lib/platform/desktop_shell/desktop_shell.dart).
static const char kSingleInstanceChannel[] = "io.soundspan.app/single_instance";
static const char kSecondInstanceMethod[] = "secondInstance";

// The method channel of the title bar (lib/platform/desktop_shell/
// desktop_shell.dart): Dart asks whether the system title bar was hidden
// and for the desktop's button layout, and stores the "Use system title
// bar" choice; the runner sends layout changes.
static const char kWindowChannel[] = "io.soundspan.app/window";

// The key file holding the "Use system title bar" choice, under the user's
// configuration directory, read before the window is realized.
static const char kWindowKeyFile[] = "window.ini";
static const char kTitleBarGroup[] = "TitleBar";
static const char kUseSystemTitleBarKey[] = "UseSystemTitleBar";

// Set to 1 to keep the system title bar, or 0 to hide it, whatever the key
// file says.
static const char kSystemTitleBarEnv[] = "SOUNDSPAN_SYSTEM_TITLEBAR";

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // The one top-level window, created by the first activation.
  GtkWindow* window;
  // Forwards later launches to Dart.
  FlMethodChannel* single_instance_channel;
  // The title bar channel (kWindowChannel).
  FlMethodChannel* window_channel;
  // Whether the system title bar was replaced by the app's own.
  gboolean integrated_title_bar;
  // The handler of GtkSettings' notify::gtk-decoration-layout.
  gulong layout_handler;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Queues a resize of |widget| and every widget inside it, internal children
// included, so each one is allocated again.
static void queue_resize_tree(GtkWidget* widget, gpointer user_data) {
  gtk_widget_queue_resize(widget);
  if (GTK_IS_CONTAINER(widget)) {
    gtk_container_forall(GTK_CONTAINER(widget), queue_resize_tree, user_data);
  }
}

// Called when the window's GdkWindow is shown, including when a hidden window
// (close to tray) is shown again.
//
// On Wayland GTK destroys the toplevel's wl_surface on hide. Flutter's
// subsurface renderer moves onto the new surface from its map and
// size-allocate handlers, but GTK maps child widgets before it shows the
// toplevel, so on map there is no surface yet, and a window shown at its
// previous size is not allocated again. The view then stays black until the
// window is resized. Re-allocating every widget once the surface exists lets
// the renderer attach to it and ask for a frame.
static gboolean window_map_event_cb(GtkWidget* window, GdkEvent* event,
                                    gpointer user_data) {
  queue_resize_tree(window, nullptr);
  return FALSE;
}

// The path of the key file holding the title bar choice.
static gchar* window_key_file_path() {
  return g_build_filename(g_get_user_config_dir(), APPLICATION_ID,
                          kWindowKeyFile, nullptr);
}

// Whether the user asked for the system title bar: the environment
// variable when set, else the key file; false when neither says so.
static gboolean use_system_title_bar() {
  const gchar* env = g_getenv(kSystemTitleBarEnv);
  if (env != nullptr && env[0] != '\0') {
    return g_strcmp0(env, "0") != 0;
  }
  g_autofree gchar* path = window_key_file_path();
  g_autoptr(GKeyFile) file = g_key_file_new();
  if (!g_key_file_load_from_file(file, path, G_KEY_FILE_NONE, nullptr)) {
    return FALSE;
  }
  return g_key_file_get_boolean(file, kTitleBarGroup, kUseSystemTitleBarKey,
                                nullptr);
}

// Stores the title bar choice in the key file, keeping its other entries.
static gboolean store_use_system_title_bar(gboolean value, GError** error) {
  g_autofree gchar* path = window_key_file_path();
  g_autofree gchar* dir = g_path_get_dirname(path);
  if (g_mkdir_with_parents(dir, 0700) != 0) {
    g_set_error(error, G_FILE_ERROR, g_file_error_from_errno(errno),
                "Could not create %s", dir);
    return FALSE;
  }
  g_autoptr(GKeyFile) file = g_key_file_new();
  g_key_file_load_from_file(file, path, G_KEY_FILE_KEEP_COMMENTS, nullptr);
  g_key_file_set_boolean(file, kTitleBarGroup, kUseSystemTitleBarKey, value);
  return g_key_file_save_to_file(file, path, error);
}

// The desktop's title bar button layout, such as
// "icon:minimize,maximize,close"; Plasma keeps it in step with its
// Titlebar Buttons settings, GNOME with its button-layout key.
static gchar* decoration_layout() {
  gchar* layout = nullptr;
  g_object_get(gtk_settings_get_default(), "gtk-decoration-layout", &layout,
               nullptr);
  return layout != nullptr ? layout : g_strdup("");
}

// Sends the changed button layout to Dart.
static void decoration_layout_changed_cb(GtkSettings* settings,
                                         GParamSpec* pspec,
                                         MyApplication* self) {
  if (self->window_channel == nullptr) return;
  g_autofree gchar* layout = decoration_layout();
  g_autoptr(FlValue) args = fl_value_new_string(layout);
  fl_method_channel_invoke_method(self->window_channel, "layoutChanged", args,
                                  nullptr, nullptr, nullptr);
}

// Answers the title bar channel's calls from Dart.
static void window_method_cb(FlMethodChannel* channel, FlMethodCall* call,
                             gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(method, "getTitleBar") == 0) {
    g_autofree gchar* layout = decoration_layout();
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "integrated",
                             fl_value_new_bool(self->integrated_title_bar));
    fl_value_set_string_take(result, "layout", fl_value_new_string(layout));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (g_strcmp0(method, "setUseSystemTitleBar") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_BOOL) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "bad-args", "expected a bool", nullptr));
    } else {
      g_autoptr(GError) error = nullptr;
      if (store_use_system_title_bar(fl_value_get_bool(args), &error)) {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "write-failed", error->message, nullptr));
      }
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

// Brings the existing window forward and sends |args| (a list of strings)
// to Dart as a second launch.
static void forward_second_instance(MyApplication* self, FlValue* args) {
  gtk_window_present(self->window);
  if (self->single_instance_channel != nullptr) {
    fl_method_channel_invoke_method(self->single_instance_channel,
                                    kSecondInstanceMethod, args, nullptr,
                                    nullptr, nullptr);
  }
}

// Implements GApplication::activate. The first activation creates the
// window; a later one (a second launch without arguments) presents it.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  if (self->window != nullptr) {
    g_autoptr(FlValue) args = fl_value_new_list();
    forward_second_instance(self, args);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;
  gtk_window_set_default_size(window, 1280, 720);

  // The app draws its own title bar: an empty title bar widget, never
  // shown, makes GTK draw the window's frame itself (client-side
  // decorations), so the window keeps its shadow, rounded corners and
  // resize margins while the window manager draws no title bar. It must be
  // set before the window is realized.
  if (!use_system_title_bar()) {
    GtkWidget* title_bar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_widget_set_size_request(title_bar, -1, 0);
    gtk_window_set_titlebar(window, title_bar);
    self->integrated_title_bar = TRUE;
  }

  gtk_window_set_title(window, "soundspan");
  g_signal_connect(window, "map-event", G_CALLBACK(window_map_event_cb),
                   nullptr);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->single_instance_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kSingleInstanceChannel, FL_METHOD_CODEC(codec));
  self->window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kWindowChannel,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->window_channel,
                                            window_method_cb, self, nullptr);
  self->layout_handler = g_signal_connect(
      gtk_settings_get_default(), "notify::gtk-decoration-layout",
      G_CALLBACK(decoration_layout_changed_cb), self);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::open: a second launch with arguments, such as a
// soundspan:// link, presents the window and forwards the URIs to Dart.
static void my_application_open(GApplication* application, GFile** files,
                                gint n_files, const gchar* hint) {
  MyApplication* self = MY_APPLICATION(application);
  if (self->window == nullptr) {
    g_application_activate(application);
  }
  g_autoptr(FlValue) args = fl_value_new_list();
  for (gint i = 0; i < n_files; i++) {
    g_autofree gchar* uri = g_file_get_uri(files[i]);
    fl_value_append_take(args, fl_value_new_string(uri));
  }
  forward_second_instance(self, args);
}

// Implements GApplication::local_command_line. The first instance passes
// its arguments to the Dart entry point; a later instance hands them to the
// first one (open, or activate without arguments) and exits with 0.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  if (g_application_get_is_remote(application)) {
    gchar** args = *arguments + 1;
    guint n_args = g_strv_length(args);
    if (n_args == 0) {
      g_application_activate(application);
    } else {
      GFile** files = g_new(GFile*, n_args);
      for (guint i = 0; i < n_args; i++) {
        files[i] = g_file_new_for_commandline_arg(args[i]);
      }
      g_application_open(application, files, n_args, "");
      for (guint i = 0; i < n_args; i++) {
        g_object_unref(files[i]);
      }
      g_free(files);
    }
    *exit_status = 0;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->single_instance_channel);
  GtkSettings* settings = gtk_settings_get_default();
  if (self->layout_handler != 0 && settings != nullptr) {
    g_signal_handler_disconnect(settings, self->layout_handler);
  }
  self->layout_handler = 0;
  g_clear_object(&self->window_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->open = my_application_open;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->window = nullptr;
  self->single_instance_channel = nullptr;
  self->window_channel = nullptr;
  self->integrated_title_bar = FALSE;
  self->layout_handler = 0;
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_HANDLES_OPEN, nullptr));
}
