import 'dart:html' as html;
import 'dart:typed_data';

// Web: there is no real filesystem path (and no OS-level file opener) to
// hand to a plugin like open_filex in a browser, so instead we trigger
// the browser's native download/open flow for the document's bytes.
Future<bool> openLocalDocument(String name, Uint8List bytes) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = name
      ..target = "_blank";

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);

    return true;
  } catch (_) {
    return false;
  }
}
