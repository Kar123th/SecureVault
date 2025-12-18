import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw Exception("Database not initialized! Call init(password) first.");
  }

  Future<void> init(String password) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'secure_vault.db');
    
    // On Android/iOS, this uses SQLCipher with encryption.
    // On Windows/Linux (if running via FFI), this might default to unencrypted 
    // depending on the loaded libs, but since we are targeting Android now,
    // this will provide the full security.
    
    _database = await openDatabase(
      path,
      version: 1,
      password: password,
      onCreate: _createDB,
    );
     print("🔒 SECURE VAULT INITIALIZED WITH ENCRYPTION 🔒");
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';

    // Users Table
    await db.execute('''
CREATE TABLE users (
  id $idType,
  password_hash $textType,
  biometric_enabled $intType,
  created_at $textType
)
''');

    // Medical Records
    await db.execute('''
CREATE TABLE medical_records (
  id $idType,
  user_id $intType,
  title $textType,
  record_type $textType,
  date $textType,
  doctor_name $textType,
  notes $textType,
  file_path $textType,
  expiry_date $textType,
  created_at $textType
)
''');

    // Personal Documents
    await db.execute('''
CREATE TABLE personal_documents (
  id $idType,
  user_id $intType,
  category $textType,
  document_name $textType,
  document_number $textType,
  issue_date $textType,
  expiry_date $textType,
  file_path $textType,
  created_at $textType
)
''');

    // Vehicle Information
    await db.execute('''
CREATE TABLE vehicle_info (
  id $idType,
  user_id $intType,
  vehicle_type $textType,
  reg_number $textType,
  document_type $textType,
  issue_date $textType,
  expiry_date $textType,
  file_path $textType,
  created_at $textType
)
''');

    // Financial Records
    await db.execute('''
CREATE TABLE financial_records (
  id $idType,
  user_id $intType,
  record_type $textType,
  institution_name $textType,
  account_number $textType,
  notes $textType,
  file_path $textType,
  created_at $textType
)
''');

    // Educational Certificates
    await db.execute('''
CREATE TABLE education_records (
  id $idType,
  user_id $intType,
  degree_name $textType,
  institution $textType,
  year_of_passing $textType,
  grade $textType,
  file_path $textType,
  created_at $textType
)
''');

    // Home & Warranties
    await db.execute('''
CREATE TABLE home_records (
  id $idType,
  user_id $intType,
  item_name $textType,
  brand $textType,
  purchase_date $textType,
  warranty_expiry $textType,
  bill_number $textType,
  file_path $textType,
  created_at $textType
)
''');

    // Travel Documents
    await db.execute('''
CREATE TABLE travel_docs (
  id $idType,
  user_id $intType,
  doc_type $textType,
  country $textType,
  doc_number $textType,
  issue_date $textType,
  expiry_date $textType,
  file_path $textType,
  created_at $textType
)
''');

    // Emergency Info
    await db.execute('''
CREATE TABLE emergency_info (
  id $idType,
  user_id $intType,
  info_type $textType,
  name $textType,
  value $textType,
  notes $textType,
  created_at $textType
)
''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
