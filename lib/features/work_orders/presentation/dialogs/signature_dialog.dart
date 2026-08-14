part of '../work_order_dialogs.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog(
      {required this.controller, required this.orderId, super.key});

  final WorkOrderController controller;
  final String orderId;

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final List<List<Offset>> _strokes = [];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(320.0, 560.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              kicker: 'SIGN / CONFIRMATION',
              title: context.tr('客户电子签名'),
              subtitle: context.tr('签名仅用于记录双方确认，不替代正式合同。'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 18),
              child: Column(
                children: [
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onPanStart: (details) =>
                          setState(() => _strokes.add([details.localPosition])),
                      onPanUpdate: (details) {
                        if (_strokes.isNotEmpty) {
                          setState(
                              () => _strokes.last.add(details.localPosition));
                        }
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(_strokes),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        context.tr('请让客户在框内签名'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _strokes.clear()),
                        child: Text(context.tr('清除重签')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(context.tr('取消'))),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('保存签名')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_strokes.every((stroke) => stroke.length < 2)) {
      showTopNotice(context, context.tr('请先让客户签名。'), error: true);
      return;
    }
    setState(() => _saving = true);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 520, 210));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 520, 210),
      Paint()..color = Colors.white,
    );
    final paint = Paint()
      ..color = _dialogNavy
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
    final image = await recorder.endRecording().toImage(520, 210);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null || !mounted) return;
    await widget.controller.saveSignature(
      widget.orderId,
      'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List())}',
    );
    if (mounted) Navigator.pop(context);
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _dialogNavy
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
