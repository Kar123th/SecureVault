class MedicalRecord {
  final int? id;
  final int userId;
  final String title;
  final String recordType; // prescription, lab_report, vaccination
  final DateTime date;
  final String? doctorName;
  final String? notes;
  final String? filePath;
  final DateTime? expiryDate;

  MedicalRecord({
    this.id,
    required this.userId,
    required this.title,
    required this.recordType,
    required this.date,
    this.doctorName,
    this.notes,
    this.filePath,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'record_type': recordType,
        'date': date.toIso8601String(),
        'doctor_name': doctorName,
        'notes': notes,
        'file_path': filePath,
        'expiry_date': expiryDate?.toIso8601String(),
      };

  static MedicalRecord fromJson(Map<String, dynamic> json) => MedicalRecord(
        id: json['id'] as int?,
        userId: json['user_id'] as int,
        title: json['title'] as String,
        recordType: json['record_type'] as String,
        date: DateTime.parse(json['date'] as String),
        doctorName: json['doctor_name'] as String?,
        notes: json['notes'] as String?,
        filePath: json['file_path'] as String?,
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
      );
}
