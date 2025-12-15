// models/kk_verification.dart
import 'package:flutter/material.dart';

class KKVerification {
  final String? fileUrl;
  final String? publicId;
  final String status; // 'pending', 'verified', 'rejected'
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  KKVerification({
    this.fileUrl,
    this.publicId,
    required this.status,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory KKVerification.fromJson(Map<String, dynamic> json) {
    return KKVerification(
      fileUrl: json['kkFile'],
      publicId: json['kkFilePublicId'],
      status: _parseStatus(json),
      rejectionReason: json['kkRejectionReason'],
      verifiedAt: json['kkVerifiedAt'] != null
          ? DateTime.parse(json['kkVerifiedAt'])
          : null,
      verifiedBy: json['kkVerifiedBy'],
    );
  }

  static String _parseStatus(Map<String, dynamic> json) {
    if (json['isVerified'] == true) {
      return 'verified';
    }
    return json['kkVerificationStatus'] ?? 'pending';
  }

  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';

  Color get statusColor {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.pending;
    }
  }

  String get statusText {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }
}
