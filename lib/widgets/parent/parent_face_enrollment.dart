import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Hugging Face / local face service base URL (no trailing slash).
const String kParentFaceApiBaseUrl = String.fromEnvironment(
  'FACE_API_URL',
  defaultValue: 'https://tusk000-yolo-arc.hf.space',
);

/// Live scans required for parent enrollment (matches backend 5-crop average).
const int kParentEnrollmentScanCount = 5;

String parentFaceLowQualityMessage(String? reason) {
  switch (reason) {
    case 'face_too_small':
      return 'Face is too small in the photo. Move closer and try again.';
    case 'face_too_blurry':
      return 'Photo is too blurry. Hold still in good lighting and try again.';
    default:
      return 'Photo quality is too low. Use a clear front face photo and try again.';
  }
}

Color parentFaceBorderColor({
  required bool hasPhoto,
  required bool verified,
  required bool rejected,
  required Color defaultColor,
}) {
  if (!hasPhoto) return defaultColor;
  if (verified) return Colors.green;
  if (rejected) return Colors.red;
  return defaultColor;
}

Widget parentSubmitDisabledBlur({
  required bool enabled,
  required BorderRadius borderRadius,
  required Widget child,
}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (!enabled)
        Positioned.fill(
          child: AbsorbPointer(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.32),
              ),
            ),
          ),
        ),
    ],
  );
}

Future<XFile?> pickParentFacePhoto() async {
  final picker = ImagePicker();
  return picker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front,
    imageQuality: 88,
    maxWidth: 1280,
  );
}

/// Result of one POST /embed call during enrollment.
class ParentFaceEmbedResult {
  const ParentFaceEmbedResult({
    required this.verified,
    required this.statusMessage,
    this.rejectReason,
    this.embedding,
    this.scansCompleted = 0,
    this.requiredScans = kParentEnrollmentScanCount,
  });

  final bool verified;
  final String statusMessage;
  final String? rejectReason;
  final List<double>? embedding;
  final int scansCompleted;
  final int requiredScans;

  bool get enrollmentComplete => scansCompleted >= requiredScans;
}

/// Collects [kParentEnrollmentScanCount] live embeddings, then averages for storage.
class ParentFaceEnrollmentSession {
  ParentFaceEnrollmentSession({this.requiredScans = kParentEnrollmentScanCount});

  final int requiredScans;
  final List<List<double>> _embeddings = [];

  int get scansCompleted => _embeddings.length;
  bool get isComplete => scansCompleted >= requiredScans;
  XFile? lastPhoto;

  void reset() {
    _embeddings.clear();
    lastPhoto = null;
  }

  /// Runs one camera scan + /embed. On success, prompts caller to open camera again until complete.
  Future<ParentFaceEmbedResult> captureNextScan() async {
    final photo = await pickParentFacePhoto();
    if (photo == null) {
      return ParentFaceEmbedResult(
        verified: false,
        statusMessage: 'Camera cancelled',
        rejectReason: 'cancelled',
        scansCompleted: scansCompleted,
        requiredScans: requiredScans,
      );
    }
    return addScan(photo);
  }

  Future<ParentFaceEmbedResult> addScan(XFile photo) async {
    final single = await verifyParentFacePhoto(photo);
    if (!single.verified || single.embedding == null) {
      return ParentFaceEmbedResult(
        verified: false,
        statusMessage: single.statusMessage,
        rejectReason: single.rejectReason,
        scansCompleted: scansCompleted,
        requiredScans: requiredScans,
      );
    }

    _embeddings.add(single.embedding!);
    lastPhoto = photo;
    final done = isComplete;
    return ParentFaceEmbedResult(
      verified: done,
      statusMessage: done
          ? 'All $requiredScans face scans completed'
          : 'Scan $scansCompleted of $requiredScans OK — tap the photo box for scan ${scansCompleted + 1}',
      scansCompleted: scansCompleted,
      requiredScans: requiredScans,
      embedding: done ? averagedEmbedding() : null,
    );
  }

