import '../models/all_models.dart';
import '../screens/generic_module_screen.dart';

// --- Simple Config Implementations ---

class PersonalDocConfig extends ModuleConfig<PersonalDocument> {
  @override String get title => 'Personal Documents';
  @override String get tableName => 'personal_documents';
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'document_name', label: 'Document Name', required: true),
    FieldConfig(key: 'category', label: 'Category', type: FieldType.dropdown, options: ['Aadhar', 'PAN', 'Passport', 'Driving License', 'Other']),
    FieldConfig(key: 'document_number', label: 'Document Number'),
    FieldConfig(key: 'issue_date', label: 'Issue Date', type: FieldType.date),
    FieldConfig(key: 'expiry_date', label: 'Expiry Date', type: FieldType.date),
    FieldConfig(key: 'file_path', label: 'Scan Copy', type: FieldType.file),
  ];

  @override PersonalDocument fromJson(Map<String, dynamic> json) => PersonalDocument.fromJson(json);
  @override Map<String, dynamic> toJson(PersonalDocument item) => item.toJson();
  
  @override String getTitle(PersonalDocument item) => item.documentName;
  @override String getSubtitle(PersonalDocument item) => '${item.category} • ${item.documentNumber ?? ''}';
  @override String? getFilePath(PersonalDocument item) => item.filePath;
}

class VehicleConfig extends ModuleConfig<VehicleRecord> {
  @override String get title => 'Vehicle Information';
  @override String get tableName => 'vehicle_info';
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'reg_number', label: 'Registration Number', required: true),
    FieldConfig(key: 'vehicle_type', label: 'Vehicle Type', type: FieldType.dropdown, options: ['Car', 'Bike', 'Scooter', 'Truck', 'Other']),
    FieldConfig(key: 'document_type', label: 'Document Type', type: FieldType.dropdown, options: ['RC Book', 'Insurance', 'PUC', 'Service Record']),
    FieldConfig(key: 'expiry_date', label: 'Valid Until', type: FieldType.date),
    FieldConfig(key: 'file_path', label: 'Document Photo', type: FieldType.file),
  ];

  @override VehicleRecord fromJson(Map<String, dynamic> json) => VehicleRecord.fromJson(json);
  @override Map<String, dynamic> toJson(VehicleRecord item) => item.toJson();
  
  @override String getTitle(VehicleRecord item) => '${item.vehicleType} - ${item.reg_number}';
  @override String getSubtitle(VehicleRecord item) => item.documentType;
  @override String? getFilePath(VehicleRecord item) => item.filePath;
}

class FinancialConfig extends ModuleConfig<FinancialRecord> {
  @override String get title => 'Financial Records';
  @override String get tableName => 'financial_records'; // Fixed table name match
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'institution_name', label: 'Bank/Institution', required: true),
    FieldConfig(key: 'record_type', label: 'Type', type: FieldType.dropdown, options: ['Bank Account', 'Credit Card', 'Loan', 'Insurance', 'Tax', 'Investment']),
    FieldConfig(key: 'account_number', label: 'Account/Policy Number'),
    FieldConfig(key: 'notes', label: 'Notes'),
    FieldConfig(key: 'file_path', label: 'Statement/Doc', type: FieldType.file),
  ];

  @override FinancialRecord fromJson(Map<String, dynamic> json) => FinancialRecord.fromJson(json);
  @override Map<String, dynamic> toJson(FinancialRecord item) => item.toJson();
  
  @override String getTitle(FinancialRecord item) => item.institutionName;
  @override String getSubtitle(FinancialRecord item) => '${item.recordType} • ${item.accountNumber ?? ''}';
  @override String? getFilePath(FinancialRecord item) => item.filePath;
}

