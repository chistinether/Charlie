import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/user_document.dart';
import '../../services/local_storage_service.dart';
import '../../services/local_document_opener.dart';

class DocumentsScreen extends StatefulWidget {
  // Used to key documents to the signed-in user, so they persist locally
  // (and don't get mixed up between users) instead of relying on Firebase
  // Storage.
  final String userEmail;

  const DocumentsScreen({super.key, required this.userEmail});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<UserDocument> documents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final loaded = await LocalStorageService.loadDocuments(widget.userEmail);

    if (!mounted) return;

    setState(() {
      documents = loaded;
      loading = false;
    });
  }

  Future<void> _persist() async {
    await LocalStorageService.saveDocuments(widget.userEmail, documents);
  }

  Future<void> pickDocument() async {
    // withData ensures we get the raw bytes back even on platforms/pickers
    // where a real file `path` isn't available - most notably the web,
    // where `path` is always null.
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not read the selected file. Please try again."),
        ),
      );
      return;
    }

    final document = UserDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: file.name,
      bytes: file.bytes!,
      uploadedAt: DateTime.now(),
    );

    setState(() {
      documents.add(document);
    });

    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${file.name} uploaded successfully"),
      ),
    );
  }

  Future<void> openDocument(UserDocument document) async {
    final opened = await openLocalDocument(document.name, document.bytes);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open document")),
      );
    }
  }

  Future<void> deleteDocument(int index) async {
    setState(() {
      documents.removeAt(index);
    });

    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Document deleted"),
      ),
    );
  }

  IconData getIcon(String name) {
    String file = name.toLowerCase();

    if (file.endsWith(".pdf")) {
      return Icons.picture_as_pdf;
    }

    if (file.endsWith(".jpg") ||
        file.endsWith(".jpeg") ||
        file.endsWith(".png")) {
      return Icons.image;
    }

    if (file.endsWith(".doc") ||
        file.endsWith(".docx")) {
      return Icons.description;
    }

    if (file.endsWith(".xls") ||
        file.endsWith(".xlsx")) {
      return Icons.table_chart;
    }

    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Financial Documents"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: pickDocument,
        child: const Icon(
          Icons.upload_file,
          color: Colors.white,
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
              ? const Center(
                  child: Text(
                    "No documents uploaded",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        onTap: () {
                          openDocument(document);
                        },

                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E7D32),
                          child: Icon(
                            getIcon(document.name),
                            color: Colors.white,
                          ),
                        ),

                        title: Text(
                          document.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: const Text(
                          "Tap to open",
                        ),

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            deleteDocument(index);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
