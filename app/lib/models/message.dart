import 'package:intl/intl.dart';
import 'office.dart';
import 'user.dart';
import 'parcel.dart';

class Message {
  final String id;
  final String fromOfficeId;
  final String toOfficeId;
  final String fromUserId;
  final String subject;
  final String content;
  final String? relatedParcelId;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final Office? fromOffice;
  final Office? toOffice;
  final User? fromUser;
  final Parcel? relatedParcel;

  Message({
    required this.id,
    required this.fromOfficeId,
    required this.toOfficeId,
    required this.fromUserId,
    required this.subject,
    required this.content,
    this.relatedParcelId,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.fromOffice,
    this.toOffice,
    this.fromUser,
    this.relatedParcel,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      fromOfficeId: json['fromOfficeId'],
      toOfficeId: json['toOfficeId'],
      fromUserId: json['fromUserId'],
      subject: json['subject'],
      content: json['content'],
      relatedParcelId: json['relatedParcelId'],
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      fromOffice: json['fromOffice'] != null
          ? Office.fromJson(json['fromOffice'])
          : null,
      toOffice: json['toOffice'] != null
          ? Office.fromJson(json['toOffice'])
          : null,
      fromUser: json['fromUser'] != null
          ? User.fromJson(json['fromUser'])
          : null,
      relatedParcel: json['relatedParcel'] != null
          ? Parcel.fromJson(json['relatedParcel'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromOfficeId': fromOfficeId,
      'toOfficeId': toOfficeId,
      'fromUserId': fromUserId,
      'subject': subject,
      'content': content,
      'relatedParcelId': relatedParcelId,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fromOffice': fromOffice?.toJson(),
      'toOffice': toOffice?.toJson(),
      'fromUser': fromUser?.toJson(),
      'relatedParcel': relatedParcel?.toJson(),
    };
  }

  bool get isRead => readAt != null;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }
}

