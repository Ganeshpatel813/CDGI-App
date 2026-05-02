import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/faculty.dart';
import '../models/attendance.dart';

/// Central HTTP client for all Flask API calls.
/// Change [baseUrl] to your server's IP/domain before running.
class ApiService {
  // ── CHANGE THIS to your Flask server address ──────────────────────────────
  // For Android phone on same WiFi: 'http://192.168.0.191:5000'
  // For Chrome/web browser:         'http://localhost:5000'
  static const String baseUrl = 'http://localhost:5000';
  // ─────────────────────────────────────────────────────────────────────────

  final String? sessionCookie;

  ApiService({this.sessionCookie});

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (sessionCookie != null) 'Authorization': 'Bearer $sessionCookie',
      };

  Future<http.Response> _get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    final uri = Uri.parse('$baseUrl$path');
    return http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> _delete(String path) {
    final uri = Uri.parse('$baseUrl$path');
    return http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
  }

  /// Extracts the Set-Cookie header value from a login response.
  static String? extractCookie(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null) return null;
    // Take only the session= part (strip path/httponly/etc.)
    final match = RegExp(r'session=[^;]+').firstMatch(raw);
    return match?.group(0);
  }

  static Map<String, dynamic> _decode(http.Response r) =>
      jsonDecode(r.body) as Map<String, dynamic>;

  static List<dynamic> _decodeList(http.Response r) =>
      jsonDecode(r.body) as List<dynamic>;

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Returns (Faculty, jwtToken) on success, throws on error.
  Future<(Faculty, String)> login(String employeeId, String password) async {
    try {
      final r = await _post('/api/auth/login', {
        'employeeId': employeeId,
        'password': password,
      });

      if (r.statusCode == 200) {
        final body  = _decode(r);
        final token = body['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('No token received from server.');
        }
        // Fetch full profile using the new token
        try {
          final meApi   = ApiService(sessionCookie: token);
          final faculty = await meApi.getMe();
          return (faculty, token);
        } catch (_) {
          // If /me fails, build Faculty from login response directly
          final faculty = Faculty.fromJson(body);
          return (faculty, token);
        }
      }

      final body = _decode(r);
      final msg  = body['error'] as String?
          ?? body['message'] as String?
          ?? 'Login failed (status ${r.statusCode}).';
      throw Exception(msg);
    } catch (e) {
      // Re-throw with clean message
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    await _post('/api/auth/logout', {});
  }

  Future<Faculty> getMe() async {
    final r = await _get('/api/auth/me');
    if (r.statusCode == 200) return Faculty.fromJson(_decode(r));
    throw Exception('Failed to fetch profile.');
  }

  Future<String> checkEmpId(String empId) async {
    final r = await _get('/api/auth/check-empid', query: {'id': empId});
    final body = _decode(r);
    return body['message'] as String? ?? '';
  }

  /// Register a new faculty member.
  /// [faceDescriptor] is a List<double> of 128 values from face-api.js (web view).
  /// [faceImageBase64] is the captured face image as base64 string.
  Future<Map<String, dynamic>> register({
    required String name,
    required String employeeId,
    required String email,
    String? phone,
    required String department,
    required String designation,
    required String password,
    required List<double> faceDescriptor,
    required String faceImageBase64,
    int? collegeId,
    int? programId,
  }) async {
    final r = await _post('/api/auth/register', {
      'name': name,
      'employeeId': employeeId,
      'email': email,
      'phone': phone ?? '',
      'department': department,
      'designation': designation,
      'password': password,
      'faceDescriptor': faceDescriptor,
      'faceImage': faceImageBase64,
      'collegeId': collegeId,
      'programId': programId,
    });
    if (r.statusCode == 201) return _decode(r);
    final body = _decode(r);
    throw Exception(body['errors']?.toString() ?? body['error'] ?? 'Registration failed.');
  }

  // ── College / Program ─────────────────────────────────────────────────────

  Future<List<dynamic>> getColleges() async {
    final r = await _get('/api/colleges');
    if (r.statusCode == 200) return _decodeList(r);
    throw Exception('Failed to load colleges.');
  }

  Future<Map<String, dynamic>> getCollegeInfo() async {
    final r = await _get('/api/college/info');
    if (r.statusCode == 200) return _decode(r);
    throw Exception('Failed to load college info.');
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> validateLocation(double lat, double lng) async {
    final r = await _post('/api/location/validate', {
      'latitude': lat,
      'longitude': lng,
    });
    return _decode(r);
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  Future<TodayStatus> getTodayStatus() async {
    final r = await _get('/api/attendance/today-status');
    if (r.statusCode == 200) return TodayStatus.fromJson(_decode(r));
    throw Exception('Failed to load today status.');
  }

  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double lng,
    required bool faceVerified,
    required String capturedImageBase64,
  }) async {
    final r = await _post('/api/attendance/check-in', {
      'latitude': lat,
      'longitude': lng,
      'faceVerified': faceVerified,
      'capturedImage': capturedImageBase64,
    });
    if (r.statusCode == 201) return _decode(r);
    throw Exception(_decode(r)['error'] ?? 'Check-in failed.');
  }

  Future<Map<String, dynamic>> checkOut({
    required double lat,
    required double lng,
    required bool faceVerified,
    required String capturedImageBase64,
  }) async {
    final r = await _post('/api/attendance/check-out', {
      'latitude': lat,
      'longitude': lng,
      'faceVerified': faceVerified,
      'capturedImage': capturedImageBase64,
    });
    if (r.statusCode == 200) return _decode(r);
    throw Exception(_decode(r)['error'] ?? 'Check-out failed.');
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<List<AttendanceRecord>> getMyReport({String? month, String? from, String? to}) async {
    final q = <String, String>{};
    if (month != null) q['month'] = month;
    if (from  != null) q['from']  = from;
    if (to    != null) q['to']    = to;
    final r = await _get('/api/report/my', query: q);
    if (r.statusCode == 200) {
      return (_decodeList(r))
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load report.');
  }

  Future<MonthlySummary> getMonthlySummary({String? month}) async {
    final q = month != null ? {'month': month} : <String, String>{};
    final r = await _get('/api/report/summary', query: q);
    if (r.statusCode == 200) return MonthlySummary.fromJson(_decode(r));
    throw Exception('Failed to load summary.');
  }

  Future<List<dynamic>> getCalendar({String? month}) async {
    final q = month != null ? {'month': month} : <String, String>{};
    final r = await _get('/api/report/calendar', query: q);
    if (r.statusCode == 200) return _decodeList(r);
    throw Exception('Failed to load calendar.');
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<AdminStats> getAdminStats() async {
    final r = await _get('/api/admin/stats');
    if (r.statusCode == 200) return AdminStats.fromJson(_decode(r));
    throw Exception('Failed to load admin stats.');
  }

  Future<List<Faculty>> getAdminFaculty({String? search, String? department}) async {
    final q = <String, String>{};
    if (search     != null && search.isNotEmpty)     q['search']     = search;
    if (department != null && department.isNotEmpty) q['department'] = department;
    final r = await _get('/api/admin/faculty', query: q);
    if (r.statusCode == 200) {
      return (_decodeList(r))
          .map((e) => Faculty.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load faculty list.');
  }

  Future<List<dynamic>> getAdminAttendance(
      {String? date, String? from, String? to, String? month}) async {
    final q = <String, String>{};
    if (date  != null) q['date']  = date;
    if (from  != null) q['from']  = from;
    if (to    != null) q['to']    = to;
    if (month != null) q['month'] = month;
    final r = await _get('/api/admin/attendance', query: q);
    if (r.statusCode == 200) return _decodeList(r);
    throw Exception('Failed to load attendance.');
  }

  Future<void> deleteFaculty(int facultyId) async {
    final r = await _delete('/api/admin/faculty/$facultyId');
    if (r.statusCode != 200) {
      throw Exception(_decode(r)['error'] ?? 'Delete failed.');
    }
  }

  Future<void> toggleFaculty(int facultyId) async {
    final r = await _post('/api/admin/faculty/$facultyId/toggle', {});
    if (r.statusCode != 200) {
      throw Exception(_decode(r)['error'] ?? 'Toggle failed.');
    }
  }

  Future<Map<String, dynamic>> addFaculty({
    required String name,
    required String employeeId,
    required String email,
    String? phone,
    required String department,
    required String designation,
    required String password,
    required List<double> faceDescriptor,
    required String faceImageBase64,
    int? collegeId,
    int? programId,
  }) async {
    final r = await _post('/api/admin/faculty/add', {
      'name': name,
      'employeeId': employeeId,
      'email': email,
      'phone': phone ?? '',
      'department': department,
      'designation': designation,
      'password': password,
      'faceDescriptor': faceDescriptor,
      'faceImage': faceImageBase64,
      'collegeId': collegeId,
      'programId': programId,
    });
    if (r.statusCode == 201) return _decode(r);
    throw Exception(_decode(r)['error'] ?? 'Add faculty failed.');
  }

  Future<List<dynamic>> getAdminMonthlyReport({String? month}) async {
    final q = month != null ? {'month': month} : <String, String>{};
    final r = await _get('/api/admin/report/summary', query: q);
    if (r.statusCode == 200) {
      final body = _decode(r);
      // Response is {"faculty": [...], "workingDays": N}
      if (body.containsKey('faculty')) {
        return body['faculty'] as List<dynamic>;
      }
      // Fallback: maybe it's a plain list
      return _decodeList(r);
    }
    throw Exception('Failed to load monthly report.');
  }

  // ── College & Program APIs ────────────────────────────────────────────────

  Future<void> addCollege({required String name, required String shortName,
      required String description}) async {
    final r = await _post('/api/colleges',
        {'name': name, 'short_name': shortName, 'description': description});
    if (r.statusCode != 201) throw Exception(_decode(r)['error'] ?? 'Failed.');
  }

  Future<void> updateCollege({required int id, required String name,
      required String shortName, required String description}) async {
    final uri = Uri.parse('$baseUrl/api/colleges/$id');
    final r   = await http.put(uri, headers: _headers,
        body: jsonEncode({'name': name, 'short_name': shortName,
          'description': description}))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception(_decode(r)['error'] ?? 'Failed.');
  }

  Future<void> deleteCollege(int id) async {
    final r = await _delete('/api/colleges/$id');
    if (r.statusCode != 200) throw Exception(_decode(r)['error'] ?? 'Failed.');
  }

  Future<void> addProgram({required int collegeId, required String name,
      required String duration, required int intake}) async {
    final r = await _post('/api/programs', {
      'college_id': collegeId, 'name': name,
      'duration': duration, 'intake_capacity': intake,
    });
    if (r.statusCode != 201) throw Exception(_decode(r)['error'] ?? 'Failed.');
  }

  Future<void> updateProgram({required int id, required String name,
      required String duration, required int intake}) async {
    final uri = Uri.parse('$baseUrl/api/programs/$id');
    final r   = await http.put(uri, headers: _headers,
        body: jsonEncode({'name': name, 'duration': duration,
          'intake_capacity': intake}))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception(_decode(r)['error'] ?? 'Failed.');
  }

  Future<void> deleteProgram(int id) async {
    final r = await _delete('/api/programs/$id');
    if (r.statusCode != 200) throw Exception(_decode(r)['error'] ?? 'Failed.');
  }

  // ── Advanced Report ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdvancedReport(
      Map<String, String> params) async {
    final r = await _get('/api/admin/report/advanced', query: params);
    if (r.statusCode == 200) return _decode(r);
    throw Exception(_decode(r)['error'] ?? 'Failed to load report.');
  }

  // ── Face APIs ─────────────────────────────────────────────────────────────

  /// Send a descriptor (computed on-device by ML Kit) to the server for storage validation.
  /// Returns the same descriptor back on success.
  Future<List<double>> getFaceDescriptor(String imageBase64, List<double> descriptor) async {
    final r = await _post('/api/face/descriptor', {
      'image':      imageBase64,
      'descriptor': descriptor,
    });
    if (r.statusCode == 200) {
      final body = _decode(r);
      return (body['descriptor'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
    }
    final body = _decode(r);
    throw Exception(body['error'] ?? 'Face descriptor failed.');
  }

  /// Verify a face descriptor (computed on-device) against the logged-in user's stored descriptor.
  Future<Map<String, dynamic>> verifyFace(String imageBase64, List<double> descriptor) async {
    final r = await _post('/api/face/verify', {
      'image':      imageBase64,
      'descriptor': descriptor,
    });
    final body = _decode(r);
    if (r.statusCode == 200) return body;
    throw Exception(body['error'] ?? body['message'] ?? 'Face verification failed.');
  }
}
