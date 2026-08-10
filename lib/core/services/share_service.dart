import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

class ShareFile {
  const ShareFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

abstract interface class ShareService {
  Future<void> share({
    required String text,
    required ShareFile file,
    String? subject,
  });
}

class PlatformShareService implements ShareService {
  const PlatformShareService();

  @override
  Future<void> share({
    required String text,
    required ShareFile file,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        text: text,
        files: [
          XFile.fromData(
            file.bytes,
            name: file.fileName,
            mimeType: file.mimeType,
          ),
        ],
        fileNameOverrides: [file.fileName],
      ),
    );
  }
}
