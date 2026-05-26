import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Hugging Face / local face service base URL (no trailing slash).
const String kParentFaceApiBaseUrl = String.fromEnvironment(
  'FACE_API_URL',
  defaultValue: 'https://tusk000-yolo-arc.hf.space',
);

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

/// Dim + block taps on submit buttons until face check passes (same pattern as supervisor End Trip).
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

/// Opens the device camera (front) — no custom overlay screen.
Future<XFile?> pickParentFacePhoto() async {
  final picker = ImagePicker();
  return picker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front,
    imageQuality: 88,
    maxWidth: 1280,
  );
}

/// Result of POST /embed for parent enrollment flows.
class ParentFaceEmbedResult {
  const ParentFaceEmbedResult({
    required this.verified,
    required this.statusMessage,
    this.rejectReason,
  });

  final bool verified;
  final String statusMessage;
  final String? rejectReason;
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
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Face service error (${streamed.statusCode})');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid face service response');
    }
    final status = (decoded['status'] as String?)?.trim() ?? '';
    if (status == 'ok') {
      return const ParentFaceEmbedResult(
        verified: true,
        statusMessage: 'Face verified successfully',
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

/// Status row under the face photo box (spinner / success / error).
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
