// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

void requestFullscreen() {
  try {
    final docEl = html.document.documentElement;
    if (docEl != null) {
      docEl.requestFullscreen();
    }
  } catch (e) {
    // browser might reject if not called inside user interaction, which is fine
  }
}

void exitFullscreen() {
  try {
    html.document.exitFullscreen();
  } catch (e) {
    // ignore
  }
}

bool isCurrentlyFullscreen() {
  try {
    return html.document.fullscreenElement != null;
  } catch (e) {
    return false;
  }
}

Stream<void> getFullscreenChangeStream() {
  return html.document.onFullscreenChange;
}

Stream<void> getEscapeKeyPressStream() {
  return html.document.onKeyDown.where((event) => event.key == 'Escape');
}
