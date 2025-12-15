// models/user.dart - UPDATE dengan properti KK yang lengkap

class User {
  final int id;
  final String namaLengkap;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? nik;
  final DateTime? tanggalLahir;
  final String? tempatLahir;
  final String? nomorTelepon;
  final String? instagram;
  final String? facebook;
  final String? alamat;
  final String? kota;
  final String? negara;
  final String? kodePos;
  final String? rtRw;
  final bool isVerified;
  final String? kkFileUrl;
  final int? reportCount;
  final int? emergencyCount;
  final int? activityCount;
  final String? bio;
  final bool? isOnline;

  // 🎯 NEW: KK Verification Properties
  final String? kkVerificationStatus;
  final String? kkRejectionReason;
  final DateTime? kkVerifiedAt;
  final String? kkVerifiedBy;
  final String? kkPublicId;

  User({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.nik,
    this.tanggalLahir,
    this.tempatLahir,
    this.nomorTelepon,
    this.instagram,
    this.facebook,
    this.alamat,
    this.kota,
    this.negara,
    this.kodePos,
    this.rtRw,
    this.isVerified = false,
    this.kkFileUrl,
    this.reportCount,
    this.emergencyCount,
    this.activityCount,
    this.bio,
    this.isOnline,

    // 🎯 NEW
    this.kkVerificationStatus,
    this.kkRejectionReason,
    this.kkVerifiedAt,
    this.kkVerifiedBy,
    this.kkPublicId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      namaLengkap: json['namaLengkap'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      nik: json['nik'],
      tanggalLahir: json['tanggalLahir'] != null
          ? DateTime.parse(json['tanggalLahir'])
          : null,
      tempatLahir: json['tempatLahir'],
      nomorTelepon: json['nomorTelepon'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      alamat: json['alamat'],
      kota: json['kota'],
      negara: json['negara'],
      kodePos: json['kodePos'],
      rtRw: json['rtRw'],
      isVerified: json['isVerified'] ?? false,
      kkFileUrl: json['kkFile'],
      reportCount: json['reportCount'],
      emergencyCount: json['emergencyCount'],
      activityCount: json['activityCount'],
      bio: json['bio'],
      isOnline: json['isOnline'],

      // 🎯 NEW
      kkVerificationStatus:
          json['kkVerificationStatus'] ??
          (json['isVerified'] == true ? 'verified' : 'pending'),
      kkRejectionReason: json['kkRejectionReason'],
      kkVerifiedAt: json['kkVerifiedAt'] != null
          ? DateTime.parse(json['kkVerifiedAt'])
          : null,
      kkVerifiedBy: json['kkVerifiedBy'],
      kkPublicId: json['kkFilePublicId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'namaLengkap': namaLengkap,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'nik': nik,
      'tanggalLahir': tanggalLahir?.toIso8601String(),
      'tempatLahir': tempatLahir,
      'nomorTelepon': nomorTelepon,
      'instagram': instagram,
      'facebook': facebook,
      'alamat': alamat,
      'kota': kota,
      'negara': negara,
      'kodePos': kodePos,
      'rtRw': rtRw,
      'isVerified': isVerified,
      'kkFile': kkFileUrl,
      'reportCount': reportCount,
      'emergencyCount': emergencyCount,
      'activityCount': activityCount,
      'bio': bio,
      'isOnline': isOnline,

      // 🎯 NEW
      'kkVerificationStatus': kkVerificationStatus,
      'kkRejectionReason': kkRejectionReason,
      'kkVerifiedAt': kkVerifiedAt?.toIso8601String(),
      'kkVerifiedBy': kkVerifiedBy,
      'kkFilePublicId': kkPublicId,
    };
  }

  Map<String, int> getStats() {
    return {
      'laporan': reportCount ?? 0,
      'darurat': emergencyCount ?? 0,
      'aktivitas': activityCount ?? 0,
    };
  }

  User copyWith({
    int? id,
    String? namaLengkap,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nik,
    DateTime? tanggalLahir,
    String? tempatLahir,
    String? nomorTelepon,
    String? instagram,
    String? facebook,
    String? alamat,
    String? kota,
    String? negara,
    String? kodePos,
    String? rtRw,
    bool? isVerified,
    String? kkFileUrl,
    int? reportCount,
    int? emergencyCount,
    int? activityCount,
    String? bio,
    bool? isOnline,

    // 🎯 NEW
    String? kkVerificationStatus,
    String? kkRejectionReason,
    DateTime? kkVerifiedAt,
    String? kkVerifiedBy,
    String? kkPublicId,
  }) {
    return User(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nik: nik ?? this.nik,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      nomorTelepon: nomorTelepon ?? this.nomorTelepon,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      alamat: alamat ?? this.alamat,
      kota: kota ?? this.kota,
      negara: negara ?? this.negara,
      kodePos: kodePos ?? this.kodePos,
      rtRw: rtRw ?? this.rtRw,
      isVerified: isVerified ?? this.isVerified,
      kkFileUrl: kkFileUrl ?? this.kkFileUrl,
      reportCount: reportCount ?? this.reportCount,
      emergencyCount: emergencyCount ?? this.emergencyCount,
      activityCount: activityCount ?? this.activityCount,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,

      // 🎯 NEW
      kkVerificationStatus: kkVerificationStatus ?? this.kkVerificationStatus,
      kkRejectionReason: kkRejectionReason ?? this.kkRejectionReason,
      kkVerifiedAt: kkVerifiedAt ?? this.kkVerifiedAt,
      kkVerifiedBy: kkVerifiedBy ?? this.kkVerifiedBy,
      kkPublicId: kkPublicId ?? this.kkPublicId,
    );
  }
}
