import '../core/database/database_helper.dart';
import '../models/family_member.dart';
import '../models/bp_reading.dart';
import '../models/glucose_reading.dart';

class HealthRepository {
  final DatabaseHelper _dbHelper;

  HealthRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<FamilyMember>> getFamilyMembers() => _dbHelper.getMembers();

  Future<void> saveMember(FamilyMember member) => _dbHelper.insertMember(member);

  Future<void> updateMember(FamilyMember member) => _dbHelper.updateMember(member);

  Future<void> deleteMember(String id) => _dbHelper.deleteMember(id);

  // Blood Pressure
  Future<List<BpReading>> getBpReadings(String memberId) =>
      _dbHelper.getBpReadings(memberId);

  Future<void> addBpReading(BpReading reading) => _dbHelper.insertBp(reading);

  Future<void> deleteBpReading(String id) => _dbHelper.deleteBp(id);

  // Blood Glucose
  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) =>
      _dbHelper.getGlucoseReadings(memberId);

  Future<void> addGlucoseReading(GlucoseReading reading) =>
      _dbHelper.insertGlucose(reading);

  Future<void> deleteGlucoseReading(String id) => _dbHelper.deleteGlucose(id);

  // Backup & Restore
  Future<String> exportBackupJson() => _dbHelper.exportToJson();

  Future<bool> importBackupJson(String jsonString) =>
      _dbHelper.importFromJson(jsonString);
}
