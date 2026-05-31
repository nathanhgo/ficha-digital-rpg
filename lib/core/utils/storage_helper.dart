import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseStorageHelper {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Picks a file or image from the device and uploads it to the 'rpg-files' bucket.
  /// Returns the public URL of the uploaded file, or null if cancelled/failed.
  static Future<String?> pickAndUploadFile({
    List<String>? allowedExtensions,
    FileType fileType = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        withData: true, // Required for Web/Mobile bytes upload
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = result.files.first;
      final fileBytes = file.bytes;

      if (fileBytes == null) {
        debugPrint("Erro: Bytes do arquivo estão vazios.");
        return null;
      }

      // Generate a unique file name to avoid collisions
      final extension = file.extension ?? 'bin';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';

      // Upload binary to Supabase bucket 'rpg-files'
      await _client.storage.from('rpg-files').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _guessMimeType(extension),
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _client.storage.from('rpg-files').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Erro ao fazer upload no Supabase Storage: $e");
      return null;
    }
  }

  static String _guessMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
