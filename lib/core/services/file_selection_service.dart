import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

enum FileSelectionKind { any, custom, image }

enum ImageSelectionSource { camera, gallery }

class SelectedFile {
  const SelectedFile({
    required this.name,
    required this.readAsBytes,
  });

  final String name;
  final Future<Uint8List> Function() readAsBytes;
}

abstract interface class FileSelectionService {
  Future<List<SelectedFile>> pickFiles({
    FileSelectionKind kind = FileSelectionKind.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  });

  Future<SelectedFile?> pickImage(ImageSelectionSource source);

  Future<String?> saveFile({
    required String fileName,
    required String extension,
    required Uint8List bytes,
    String? dialogTitle,
  });
}

class PlatformFileSelectionService implements FileSelectionService {
  PlatformFileSelectionService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<List<SelectedFile>> pickFiles({
    FileSelectionKind kind = FileSelectionKind.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final type = switch (kind) {
      FileSelectionKind.any => FileType.any,
      FileSelectionKind.custom => FileType.custom,
      FileSelectionKind.image => FileType.image,
    };
    if (!allowMultiple) {
      final file = await FilePicker.pickFile(
        type: type,
        allowedExtensions: allowedExtensions,
      );
      if (file == null) return const [];
      return [
        SelectedFile(
          name: file.name,
          readAsBytes: file.readAsBytes,
        ),
      ];
    }
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (result == null) return const [];
    return result.files
        .map(
          (file) => SelectedFile(
            name: file.name,
            readAsBytes: file.readAsBytes,
          ),
        )
        .toList();
  }

  @override
  Future<SelectedFile?> pickImage(ImageSelectionSource source) async {
    final file = await _imagePicker.pickImage(
      source: source == ImageSelectionSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Keep enough detail for a repair record while avoiding very large
      // camera files that make watermarking and local persistence feel slow.
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return null;
    return SelectedFile(name: file.name, readAsBytes: file.readAsBytes);
  }

  @override
  Future<String?> saveFile({
    required String fileName,
    required String extension,
    required Uint8List bytes,
    String? dialogTitle,
  }) {
    return FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
  }
}
