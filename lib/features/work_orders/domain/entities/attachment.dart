part of 'work_order.dart';

class Attachment {
  const Attachment({
    required this.id,
    required this.category,
    required this.path,
    this.caption = '',
    required this.createdAt,
  });

  final String id;
  final String category;
  final String path;
  final String caption;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'category': category,
        'path': path,
        'caption': caption,
        'createdAt': dateString(createdAt),
      };

  factory Attachment.fromJson(Map<String, Object?> json) => Attachment(
        id: json['id']?.toString() ?? '',
        category: json['category']?.toString() ?? 'before',
        path: json['path']?.toString() ?? '',
        caption: json['caption']?.toString() ?? '',
        createdAt: dateValue(json['createdAt']) ?? DateTime.now(),
      );
}
