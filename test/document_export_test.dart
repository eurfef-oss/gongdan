import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/work_orders/services/document_export.dart';

void main() {
  test('encodes an RGB bitmap as a readable single-page PDF', () {
    final bytes = pdfFromRgb(
      width: 2,
      height: 1,
      rgb: Uint8List.fromList([255, 0, 0, 0, 255, 0]),
    );
    final text = latin1.decode(bytes);

    expect(text, startsWith('%PDF-1.4'));
    expect(text, contains('/Type /Catalog'));
    expect(text, contains('/Subtype /Image'));
    expect(text, contains('/Width 2 /Height 1'));
    expect(text, contains('xref\n0 6\n'));
    expect(text, endsWith('%%EOF\n'));
  });

  test('rejects an RGB bitmap with mismatched dimensions', () {
    expect(
      () => pdfFromRgb(
        width: 1,
        height: 1,
        rgb: Uint8List.fromList([255, 0]),
      ),
      throwsArgumentError,
    );
  });
}
