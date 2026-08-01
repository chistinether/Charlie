// Picks the right implementation of openLocalDocument() for the current
// platform. Documents are now kept purely as in-memory/persisted bytes
// (see UserDocument + LocalStorageService), so opening them needs
// different handling per platform:
//   - Web: trigger a browser download/open of the bytes.
//   - Mobile/desktop: write the bytes to a temp file, then hand that
//     path to the OS via open_filex.
export 'local_document_opener_io.dart'
    if (dart.library.html) 'local_document_opener_web.dart';
