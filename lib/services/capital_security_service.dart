import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';

/// نموذج بيانات أمان الخزنة
class CapitalSecurityData {
  final String passwordHash;
  final String securityQuestion;
  final String securityAnswerHash;

  const CapitalSecurityData({
    required this.passwordHash,
    required this.securityQuestion,
    required this.securityAnswerHash,
  });
}

/// خدمة أمان الخزنة – تشفير، تحقق، وإدارة الباسوورد
class CapitalSecurityService {
  static final CapitalSecurityService _instance =
      CapitalSecurityService._internal();
  factory CapitalSecurityService() => _instance;
  CapitalSecurityService._internal();

  final _db = DatabaseHelper();

  // ══════════════════════════════════════
  //  تشفير
  // ══════════════════════════════════════

  /// تحويل نص إلى SHA-256 hash
  static String hash(String input) {
    final bytes = utf8.encode(input.trim());
    return sha256.convert(bytes).toString();
  }

  // ══════════════════════════════════════
  //  قراءة / كتابة من قاعدة البيانات
  // ══════════════════════════════════════

  Future<CapitalSecurityData?> loadSecurity() => _db.getCapitalSecurity();

  Future<void> saveSecurity(CapitalSecurityData data) =>
      _db.saveCapitalSecurity(data);

  Future<bool> isPasswordSet() async {
    final data = await loadSecurity();
    return data != null && data.passwordHash.isNotEmpty;
  }

  // ══════════════════════════════════════
  //  التحقق
  // ══════════════════════════════════════

  /// التحقق من الباسوورد
  Future<bool> verifyPassword(String password) async {
    final data = await loadSecurity();
    if (data == null) return false;
    return data.passwordHash == hash(password);
  }

  /// التحقق من إجابة سؤال الأمان
  Future<bool> verifySecurityAnswer(String answer) async {
    final data = await loadSecurity();
    if (data == null) return false;
    return data.securityAnswerHash == hash(answer.toLowerCase().trim());
  }

  // ══════════════════════════════════════
  //  إعداد / تغيير
  // ══════════════════════════════════════

  /// الإعداد الأول للباسوورد والسؤال
  Future<void> setupPassword({
    required String password,
    required String question,
    required String answer,
  }) async {
    final data = CapitalSecurityData(
      passwordHash: hash(password),
      securityQuestion: question.trim(),
      securityAnswerHash: hash(answer.toLowerCase().trim()),
    );
    await saveSecurity(data);
  }

  /// تغيير الباسوورد (بعد التحقق من القديم أو إجابة السؤال)
  Future<bool> changePassword({
    required String newPassword,
    String? oldPassword,
    String? securityAnswer,
  }) async {
    // التحقق من المصادقة
    bool authenticated = false;
    if (oldPassword != null && oldPassword.isNotEmpty) {
      authenticated = await verifyPassword(oldPassword);
    }
    if (!authenticated && securityAnswer != null && securityAnswer.isNotEmpty) {
      authenticated = await verifySecurityAnswer(securityAnswer);
    }
    if (!authenticated) return false;

    final current = await loadSecurity();
    if (current == null) return false;

    final data = CapitalSecurityData(
      passwordHash: hash(newPassword),
      securityQuestion: current.securityQuestion,
      securityAnswerHash: current.securityAnswerHash,
    );
    await saveSecurity(data);
    return true;
  }

  /// الحصول على السؤال الاحتياطي
  Future<String?> getSecurityQuestion() async {
    final data = await loadSecurity();
    return data?.securityQuestion;
  }
}
