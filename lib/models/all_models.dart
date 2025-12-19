// --- Personal Documents ---
class PersonalDocument {
  final int? id;
  final int userId;
  final String category; // aadhar, pan, passport
  final String documentName;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? filePath;

  PersonalDocument({this.id, required this.userId, required this.category, required this.documentName, this.documentNumber, this.issueDate, this.expiryDate, this.filePath});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'category': category, 'document_name': documentName, 'document_number': documentNumber,
    'issue_date': issueDate?.toIso8601String(), 'expiry_date': expiryDate?.toIso8601String(), 'file_path': filePath,
  };

  static PersonalDocument fromJson(Map<String, dynamic> json) => PersonalDocument(
    id: json['id'], userId: json['user_id'], category: json['category'], documentName: json['document_name'], documentNumber: json['document_number'],
    issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : null,
    expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    filePath: json['file_path'],
  );
}

// --- Vehicle Info ---
class VehicleRecord {
  final int? id;
  final int userId;
  final String vehicleType;
  final String regNumber;
  final String documentType; // RC, Insurance
  final DateTime? expiryDate;
  final String? filePath;

  VehicleRecord({this.id, required this.userId, required this.vehicleType, required this.regNumber, required this.documentType, this.expiryDate, this.filePath});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'vehicle_type': vehicleType, 'reg_number': regNumber, 'document_type': documentType,
    'expiry_date': expiryDate?.toIso8601String(), 'file_path': filePath,
  };

  static VehicleRecord fromJson(Map<String, dynamic> json) => VehicleRecord(
    id: json['id'], userId: json['user_id'], vehicleType: json['vehicle_type'], regNumber: json['reg_number'], documentType: json['document_type'],
    expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    filePath: json['file_path'],
  );
}

// --- Financial Records ---
class FinancialRecord {
  final int? id;
  final int userId;
  final String recordType; // Bank, Loan, Tax
  final String institutionName;
  final String? accountNumber;
  final String? notes;
  final String? filePath;

  FinancialRecord({this.id, required this.userId, required this.recordType, required this.institutionName, this.accountNumber, this.notes, this.filePath});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'record_type': recordType, 'institution_name': institutionName, 'account_number': accountNumber, 'notes': notes, 'file_path': filePath,
  };

  static FinancialRecord fromJson(Map<String, dynamic> json) => FinancialRecord(
    id: json['id'], userId: json['user_id'], recordType: json['record_type'], institutionName: json['institution_name'], accountNumber: json['account_number'], notes: json['notes'], filePath: json['file_path'],
  );
}

// --- Education Records ---
class EducationRecord {
  final int? id;
  final int userId;
  final String degreeName;
  final String institution;
  final String? yearOfPassing;
  final String? grade;
  final String? filePath;

  EducationRecord({this.id, required this.userId, required this.degreeName, required this.institution, this.yearOfPassing, this.grade, this.filePath});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'degree_name': degreeName, 'institution': institution, 'year_of_passing': yearOfPassing, 'grade': grade, 'file_path': filePath,
  };

  static EducationRecord fromJson(Map<String, dynamic> json) => EducationRecord(
    id: json['id'], userId: json['user_id'], degreeName: json['degree_name'], institution: json['institution'], yearOfPassing: json['year_of_passing'], grade: json['grade'], filePath: json['file_path'],
  );
}

// --- Home Records ---
class HomeRecord {
  final int? id;
  final int userId;
  final String itemName;
  final String? brand;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final String? billNumber;
  final String? filePath;

  HomeRecord({this.id, required this.userId, required this.itemName, this.brand, this.purchaseDate, this.warrantyExpiry, this.billNumber, this.filePath});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'item_name': itemName, 'brand': brand, 'purchase_date': purchaseDate?.toIso8601String(),
    'warranty_expiry': warrantyExpiry?.toIso8601String(), 'bill_number': billNumber, 'file_path': filePath,
  };

  static HomeRecord fromJson(Map<String, dynamic> json) => HomeRecord(
    id: json['id'], userId: json['user_id'], itemName: json['item_name'], brand: json['brand'],
    purchaseDate: json['purchase_date'] != null ? DateTime.parse(json['purchase_date']) : null,
    warrantyExpiry: json['warranty_expiry'] != null ? DateTime.parse(json['warranty_expiry']) : null,
    billNumber: json['bill_number'], filePath: json['file_path'],
  );
}

// --- Travel Docs ---
class TravelDoc {
  final int? id;
  final int userId;
  final String docType; // Passport, Visa
  final String? country;
  final String? docNumber;
  final DateTime? expiryDate;
  final String? filePath;

  TravelDoc({this.id, required this.userId, required this.docType, this.country, this.docNumber, this.expiryDate, this.filePath});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'doc_type': docType, 'country': country, 'doc_number': docNumber,
    'expiry_date': expiryDate?.toIso8601String(), 'file_path': filePath,
  };

  static TravelDoc fromJson(Map<String, dynamic> json) => TravelDoc(
    id: json['id'], userId: json['user_id'], docType: json['doc_type'], country: json['country'], docNumber: json['doc_number'],
    expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    filePath: json['file_path'],
  );
}

// --- Emergency Info ---
class EmergencyInfo {
  final int? id;
  final int userId;
  final String infoType; // Contact, Allergy
  final String name;
  final String value;
  final String? notes;

  EmergencyInfo({this.id, required this.userId, required this.infoType, required this.name, required this.value, this.notes});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'info_type': infoType, 'name': name, 'value': value, 'notes': notes,
  };

  static EmergencyInfo fromJson(Map<String, dynamic> json) => EmergencyInfo(
    id: json['id'], userId: json['user_id'], infoType: json['info_type'], name: json['name'], value: json['value'], notes: json['notes'],
  );
}

// --- Password Manager ---
class PasswordItem {
  final int? id;
  final int userId;
  final String accountName;
  final String username;
  final String password;
  final String? website;
  final String? notes;

  PasswordItem({this.id, required this.userId, required this.accountName, required this.username, required this.password, this.website, this.notes});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'account_name': accountName, 'username': username, 'password': password, 'website': website, 'notes': notes,
  };

  static PasswordItem fromJson(Map<String, dynamic> json) => PasswordItem(
    id: json['id'], userId: json['user_id'], accountName: json['account_name'], username: json['username'], password: json['password'], website: json['website'], notes: json['notes'],
  );
}

// --- Reminders ---
class ReminderItem {
  final int? id;
  final int userId;
  final String title;
  final String category; // Electricity, Insurance, SIP, Other
  final DateTime reminderDate;
  final bool isCompleted;
  final String? notes;

  ReminderItem({this.id, required this.userId, required this.title, required this.category, required this.reminderDate, this.isCompleted = false, this.notes});

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'title': title, 'category': category, 'reminder_date': reminderDate.toIso8601String(), 'is_completed': isCompleted ? 1 : 0, 'notes': notes,
  };

  static ReminderItem fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'], userId: json['user_id'], title: json['title'], category: json['category'], 
    reminderDate: DateTime.parse(json['reminder_date']),
    isCompleted: json['is_completed'] == 1,
    notes: json['notes'],
  );
}