  List<double>? averagedEmbedding() {
    if (_embeddings.isEmpty) return null;
    final dim = _embeddings.first.length;
    final sum = List<double>.filled(dim, 0);
    for (final vec in _embeddings) {
      if (vec.length != dim) continue;
      for (var i = 0; i < dim; i++) {
        sum[i] += vec[i];
      }
    }
    final n = _embeddings.length;
    for (var i = 0; i < dim; i++) {
      sum[i] /= n;
    }
    var norm = 0.0;
    for (final v in sum) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm < 1e-6) return null;
    return sum.map((v) => v / norm).toList();
  }

  String? averagedEmbeddingJson() {
    final vec = averagedEmbedding();
    if (vec == null) return null;
    return jsonEncode(vec);
  }
}

Future<ParentFaceEmbedResult> verifyParentFacePhoto(XFile photo) async {
  try {
    final bytes = await File(photo.path).readAsBytes();
    final uri = Uri.parse('$kParentFaceApiBaseUrl/embed');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'face.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 400) {
      String message = 'Could not verify face. Please retake the photo.';
      try {
        final err = jsonDecode(body);
        if (err is Map<String, dynamic>) {
          final detail = err['detail'];
          if (detail is String && detail.trim().isNotEmpty) {
            message = detail.trim();
          }
        }
      } catch (_) {}
      return ParentFaceEmbedResult(
        verified: false,
        statusMessage: message,
        rejectReason: 'enrollment_quality',
      );
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Face service error (${streamed.statusCode})');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid face service response');
    }
    final status = (decoded['status'] as String?)?.trim() ?? '';
    if (status == 'ok') {
      final emb = _parseEmbeddingList(decoded['embedding']);
      if (emb == null || emb.length < 512) {
        return const ParentFaceEmbedResult(
          verified: false,
          statusMessage: 'Invalid embedding from face service',
          rejectReason: 'bad_embedding',
        );
      }
      return ParentFaceEmbedResult(
        verified: true,
        statusMessage: 'Face scan accepted',
        embedding: emb,
      );
    }
    if (status == 'no_face_detected') {
      return const ParentFaceEmbedResult(
        verified: false,
        statusMessage:
            'No face detected. Make sure your child\'s face is clearly visible and well-lit, then try again.',
        rejectReason: 'no_face_detected',
      );
    }
    if (status == 'low_quality') {
      final reason = decoded['reason'] as String?;
      return ParentFaceEmbedResult(
        verified: false,
        statusMessage: parentFaceLowQualityMessage(reason),
        rejectReason: reason ?? status,
      );
    }
    return ParentFaceEmbedResult(
      verified: false,
      statusMessage: 'Could not verify face. Please retake the photo.',
      rejectReason: status.isEmpty ? 'unknown' : status,
    );
  } catch (_) {
    return const ParentFaceEmbedResult(
      verified: false,
      statusMessage:
          'Could not reach face verification. Check internet and try again.',
      rejectReason: 'network_error',
    );
  }
}

List<double>? _parseEmbeddingList(dynamic raw) {
  if (raw is! List) return null;
  final out = <double>[];
  for (final v in raw) {
    if (v is num) {
      out.add(v.toDouble());
    } else {
      return null;
    }
  }
  return out;
}

class ParentFaceStatusRow extends StatelessWidget {
  const ParentFaceStatusRow({
    super.key,
    required this.checking,
    required this.verified,
    required this.statusMessage,
    this.messageStyle,
    this.verifiedColor = Colors.green,
    this.errorColor = Colors.red,
    this.loadingColor,
  });

  final bool checking;
  final bool verified;
  final String? statusMessage;
  final TextStyle? messageStyle;
  final Color verifiedColor;
  final Color errorColor;
  final Color? loadingColor;

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loadingColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Checking face photo…',
              style: messageStyle,
            ),
          ),
        ],
      );
    }
    if (verified) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: verifiedColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusMessage ?? 'Face verified successfully',
              style: messageStyle?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: verifiedColor,
                  ) ??
                  TextStyle(fontWeight: FontWeight.w600, color: verifiedColor),
            ),
          ),
        ],
      );
    }
    if (statusMessage != null && statusMessage!.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusMessage!,
              style: messageStyle?.copyWith(color: errorColor) ??
                  TextStyle(color: errorColor),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
