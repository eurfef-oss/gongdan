import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Encodes an RGB bitmap as a single-page PDF without adding a PDF dependency.
///
/// The caller supplies one byte triplet per pixel in row-major order. Keeping
/// this encoder independent from Flutter rendering makes the exported format
/// easy to validate in unit tests and keeps document sharing offline.
Uint8List pdfFromRgb({
  required int width,
  required int height,
  required Uint8List rgb,
}) {
  if (width <= 0 || height <= 0 || rgb.length != width * height * 3) {
    throw ArgumentError('RGB bitmap dimensions and bytes do not match.');
  }

  final compressed = ZLibEncoder().convert(rgb);
  final content = 'q\n$width 0 0 $height 0 0 cm\n/Im0 Do\nQ\n';
  final objects = <List<int>>[
    _ascii('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'),
    _ascii('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'),
    _ascii(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R '
      '/MediaBox [0 0 $width $height] '
      '/Resources << /XObject << /Im0 4 0 R >> >> '
      '/Contents 5 0 R >>\nendobj\n',
    ),
    [
      ..._ascii(
        '4 0 obj\n<< /Type /XObject /Subtype /Image '
        '/Width $width /Height $height '
        '/ColorSpace /DeviceRGB /BitsPerComponent 8 '
        '/Filter /FlateDecode /Length ${compressed.length} >>\nstream\n',
      ),
      ...compressed,
      ..._ascii('\nendstream\nendobj\n'),
    ],
    [
      ..._ascii('5 0 obj\n<< /Length ${_ascii(content).length} >>\nstream\n'),
      ..._ascii(content),
      ..._ascii('endstream\nendobj\n'),
    ],
  ];

  final output = BytesBuilder(copy: false)
    ..add(_ascii('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n'));
  final offsets = <int>[0];
  for (final object in objects) {
    offsets.add(output.length);
    output.add(object);
  }
  final xrefOffset = output.length;
  output
    ..add(_ascii('xref\n0 ${objects.length + 1}\n'))
    ..add(_ascii('0000000000 65535 f \n'));
  for (final offset in offsets.skip(1)) {
    output.add(_ascii('${offset.toString().padLeft(10, '0')} 00000 n \n'));
  }
  output.add(
    _ascii(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefOffset\n%%EOF\n',
    ),
  );
  return output.takeBytes();
}

Uint8List _ascii(String value) => Uint8List.fromList(latin1.encode(value));
