import 'dart:typed_data';

import '../../../core/services/file_selection_service.dart';
import '../../../core/services/share_service.dart';

abstract interface class DocumentService {
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
    String? subject,
  });

  Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    String? dialogTitle,
  });
}

class PlatformDocumentService implements DocumentService {
  PlatformDocumentService({
    required FileSelectionService fileSelectionService,
    required ShareService shareService,
  })  : _fileSelectionService = fileSelectionService,
        _shareService = shareService;

  final FileSelectionService _fileSelectionService;
  final ShareService _shareService;

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
    String? subject,
  }) {
    return _shareService.share(
      text: text,
      subject: subject,
      file: ShareFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      ),
    );
  }

  @override
  Future<String?> save({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    String? dialogTitle,
  }) {
    return _fileSelectionService.saveFile(
      fileName: fileName,
      extension: extension,
      bytes: bytes,
      dialogTitle: dialogTitle,
    );
  }
}
