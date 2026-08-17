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
    final currencySymbol = controller.data.settings.currencySymbol;
    final customer = controller.customerById(order.customerId);
    final isReceipt = kind == 'receipt';
    final title = context.tr(isReceipt ? '维修服务凭证' : '服务报价单');
    final summary = [
      title,
      context.trf('工单号：{number}', {'number': order.number}),
      context.trf(
          '客户：{customer}', {'customer': customer?.name ?? context.tr('未关联')}),
      context.trf(
          '设备：{device}', {'device': _dialogDeviceLocalized(context, order)}),
      context.trf(
        '应收：{amount}',
        {
          'amount': _dialogMoney(
            order.total,
            currencySymbol: currencySymbol,
          ),
        },
      ),
      context.trf('已收：{amount}', {
        'amount': _dialogMoney(
          order.normalizedPaid,
          currencySymbol: currencySymbol,
        ),
      }),
      controller.data.settings.shopName,
    ].join('\n');
    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            _DialogHeader(
              kicker: 'DOCUMENT / PREVIEW',
              title: context.trf('{title}预览', {'title': title}),
              subtitle: context.tr(
                '确认内容后，可以复制摘要、分享或保存单据文件。',
              ),
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
                    currencySymbol: currencySymbol,
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
                      if (context.mounted) {
                        showTopNotice(context, context.tr('摘要已复制。'));
                      }
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: Text(context.tr('复制摘要')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _shareDocument(asPdf: false),
                    icon: const Icon(Icons.share_outlined, size: 14),
                    label: Text(context.tr('分享 PNG')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveDocument(asPdf: false),
                    icon: const Icon(Icons.save_alt_outlined, size: 16),
                    label: Text(context.tr('保存 PNG')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _shareDocument(asPdf: true),
                    icon: const Icon(Icons.share_outlined, size: 14),
                    label: Text(context.tr('分享 PDF')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveDocument(asPdf: true),
                    icon: const Icon(Icons.save_alt_outlined, size: 16),
                    label: Text(context.tr('保存 PDF')),
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
    final title = context.tr(kind == 'receipt' ? '维修服务凭证' : '服务报价单');
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
        dialogTitle: context.trf(
          '保存{format}到本地',
          {'format': asPdf ? 'PDF' : 'PNG'},
        ),
        fileName: fileName,
        bytes: content,
        extension: extension,
      );
      if (!mounted || path == null) return;
      showTopNotice(
        context,
        context.trf('已保存到本地：{fileName}', {'fileName': fileName}),
      );
    } catch (_) {
      if (!mounted) return;
      showTopNotice(
        context,
        context.tr('保存失败，请重新选择保存位置。'),
        error: true,
      );
    }
  }

  Future<Uint8List?> _renderDocument({required bool asPdf}) async {
    final renderObject = _documentKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      if (mounted) {
        showTopNotice(
          context,
          context.tr('单据还没有渲染完成，请稍后再试。'),
          error: true,
        );
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
        showTopNotice(
          context,
          context.tr('单据导出失败，请稍后再试。'),
          error: true,
        );
        return null;
      }
      return content;
    } finally {
      image.dispose();
    }
  }

  String _documentFileName({required bool asPdf}) {
    final extension = asPdf ? 'pdf' : 'png';
    final number = controller.orderById(orderId)?.number ?? context.tr('单据');
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
      required this.currencySymbol,
      required this.isReceipt});

  final WorkOrderController controller;
  final WorkOrder order;
  final Customer? customer;
  final String currencySymbol;
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
                      context.tr(isReceipt ? '维修服务凭证' : '服务报价单'),
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
                    Text(workOrderStatusText(context, order.status),
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
                  label: context.tr('客户信息'),
                  text: '${customer?.name ?? context.tr('未关联客户')}\n'
                      '${customer?.phone ?? context.tr('未填写电话')}\n'
                      '${order.serviceAddress.isNotEmpty ? order.serviceAddress : customer?.address ?? context.tr('未填写地址')}',
                );
                final serviceMeta = _DocumentMeta(
                  label: context.tr('设备与服务'),
                  text: '${_dialogDeviceLocalized(context, order)}\n'
                      '${order.faultDescription}\n'
                      '${context.tr('服务日期：')}'
                      '${_dialogDateLocalized(context, order.appointmentAt ?? order.createdAt)}',
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
                TableRow(
                  children: [
                    _DocumentCell(context.tr('服务项目'), header: true),
                    _DocumentCell(context.tr('数量'), header: true),
                    _DocumentCell(context.tr('单价'), header: true),
                    _DocumentCell(
                      context.tr('小计'),
                      header: true,
                      alignEnd: true,
                    ),
                  ],
                ),
                ...order.items.map(
                  (item) => TableRow(
                    children: [
                      _DocumentCell(localizedWorkOrderItemName(context, item)),
                      _DocumentCell(
                        '${item.quantity} ${localizedWorkOrderItemUnit(context, item)}',
                      ),
                      _DocumentCell(
                        _dialogMoney(
                          item.unitPrice,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                      _DocumentCell(
                        _dialogMoney(
                          item.amount,
                          currencySymbol: currencySymbol,
                        ),
                        alignEnd: true,
                      ),
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
                    _DocumentAmount(
                      label: context.tr('项目小计'),
                      value: order.subtotal,
                      currencySymbol: currencySymbol,
                    ),
                    _DocumentAmount(
                      label: context.tr('优惠金额'),
                      value: -order.discount,
                      currencySymbol: currencySymbol,
                    ),
                    _DocumentAmount(
                      label: context.tr(isReceipt ? '最终应收' : '报价合计'),
                      value: order.total,
                      currencySymbol: currencySymbol,
                      strong: true,
                    ),
                    if (isReceipt)
                      _DocumentAmount(
                        label: context.tr('已收 / 未收'),
                        value: order.normalizedPaid,
                        currencySymbol: currencySymbol,
                        suffix: '${_dialogMoney(
                          order.normalizedPaid,
                          currencySymbol: currencySymbol,
                        )} / ${_dialogMoney(
                          order.outstanding,
                          currencySymbol: currencySymbol,
                        )}',
                      ),
                  ],
                ),
              ),
            ),
            if (isReceipt && order.result.isNotEmpty) ...[
              const SizedBox(height: 23),
              const Divider(color: Color(0xFFE0E5EB)),
              const SizedBox(height: 13),
              Text(context.tr('维修结果'),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 5),
              Text(order.result,
                  style: const TextStyle(
                      color: Color(0xFF607080), fontSize: 14, height: 1.55)),
            ],
            if (_workOrderNote(order).isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(context.tr('备注'),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 5),
              Text(_workOrderNote(order),
                  style: const TextStyle(
                      color: Color(0xFF607080), fontSize: 14, height: 1.55)),
            ],
            if (isReceipt && order.attachments.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(context.tr('维修照片'),
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
                  ? context.trf(
                      '保修期限：{start} 至 {end}',
                      {
                        'start':
                            _dialogDateLocalized(context, order.warrantyStart),
                        'end': _dialogDateLocalized(context, order.warrantyEnd),
                      },
                    )
                  : context.tr('报价有效期：以现场沟通为准'),
              style: const TextStyle(color: Color(0xFF748191), fontSize: 14),
            ),
            if (isReceipt && order.warrantyScope.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.trf(
                    '保修范围：{scope}',
                    {'scope': order.warrantyScope},
                  ),
                  style:
                      const TextStyle(color: Color(0xFF748191), fontSize: 14),
                ),
              ),
            if (isReceipt && order.warrantyExclusions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.trf(
                    '不保修说明：{exclusions}',
                    {'exclusions': order.warrantyExclusions},
                  ),
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
      required this.currencySymbol,
      this.strong = false,
      this.suffix});

  final String label;
  final double value;
  final String currencySymbol;
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
            suffix ?? _dialogMoney(value, currencySymbol: currencySymbol),
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
        Text(context.tr('客户确认签名'),
            style: TextStyle(color: Color(0xFF748191), fontSize: 14)),
      ],
    );
  }
}
