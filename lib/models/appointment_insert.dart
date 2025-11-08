class AppointmentInsert {
  final int id;
  final int advisorId;
  final int clientId;
  final String time;
  final String appointmentNo;
  final int status;
  final int type;
  final int paymentStatus;
  final int source;
  final String clientName;
  final String clientSurname;
  final String clientTcId;
  final double paymentAmount;
  final String paymentExp;
  final String iptalExp;
  final String unitName;
  final int unitId;
  final String advisorName;
  final String reference;
  final bool isAccess;
  final String? image; // Resim alanı
  final String? notes; // Notlar alanı
  final DateTime? createdAt; // Oluşturulma tarihi
  final DateTime? updatedAt; // Güncellenme tarihi

  const AppointmentInsert({
    required this.id,
    required this.advisorId,
    required this.clientId,
    required this.time,
    required this.appointmentNo,
    required this.status,
    required this.type,
    required this.paymentStatus,
    required this.source,
    required this.clientName,
    required this.clientSurname,
    required this.clientTcId,
    required this.paymentAmount,
    required this.paymentExp,
    required this.iptalExp,
    required this.unitName,
    required this.unitId,
    required this.advisorName,
    required this.reference,
    required this.isAccess,
    this.image,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // JSON'dan AppointmentInsert nesnesi oluştur
  factory AppointmentInsert.fromJson(Map<String, dynamic> json) {
    return AppointmentInsert(
      id: json['id'] ?? 0,
      advisorId: json['advisorId'] ?? 0,
      clientId: json['clientId'] ?? 0,
      time: json['time'] ?? '',
      appointmentNo: json['appointmentNo'] ?? '',
      status: json['status'] ?? 0,
      type: json['type'] ?? 0,
      paymentStatus: json['paymentStatus'] ?? 0,
      source: json['source'] ?? 0,
      clientName: json['clientName'] ?? '',
      clientSurname: json['clientSurname'] ?? '',
      clientTcId: json['clientTcId'] ?? '',
      paymentAmount: (json['paymentAmount'] ?? 0).toDouble(),
      paymentExp: json['paymentExp'] ?? '',
      iptalExp: json['iptalExp'] ?? '',
      unitName: json['unitName'] ?? '',
      unitId: json['unitId'] ?? 0,
      advisorName: json['advisorName'] ?? '',
      reference: json['reference'] ?? '',
      isAccess: json['isAccess'] ?? false,
      image: json['image'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // AppointmentInsert nesnesini JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advisorId': advisorId,
      'clientId': clientId,
      'time': time,
      'appointmentNo': appointmentNo,
      'status': status,
      'type': type,
      'paymentStatus': paymentStatus,
      'source': source,
      'clientName': clientName,
      'clientSurname': clientSurname,
      'clientTcId': clientTcId,
      'paymentAmount': paymentAmount,
      'paymentExp': paymentExp,
      'iptalExp': iptalExp,
      'unitName': unitName,
      'unitId': unitId,
      'advisorName': advisorName,
      'reference': reference,
      'isAccess': isAccess,
      if (image != null) 'image': image,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // API için minimal JSON (sadece gerekli alanlar)
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'advisorId': advisorId,
      'clientId': clientId,
      'time': time,
      'appointmentNo': appointmentNo,
      'status': status,
      'type': type,
      'paymentStatus': paymentStatus,
      'source': source,
      'clientName': clientName,
      'clientSurname': clientSurname,
      'clientTcId': clientTcId,
      'paymentAmount': paymentAmount,
      'paymentExp': paymentExp,
      'iptalExp': iptalExp,
      'unitName': unitName,
      'unitId': unitId,
      'advisorName': advisorName,
      'reference': reference,
      'isAccess': isAccess,
    };
  }

  // Kopya oluştur (belirli alanları değiştirerek)
  AppointmentInsert copyWith({
    int? id,
    int? advisorId,
    int? clientId,
    String? time,
    String? appointmentNo,
    int? status,
    int? type,
    int? paymentStatus,
    int? source,
    String? clientName,
    String? clientSurname,
    String? clientTcId,
    double? paymentAmount,
    String? paymentExp,
    String? iptalExp,
    String? unitName,
    int? unitId,
    String? advisorName,
    String? reference,
    bool? isAccess,
    String? image,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentInsert(
      id: id ?? this.id,
      advisorId: advisorId ?? this.advisorId,
      clientId: clientId ?? this.clientId,
      time: time ?? this.time,
      appointmentNo: appointmentNo ?? this.appointmentNo,
      status: status ?? this.status,
      type: type ?? this.type,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      source: source ?? this.source,
      clientName: clientName ?? this.clientName,
      clientSurname: clientSurname ?? this.clientSurname,
      clientTcId: clientTcId ?? this.clientTcId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentExp: paymentExp ?? this.paymentExp,
      iptalExp: iptalExp ?? this.iptalExp,
      unitName: unitName ?? this.unitName,
      unitId: unitId ?? this.unitId,
      advisorName: advisorName ?? this.advisorName,
      reference: reference ?? this.reference,
      isAccess: isAccess ?? this.isAccess,
      image: image ?? this.image,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Güzel yazdırma
  @override
  String toString() {
    return 'AppointmentInsert{\n'
        '  id: $id,\n'
        '  advisorId: $advisorId,\n'
        '  clientId: $clientId,\n'
        '  time: $time,\n'
        '  appointmentNo: $appointmentNo,\n'
        '  status: $status,\n'
        '  type: $type,\n'
        '  paymentStatus: $paymentStatus,\n'
        '  source: $source,\n'
        '  clientName: $clientName,\n'
        '  clientSurname: $clientSurname,\n'
        '  clientTcId: $clientTcId,\n'
        '  paymentAmount: $paymentAmount,\n'
        '  paymentExp: $paymentExp,\n'
        '  iptalExp: $iptalExp,\n'
        '  unitName: $unitName,\n'
        '  unitId: $unitId,\n'
        '  advisorName: $advisorName,\n'
        '  reference: $reference,\n'
        '  isAccess: $isAccess,\n'
        '  image: $image,\n'
        '  notes: $notes,\n'
        '  createdAt: $createdAt,\n'
        '  updatedAt: $updatedAt\n'
        '}';
  }

  // Eşitlik kontrolü
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentInsert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          advisorId == other.advisorId &&
          clientId == other.clientId &&
          time == other.time &&
          appointmentNo == other.appointmentNo &&
          status == other.status &&
          type == other.type &&
          paymentStatus == other.paymentStatus &&
          source == other.source &&
          clientName == other.clientName &&
          clientSurname == other.clientSurname &&
          clientTcId == other.clientTcId &&
          paymentAmount == other.paymentAmount &&
          paymentExp == other.paymentExp &&
          iptalExp == other.iptalExp &&
          unitName == other.unitName &&
          unitId == other.unitId &&
          advisorName == other.advisorName &&
          reference == other.reference &&
          isAccess == other.isAccess &&
          image == other.image &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      advisorId.hashCode ^
      clientId.hashCode ^
      time.hashCode ^
      appointmentNo.hashCode ^
      status.hashCode ^
      type.hashCode ^
      paymentStatus.hashCode ^
      source.hashCode ^
      clientName.hashCode ^
      clientSurname.hashCode ^
      clientTcId.hashCode ^
      paymentAmount.hashCode ^
      paymentExp.hashCode ^
      iptalExp.hashCode ^
      unitName.hashCode ^
      unitId.hashCode ^
      advisorName.hashCode ^
      reference.hashCode ^
      isAccess.hashCode ^
      image.hashCode ^
      notes.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}

// Helper sınıfı - Appointment durumları için
class AppointmentStatus {
  static const int pending = 0;      // Beklemede
  static const int confirmed = 1;    // Onaylandı
  static const int cancelled = 2;    // İptal edildi
  static const int completed = 3;    // Tamamlandı
  static const int rescheduled = 4;  // Yeniden planlandı

  static String getStatusText(int status) {
    switch (status) {
      case pending:
        return 'Beklemede';
      case confirmed:
        return 'Onaylandı';
      case cancelled:
        return 'İptal Edildi';
      case completed:
        return 'Tamamlandı';
      case rescheduled:
        return 'Yeniden Planlandı';
      default:
        return 'Bilinmeyen';
    }
  }
}

// Helper sınıfı - Appointment tipleri için
class AppointmentType {
  static const int consultation = 1;  // Danışmanlık
  static const int examination = 2;   // Muayene
  static const int therapy = 3;       // Terapi
  static const int followUp = 4;      // Takip

  static String getTypeText(int type) {
    switch (type) {
      case consultation:
        return 'Danışmanlık';
      case examination:
        return 'Muayene';
      case therapy:
        return 'Terapi';
      case followUp:
        return 'Takip';
      default:
        return 'Bilinmeyen';
    }
  }
}

// Helper sınıfı - Payment durumları için
class PaymentStatus {
  static const int pending = 0;      // Ödeme bekliyor
  static const int paid = 1;         // Ödendi
  static const int failed = 2;       // Ödeme başarısız
  static const int refunded = 3;     // İade edildi

  static String getPaymentStatusText(int status) {
    switch (status) {
      case pending:
        return 'Ödeme Bekliyor';
      case paid:
        return 'Ödendi';
      case failed:
        return 'Ödeme Başarısız';
      case refunded:
        return 'İade Edildi';
      default:
        return 'Bilinmeyen';
    }
  }
}
