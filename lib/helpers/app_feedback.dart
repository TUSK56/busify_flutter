import 'package:flutter/material.dart';

Future<void> showAppFeedback(
  BuildContext context,
  String message, {
  bool isError = false,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (ctx.mounted) Navigator.of(ctx).pop();
      });
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isError ? const Color(0xFFEF4444) : const Color(0xFF374151),
              width: 1,
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    },
  );
}
