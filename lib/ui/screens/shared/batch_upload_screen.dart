import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Batch OCR receipt upload screen (owner and staff).
/// TODO: Integrate google_mlkit_text_recognition for OCR processing.
class BatchUploadScreen extends StatefulWidget {
  const BatchUploadScreen({super.key});

  @override
  State<BatchUploadScreen> createState() => _BatchUploadScreenState();
}

class _BatchUploadScreenState extends State<BatchUploadScreen> {
  final List<String> _uploadedPaths = [];
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Receipts')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload your GCash receipts and FloatWatch will automatically read the transaction details.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              // Upload area
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 40, color: AppColors.primary),
                      SizedBox(height: 8),
                      Text('Tap to take photo or select from gallery',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('${_uploadedPaths.length} receipt(s) selected',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              // TODO: Show premium lock if batch limit exceeded (SubscriptionService)
              PrimaryButton(
                label: 'Process Receipts',
                onPressed: _uploadedPaths.isEmpty
                    ? null
                    : () => context.push(Routes.ocrReview),
                leadingIcon: Icons.auto_awesome_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    if (source == ImageSource.camera) {
      final file =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file != null && mounted) {
        setState(() => _uploadedPaths.add(file.path));
      }
    } else {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty && mounted) {
        setState(() => _uploadedPaths.addAll(files.map((f) => f.path)));
      }
    }
    // TODO: Integrate google_mlkit_text_recognition for OCR on picked images
  }
}
