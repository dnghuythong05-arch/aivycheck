import 'dart:js_interop';

@JS('document.documentElement.setAttribute')
external void _setAttribute(String name, String value);

void applyBrowserTheme(bool dark) {
  _setAttribute('data-aivie-theme', dark ? 'dark' : 'light');
}
