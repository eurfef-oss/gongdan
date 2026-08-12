part of '../work_order_dialogs.dart';

class DocumentPreviewDialog extends StatefulWidget {
  const DocumentPreviewDialog(
      {required this.controller,
      required this.orderId,
      required this.kind,
      this.documentService,
      super.key});

  final WorkOrderController controller;
  final String orderId;
  final String kind;
  final DocumentService? documentService;

  @override
  State<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends State<DocumentPreviewDialog> {
  final _documentKey = GlobalKey();
  late final DocumentService _documentService;

  WorkOrderController get controller => widget.controller;
  String get orderId => widget.orderId;
  String get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _documentService = widget.documentService ??
        PlatformDocumentService(
          fileSelectionService: PlatformFileSelectionService(),
          shareService: const PlatformShareService(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final order = controller.orderById(orderId);
    if (order == null) return const SizedBox.shrink();
    final customer = controller.customerById(order.customerId);
    final isReceipt = kind == 'receipt';
    final title = isReceipt ? '维修服务凭证' : '服务报价单';
    final summary = [
      title,
      '工单号：${order.number}',
      '客户：${customer?.name ?? '未关联'}',
      '设备：${_dialogDevice(order)}',
      '应收：${_dialogMoney(order.total)}',
      '已收：${_dialogMoney(order.normalizedPaid)}',
      controller.data.settings.shopName,
    ].join('\n');
    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            _DialogHeader(
              kicker: 'DOCUMENT / PREVIEW',
              title: '$title预览',
              subtitle: '确认内容后，可以复制摘要、分享或保存单据文件。',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: RepaintBoundary(
                  key: _documentKey,
                  child: _DocumentPaper(
                    controller: controller,
                    order: order,
                    customer: customer,
                    isReceipt: isReceipt,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: summary));
                      if (context.mounted) showTopNotice(context, '摘要已复制。');
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('复制摘要'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _shareDocument(asPdf: false),
                    icon: const Icon(Icons.share_outlined, size: 14),
                    label: const Text('分享 PNG'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveDocument(asPdf: false),
                    icon: const Icon(Icons.save_alt_outlined, size: 16),
                    label: const Text('保存 PNG'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _shareDocument(asPdf: true),
                    icon: const Icon(Icons.share_outlined, size: 14),
                    label: const Text('分享 PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveDocument(asPdf: true),
                    icon: const Icon(Icons.save_alt_outlined, size: 16),
                    label: const Text('保存 PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDocument({required bool asPdf}) async {
    final content = await _renderDocument(asPdf: asPdf);
    if (content == null || !mounted) return;
    final title = kind == 'receipt' ? '维修服务凭证' : '服务报价单';
    await _documentService.share(
      subject: title,
      text: '$title · ${controller.orderById(orderId)?.number ?? ''}',
      bytes: content,
      mimeType: asPdf ? 'application/pdf' : 'image/png',
      fileName: _documentFileName(asPdf: asPdf),
    );
  }

  Future<void> _saveDocument({required bool asPdf}) async {
    final content = await _renderDocument(asPdf: asPdf);
    if (content == null || !mounted) return;
    final extension = asPdf ? 'pdf' : 'png';
    final fileName = _documentFileName(asPdf: asPdf);
    try {
      final path = await _documentService.save(
        dialogTitle: '保存${asPdf ? 'PDF' : 'PNG'}到本地',
        fileName: fileName,
        bytes: content,
        extension: extension,
      );
      if (!mounted || path == null) return;
      showTopNotice(context, '已保存到本地：$fileName');
    } catch (_) {
      if (!mounted) return;
      showTopNotice(context, '保存失败，请重新选择保存位置。', error: true);
    }
  }

  Future<Uint8List?> _renderDocument({required bool asPdf}) async {
    final renderObject = _documentKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      if (mounted) {
        showTopNotice(context, '单据还没有渲染完成，请稍后再试。', error: true);
      }
      return null;
    }
    await WidgetsBinding.instance.endOfFrame;
    final image = await renderObject.toImage(pixelRatio: 2.0);
    try {
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return null;
      final pngBytes = pngData.buffer.asUint8List();
      final content =
          asPdf ? await _pdfFromImage(image) : Uint8List.fromList(pngBytes);
      if (content.isEmpty && mounted) {
        showTopNotice(context, '单据导出失败，请稍后再试。', error: true);
        return null;
      }
      return content;
    } finally {
      image.dispose();
    }
  }

  String _documentFileName({required bool asPdf}) {
    final extension = asPdf ? 'pdf' : 'png';
    final number = controller.orderById(orderId)?.number ?? '单据';
    return 'RepairDesk-$number.$extension';
  }

  Future<Uint8List> _pdfFromImage(ui.Image image) async {
    final rawData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rawData == null) return Uint8List(0);
    final rgba = rawData.buffer.asUint8List();
    final rgb = Uint8List(image.width * image.height * 3);
    for (var source = 0, target = 0; source < rgba.length; source += 4) {
      rgb[target++] = rgba[source];
      rgb[target++] = rgba[source + 1];
      rgb[target++] = rgba[source + 2];
    }
    return pdfFromRgb(
      width: image.width,
      height: image.height,
      rgb: rgb,
    );
  }
}

class _DocumentPaper extends StatelessWidget {
  const _DocumentPaper(
      {required this.controller,
      required this.order,
      required this.customer,
      required this.isReceipt});

  final WorkOrderController controller;
  final WorkOrder order;
  final Customer? customer;
  final bool isReceipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E5EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 15, offset: Offset(0, 6)),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF1C2736)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.data.settings.shopName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${controller.data.settings.ownerName}\n${controller.data.settings.phone}\n${controller.data.settings.address}',
                        style: const TextStyle(
                            color: Color(0xFF607080),
                            fontSize: 14,
                            height: 1.55),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isReceipt ? '维修服务凭证' : '服务报价单',
                      style: const TextStyle(
                          color: _dialogTeal, fontSize: 14, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 7),
                    Text(order.number,
                        style: const TextStyle(
                            color: Color(0xFF607080),
                            fontSize: 14,
                            fontFamily: 'monospace')),
                    const SizedBox(height: 5),
                    Text(order.status.label,
                        style: const TextStyle(
                            color: Color(0xFF607080), fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: _dialogNavy, thickness: 2),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final customerMeta = _DocumentMeta(
                  label: '客户信息',
                  text:
                      '${customer?.name ?? '未关联客户'}\n${customer?.phone ?? '未填写电话'}\n${order.serviceAddress.isNotEmpty ? order.serviceAddress : customer?.address ?? '未填写地址'}',
                );
                final serviceMeta = _DocumentMeta(
                  label: '设备与服务',
                  text:
                      '${_dialogDevice(order)}\n${order.faultDescription}\n服务日期：${_dialogDate(order.appointmentAt ?? order.createdAt)}',
                );
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      customerMeta,
                      const SizedBox(height: 14),
                      serviceMeta,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: customerMeta),
                    const SizedBox(width: 20),
                    Expanded(child: serviceMeta),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Table(
              border: const TableBorder(
                horizontalInside: BorderSide(color: Color(0xFFE5E9F0)),
                bottom: BorderSide(color: Color(0xFFD8E0EA)),
              ),
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1.6),
                3: FlexColumnWidth(1.7),
              },
              children: [
                const TableRow(
                  children: [
                    _DocumentCell('服务项目', header: true),
                    _DocumentCell('数量', header: true),
                    _DocumentCell('单价', header: true),
                    _DocumentCell('小计', header: true, alignEnd: true),
                  ],
                ),
                ...order.items.map(
                  (item) => TableRow(
                    children: [
                      _DocumentCell(item.name),
                      _DocumentCell('${item.quantity} ${item.unit}'),
                      _DocumentCell(_dialogMoney(item.unitPrice)),
                      _DocumentCell(_dialogMoney(item.amount), alignEnd: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: Column(
                  children: [
                    _DocumentAmount(label: '项目小计', value: order.subtotal),
                    _DocumentAmount(label: '优惠金额', value: -order.discount),
                    _DocumentAmount(
                        label: isReceipt ? '最终应收' : '报价合计',
                        value: order.total,
                        strong: true),
                    if (isReceipt)
                      _DocumentAmount(
                        label: '已收 / 未收',
                        value: order.normalizedPaid,
                        suffix:
                            '${_dialogMoney(order.normalizedPaid)} / ${_dialogMoney(order.outstanding)}',
                      ),
                  ],
                ),
              ),
            ),
            if (isReceipt && order.result.isNotEmpty) ...[
              const SizedBox(height: 23),
              const Divider(color: Color(0xFFE0E5EB)),
              const SizedBox(height: 13),
              const Text('维修结果',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 5),
              Text(order.result,
                  style: const TextStyle(
                      color: Color(0xFF607080), fontSize: 14, height: 1.55)),
            ],
            if (order.customerNote.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('客户备注',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 5),
              Text(order.customerNote,
                  style: const TextStyle(
                      color: Color(0xFF607080), fontSize: 14, height: 1.55)),
            ],
            if (isReceipt && order.attachments.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('维修照片',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: order.attachments
                    .map((item) => _DocumentPhoto(attachment: item))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE0E5EB)),
            const SizedBox(height: 12),
            Text(
              controller.data.settings.defaultNote,
              style: const TextStyle(
                  color: Color(0xFF748191), fontSize: 14, height: 1.65),
            ),
            const SizedBox(height: 6),
            Text(
              isReceipt
                  ? '保修期限：${_dialogDate(order.warrantyStart)} 至 ${_dialogDate(order.warrantyEnd)}'
                  : '报价有效期：以现场沟通为准',
              style: const TextStyle(color: Color(0xFF748191), fontSize: 14),
            ),
            if (isReceipt && order.warrantyScope.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '保修范围：${order.warrantyScope}',
                  style:
                      const TextStyle(color: Color(0xFF748191), fontSize: 14),
                ),
              ),
            if (isReceipt && order.warrantyExclusions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '不保修说明：${order.warrantyExclusions}',
                  style:
                      const TextStyle(color: Color(0xFF748191), fontSize: 14),
                ),
              ),
            if (order.signatureData != null) ...[
              const SizedBox(height: 13),
              Align(
                alignment: Alignment.centerRight,
                child: _SignatureImage(data: order.signatureData!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentMeta extends StatelessWidget {
  const _DocumentMeta({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF9AA7A2), fontSize: 14)),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontSize: 14, height: 1.55)),
      ],
    );
  }
}

class _DocumentCell extends StatelessWidget {
  const _DocumentCell(this.text, {this.header = false, this.alignEnd = false});

  final String text;
  final bool header;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: header ? const Color(0xFF748191) : const Color(0xFF1C2736),
            fontSize: 14,
            fontWeight: header ? FontWeight.normal : FontWeight.w500,
            fontFamily: alignEnd && !header ? 'monospace' : null,
          ),
        ),
      ),
    );
  }
}

class _DocumentAmount extends StatelessWidget {
  const _DocumentAmount(
      {required this.label,
      required this.value,
      this.strong = false,
      this.suffix});

  final String label;
  final double value;
  final bool strong;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: strong ? const Color(0xFF1C2736) : const Color(0xFF607080),
              fontSize: 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            suffix ?? _dialogMoney(value),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: strong ? _dialogTeal : const Color(0xFF1C2736),
              fontSize: strong ? 15 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPhoto extends StatelessWidget {
  const _DocumentPhoto({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(attachment.path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 84,
        height: 66,
        child: bytes == null
            ? const ColoredBox(
                color: Color(0xFFE5E9F0), child: Icon(Icons.image_outlined))
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}

class _SignatureImage extends StatelessWidget {
  const _SignatureImage({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(data);
    return Column(
      children: [
        if (bytes != null)
          Image.memory(bytes, width: 150, height: 55, fit: BoxFit.contain),
        const SizedBox(width: 150, child: Divider(color: Color(0xFFCBD7D1))),
        const Text('客户确认签名',
            style: TextStyle(color: Color(0xFF748191), fontSize: 14)),
      ],
    );
  }
}
