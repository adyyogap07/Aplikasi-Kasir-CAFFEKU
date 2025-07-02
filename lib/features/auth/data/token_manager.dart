import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _tokenExpiryKey = 'token_expiry';
  
  static TokenManager? _instance;
  static TokenManager get instance {
    _instance ??= TokenManager._();
    return _instance!;
  }
  
  TokenManager._();
  
  SharedPreferences? _prefs;
  
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // Simpan token setelah login berhasil
  Future<bool> saveToken({
    required String token,
    String? userId,
    String? userName,
    Duration? expiryDuration,
  }) async {
    try {
      await _initPrefs();
      
      debugPrint('💾 Saving token...');
      debugPrint('  - Token length: ${token.length}');
      debugPrint('  - Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      // Simpan token
      await _prefs!.setString(_tokenKey, token);
      
      // Simpan user info jika ada
      if (userId != null) {
        await _prefs!.setString(_userIdKey, userId);
      }
      if (userName != null) {
        await _prefs!.setString(_userNameKey, userName);
      }
      
      // Simpan waktu expired jika ada
      if (expiryDuration != null) {
        final expiryTime = DateTime.now().add(expiryDuration).millisecondsSinceEpoch;
        await _prefs!.setInt(_tokenExpiryKey, expiryTime);
      }
      
      debugPrint('✅ Token saved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
      return false;
    }
  }
  
  // Ambil token yang tersimpan
  Future<String?> getToken() async {
    try {
      await _initPrefs();
      
      final token = _prefs!.getString(_tokenKey);
      
      if (token == null) {
        debugPrint('❌ No token found in storage');
        return null;
      }
      
      // Cek apakah token sudah expired
      if (await isTokenExpired()) {
        debugPrint('❌ Token expired, removing from storage');
        await clearToken();
        return null;
      }
      
      debugPrint('✅ Token retrieved from storage');
      debugPrint('  - Token length: ${token.length}');
      debugPrint('  - Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      return token;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }
  
  // Cek apakah token sudah expired
  Future<bool> isTokenExpired() async {
    try {
      await _initPrefs();
      
      final expiryTime = _prefs!.getInt(_tokenExpiryKey);
      if (expiryTime == null) {
        // Jika tidak ada info expiry, anggap token masih valid
        return false;
      }
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = now > expiryTime;
      
      debugPrint('🕒 Token expiry check: ${isExpired ? "EXPIRED" : "VALID"}');
      
      return isExpired;
    } catch (e) {
      debugPrint('❌ Error checking token expiry: $e');
      return true; // Anggap expired jika ada error
    }
  }
  
  // Hapus token (logout)
  Future<bool> clearToken() async {
    try {
      await _initPrefs();
      
      await _prefs!.remove(_tokenKey);
      await _prefs!.remove(_userIdKey);
      await _prefs!.remove(_userNameKey);
      await _prefs!.remove(_tokenExpiryKey);
      
      debugPrint('🗑️ Token cleared from storage');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing token: $e');
      return false;
    }
  }
  
  // Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Get user info
  Future<Map<String, String?>> getUserInfo() async {
    await _initPrefs();
    
    return {
      'userId': _prefs!.getString(_userIdKey),
      'userName': _prefs!.getString(_userNameKey),
    };
  }
  
  // Debug: Print semua data yang tersimpan
  Future<void> debugPrintStoredData() async {
    await _initPrefs();
    
    debugPrint('🔍 Debug - Stored Data:');
    debugPrint('  - Token: ${_prefs!.getString(_tokenKey) ?? "NULL"}');
    debugPrint('  - User ID: ${_prefs!.getString(_userIdKey) ?? "NULL"}');
    debugPrint('  - User Name: ${_prefs!.getString(_userNameKey) ?? "NULL"}');
    debugPrint('  - Token Expiry: ${_prefs!.getInt(_tokenExpiryKey) ?? "NULL"}');
    
    final isExpired = await isTokenExpired();
    debugPrint('  - Is Expired: $isExpired');
  }
}