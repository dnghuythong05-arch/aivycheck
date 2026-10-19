import 'dart:js_interop';

@JS('document.documentElement.setAttribute')
external void _setAttribute(String name, String value);

@JS('document.head.insertAdjacentHTML')
external void _insertHeadHtml(String position, String html);

bool _textStylesAdded = false;

void applyBrowserTheme(bool dark) {
  _setAttribute('data-aivie-theme', dark ? 'dark' : 'light');

  if (_textStylesAdded) return;

  _insertHeadHtml('beforeend', '''
    <style id="aivie-face-text-style">
      html .aivy-face-dialog {
        font-weight: 500;
      }

      html .aivy-face-dialog .aivy-face-header h2 {
        font-weight: 600;
      }

      html .aivy-face-dialog [data-name],
      html .aivy-face-dialog [data-status],
      html .aivy-face-dialog [data-photo-count],
      html .aivy-face-dialog [data-previews] > div > div {
        font-weight: 400;
        color: var(--aivie-muted);
      }

      html .aivy-face-dialog button {
        font-weight: 500;
      }
    </style>
  ''');

  _textStylesAdded = true;
}
