#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// The header bar inherits the desktop theme, so on a light theme the window
// opens with a pale strip above a black app. Repaint just the chrome black to
// match the shell; the page itself is drawn by Flutter.
static void apply_black_header_bar_css() {
  GtkCssProvider* provider = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      provider,
      "headerbar, .titlebar {"
      "  background-image: none;"
      "  background-color: #000000;"
      "  box-shadow: none;"
      "  border-bottom: 1px solid #1b1e23;"
      "}"
      "headerbar label, headerbar .title { color: #f2f4f8; }"
      "headerbar button { color: #f2f4f8; background: transparent;"
      "  border-color: transparent; box-shadow: none; }",
      -1, nullptr);
  gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(provider);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  gtk_widget_show(toplevel);
}

// Re-ask for the maximised state once the window manager has actually mapped
// the window. A maximise request sent before the window is managed is dropped
// by most WMs, which leaves the app at its default 1280x900 size.
static gboolean on_window_map_event(GtkWidget* widget, GdkEvent* event,
                                    gpointer user_data) {
  if (GTK_IS_WINDOW(widget)) {
    gtk_window_maximize(GTK_WINDOW(widget));
  }
  return FALSE;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  apply_black_header_bar_css();
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Always use client-side decorations so the chrome is the app's own black
  // header bar. With server-side decorations the window manager paints the
  // title in the desktop theme, which on a light theme is a pale strip above
  // an otherwise black app. Tiling WMs honour the CSD header bar as well.
  gboolean use_header_bar = TRUE;
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    // OS-level title so taskbars, Alt-Tab and screen readers get a name;
    // the in-app header still carries the full identity.
    gtk_header_bar_set_title(header_bar, "CEN Wallet");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "CEN Wallet");
  }

  gtk_window_set_default_size(window, 1280, 900);
  gtk_window_maximize(window);
  g_signal_connect(window, "map-event", G_CALLBACK(on_window_map_event), nullptr);

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

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
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
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
