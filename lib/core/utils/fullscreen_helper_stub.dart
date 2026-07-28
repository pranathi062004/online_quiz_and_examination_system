void requestFullscreen() {
  // No-op on native platforms
}

void exitFullscreen() {
  // No-op on native platforms
}

bool isCurrentlyFullscreen() {
  return false;
}

Stream<void> getFullscreenChangeStream() {
  return const Stream.empty();
}

Stream<void> getEscapeKeyPressStream() {
  return const Stream.empty();
}

