import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Three-step attendance marking:
///  1. GPS location verification
///  2. Face capture & server-side verification
///  3. Check-in / Check-out
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  bool _locLoading  = false;
  bool _locVerified = false;
  double? _locDist;
  String? _locError;

  bool _faceLoading  = false;
  bool _faceVerified = false;
  String? _faceError;
  String? _capturedImageBase64;

  double? _lat, _lng;

  TodayStatus? _todayStatus;
  bool _statusLoading = true;

  CameraController? _camCtrl;
  bool _camReady = false;

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
    _initCamera();
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    super.dispose();
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camCtrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _camCtrl!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (e) {
      if (mounted) setState(() => _faceError = 'Camera error: $e');
    }
  }

  // ── Today Status ──────────────────────────────────────────────────────────

  Future<void> _loadTodayStatus() async {
    setState(() => _statusLoading = true);
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final s    = await api.getTodayStatus();
      if (mounted) setState(() { _todayStatus = s; _statusLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  // ── Step 1: Location ──────────────────────────────────────────────────────

  Future<void> _verifyLocation() async {
    setState(() { _locLoading = true; _locError = null; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Enable it in Settings.');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lat = pos.latitude;
      _lng = pos.longitude;

      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final res  = await api.validateLocation(pos.latitude, pos.longitude);

      if (res['insideCampus'] == true) {
        setState(() {
          _locVerified = true;
          _locDist     = (res['distance'] as num?)?.toDouble();
        });
      } else {
        setState(() {
          _locError = res['message'] as String? ?? 'Outside campus boundary.';
          _locDist  = (res['distance'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      setState(() => _locError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  // ── Step 2: Face ──────────────────────────────────────────────────────────

  Future<void> _captureFace() async {
    if (_camCtrl == null || !_camReady) return;
    setState(() { _faceLoading = true; _faceError = null; });

    try {
      final xFile = await _camCtrl!.takePicture();
      final bytes = await xFile.readAsBytes();
      final b64   = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Build descriptor — web uses pixel sampling, mobile tries ML Kit
      final descriptor = kIsWeb
          ? _pseudoDescriptor(bytes)
          : _pseudoDescriptor(bytes); // same for now — ML Kit optional

      // Send to server for verification
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);
      final body = await api.verifyFace(b64, descriptor);

      if (body['matched'] == true) {
        setState(() {
          _faceVerified        = true;
          _capturedImageBase64 = b64;
        });
      } else {
        setState(() => _faceError =
            body['message'] as String? ?? 'Face not matched. Try again.');
      }
    } catch (e) {
      setState(() =>
          _faceError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _faceLoading = false);
    }
  }

  /// Stable 128-dim pseudo-descriptor from image bytes.
  List<double> _pseudoDescriptor(List<int> bytes) {
    final rng  = math.Random(bytes.length ^ (bytes.isNotEmpty ? bytes[0] : 0));
    final desc = <double>[];
    final step = bytes.length ~/ 128;
    for (int i = 0; i < 128; i++) {
      final idx = (i * step).clamp(0, bytes.length - 1);
      desc.add((bytes[idx] / 255.0) * 0.8 + rng.nextDouble() * 0.2);
    }
    return desc;
  }

  void _retryFace() => setState(() { _faceVerified = false; _faceError = null; _capturedImageBase64 = null; });

  // ── Step 3: Check-in / Check-out ──────────────────────────────────────────

  Future<void> _markAttendance(bool isCheckIn) async {
    if (!_locVerified || !_faceVerified || _lat == null || _lng == null) return;

    setState(() { _faceLoading = true; });
    try {
      final auth = context.read<AuthService>();
      final api  = ApiService(sessionCookie: auth.sessionCookie);

      Map<String, dynamic> res;
      if (isCheckIn) {
        res = await api.checkIn(
          lat: _lat!, lng: _lng!,
          faceVerified: true,
          capturedImageBase64: _capturedImageBase64 ?? '',
        );
      } else {
        res = await api.checkOut(
          lat: _lat!, lng: _lng!,
          faceVerified: true,
          capturedImageBase64: _capturedImageBase64 ?? '',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Done!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reset face for next scan
      _retryFace();
      await _loadTodayStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _faceLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: RefreshIndicator(
        onRefresh: _loadTodayStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today's status card
            _TodayStatusCard(status: _todayStatus, loading: _statusLoading),
            const SizedBox(height: 16),

            // Step 1: Location
            _StepCard(
              step: 1,
              title: 'Campus Location Verification',
              verified: _locVerified,
              child: _buildLocationStep(),
            ),
            const SizedBox(height: 12),

            // Step 2: Face
            _StepCard(
              step: 2,
              title: 'Face Verification',
              verified: _faceVerified,
              child: _buildFaceStep(),
            ),
            const SizedBox(height: 12),

            // Step 3: Action
            _StepCard(
              step: 3,
              title: 'Mark Attendance',
              verified: false,
              child: _buildActionStep(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    if (_locVerified) {
      return _successRow(
        'Location verified — ${_locDist?.toStringAsFixed(0) ?? '?'}m from campus',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chameli Devi Group of Institutions\nKhandwa Road, Umri Khedi, Indore\nAttendance only allowed within 50m of campus.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_locError != null) _errorBox(_locError!),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _locLoading ? null : _verifyLocation,
          icon: _locLoading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.location_on),
          label: Text(_locLoading ? 'Verifying…' : 'Verify My Location'),
        ),
      ],
    );
  }

  Widget _buildFaceStep() {
    if (_faceVerified) {
      return _successRow('Face verified successfully!');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera preview
        if (_camReady && _camCtrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CameraPreview(_camCtrl!),
                  // Oval guide
                  Container(
                    width: 160,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _locVerified ? AppColors.accent : Colors.white54,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        const SizedBox(height: 10),
        if (_faceError != null) _errorBox(_faceError!),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: (!_locVerified || _faceLoading || !_camReady) ? null : _captureFace,
          icon: _faceLoading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.face),
          label: Text(_faceLoading ? 'Verifying…' : 'Scan & Verify Face'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _locVerified ? AppColors.primary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionStep() {
    final canAct = _locVerified && _faceVerified;
    final hasOpen = _todayStatus?.hasOpenSession ?? false;
    final hasRecord = _todayStatus?.hasRecord ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canAct)
          const Text(
            'Complete location and face verification above to mark attendance.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else ...[
          if (!hasRecord || !hasOpen)
            ElevatedButton.icon(
              onPressed: _faceLoading ? null : () => _markAttendance(true),
              icon: const Icon(Icons.login),
              label: const Text('Check In'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          if (hasOpen) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _faceLoading ? null : () => _markAttendance(false),
              icon: const Icon(Icons.logout),
              label: const Text('Check Out'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            ),
          ],
        ],
      ],
    );
  }

  Widget _successRow(String msg) => Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      );

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Text(msg, style: const TextStyle(color: AppColors.error, fontSize: 12)),
      );
}

// ─── Today Status Card ────────────────────────────────────────────────────────

class _TodayStatusCard extends StatelessWidget {
  final TodayStatus? status;
  final bool loading;
  const _TodayStatusCard({this.status, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text("Today's Status", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (status == null || !status!.hasRecord)
              const Text('No attendance marked yet today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            else
              _buildSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessions() {
    return Column(
      children: status!.sessions.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text('Session ${i + 1}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.login, size: 14, color: AppColors.success),
              const SizedBox(width: 2),
              Text(s.checkInTime.substring(0, 5), style: const TextStyle(fontSize: 12)),
              if (s.checkOutTime != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.logout, size: 14, color: AppColors.error),
                const SizedBox(width: 2),
                Text(s.checkOutTime!.substring(0, 5), style: const TextStyle(fontSize: 12)),
                if (s.sessionHours != null) ...[
                  const SizedBox(width: 8),
                  Text('(${s.sessionHours!.toStringAsFixed(1)}h)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ] else
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('Open', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final bool verified;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.verified,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: verified ? AppColors.success : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: verified
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text('$step', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// end of scan_screen.dart
