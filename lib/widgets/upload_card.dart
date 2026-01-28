import 'dart:io';
import 'package:flutter/material.dart';

class UploadCard extends StatelessWidget {
  final String title;
  final File? file;
  final VoidCallback onPick;

  const UploadCard({
    super.key,
    required this.title,
    required this.file,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.upload_file, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file == null ? title : "Selected ✓",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