class EducationConfig extends ModuleConfig<EducationRecord> {
  @override String get title => 'Education';
  @override String get tableName => 'education_records';
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'degree_name', label: 'Degree/Certificate', required: true),
    FieldConfig(key: 'institution', label: 'Institution/Board', required: true),
    FieldConfig(key: 'year_of_passing', label: 'Year of Passing'),
    FieldConfig(key: 'grade', label: 'Grade/Percentage'),
    FieldConfig(key: 'file_path', label: 'Certificate Copy', type: FieldType.file),
  ];

  @override EducationRecord fromJson(Map<String, dynamic> json) => EducationRecord.fromJson(json);
  @override Map<String, dynamic> toJson(EducationRecord item) => item.toJson();
  
  @override String getTitle(EducationRecord item) => item.degreeName;
  @override String getSubtitle(EducationRecord item) => item.institution;
  @override String? getFilePath(EducationRecord item) => item.filePath;
}

class HomeConfig extends ModuleConfig<HomeRecord> {
  @override String get title => 'Home & Warranties';
  @override String get tableName => 'home_records';
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'item_name', label: 'Item Name', required: true),
    FieldConfig(key: 'brand', label: 'Brand/Manufacturer'),
    FieldConfig(key: 'bill_number', label: 'Bill/Invoice Number'),
    FieldConfig(key: 'purchase_date', label: 'Purchase Date', type: FieldType.date),
    FieldConfig(key: 'warranty_expiry', label: 'Warranty Expiry', type: FieldType.date),
    FieldConfig(key: 'file_path', label: 'Bill/Warranty Card', type: FieldType.file),
  ];

  @override HomeRecord fromJson(Map<String, dynamic> json) => HomeRecord.fromJson(json);
  @override Map<String, dynamic> toJson(HomeRecord item) => item.toJson();
  
  @override String getTitle(HomeRecord item) => item.itemName;
  @override String getSubtitle(HomeRecord item) => item.brand ?? '';
  @override String? getFilePath(HomeRecord item) => item.filePath;
}

class TravelConfig extends ModuleConfig<TravelDoc> {
  @override String get title => 'Travel Documents';
  @override String get tableName => 'travel_docs';
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'doc_type', label: 'Document Type', type: FieldType.dropdown, options: ['Passport', 'Visa', 'Ticket', 'Travel Insurance']),
    FieldConfig(key: 'country', label: 'Country (if applicable)'),
    FieldConfig(key: 'doc_number', label: 'Passport/Doc Number'),
    FieldConfig(key: 'expiry_date', label: 'Expiry/Travel Date', type: FieldType.date),
    FieldConfig(key: 'file_path', label: 'File', type: FieldType.file),
  ];

  @override TravelDoc fromJson(Map<String, dynamic> json) => TravelDoc.fromJson(json);
  @override Map<String, dynamic> toJson(TravelDoc item) => item.toJson();
  
  @override String getTitle(TravelDoc item) => item.docType;
  @override String getSubtitle(TravelDoc item) => item.country ?? '';
  @override String? getFilePath(TravelDoc item) => item.filePath;
}

class EmergencyConfig extends ModuleConfig<EmergencyInfo> {
  @override String get title => 'Emergency Info';
  @override String get tableName => 'emergency_info';
  
  @override
  List<FieldConfig> get fields => [
    FieldConfig(key: 'name', label: 'Contact Name / Allergy', required: true),
    FieldConfig(key: 'info_type', label: 'Type', type: FieldType.dropdown, options: ['Emergency Contact', 'Blood Group', 'Allergy', 'Medication', 'Doctor']),
    FieldConfig(key: 'value', label: 'Phone Number / Details', required: true),
    FieldConfig(key: 'notes', label: 'Notes'),
  ];

  @override EmergencyInfo fromJson(Map<String, dynamic> json) => EmergencyInfo.fromJson(json);
  @override Map<String, dynamic> toJson(EmergencyInfo item) => item.toJson();
  
  @override String getTitle(EmergencyInfo item) => item.name;
  @override String getSubtitle(EmergencyInfo item) => '${item.infoType}: ${item.value}';
  @override String? getFilePath(EmergencyInfo item) => null;
}
