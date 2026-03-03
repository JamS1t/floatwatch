import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ocr_result.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/receipt_parser.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Batch OCR receipt upload screen.
/// Picks images → runs ML Kit OCR → parses with ReceiptParser → pushes to review.
class BatchUploadScreen extends StatefulWidget {
  const BatchUploadScreen({super.key});

  @override
  State<BatchUploadScreen> createState() => _BatchUploadScreenState();
}

class _BatchUploadScreenState extends State<BatchUploadScreen> {
  final List<String> _uploadedPaths = [];
  final _picker = ImagePicker();
  bool _isProcessing = false;
  int _processedCount = 0;

  bool get _overLimit =>
      _uploadedPaths.length > AppConstants.freeBatchUploadLimit;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Receipts')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload your GCash receipts and FloatWatch will automatically read the transaction details.',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                _uploadedPaths.isEmpty
                    ? _buildUploadArea()
                    : _buildThumbnailGrid(),
                const SizedBox(height: 12),
                _buildSelectionRow(),
                if (_isProcessing) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Processing $_processedCount of ${_uploadedPaths.length}...',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _uploadedPaths.isNotEmpty
                        ? _processedCount / _uploadedPaths.length
                        : null,
                    backgroundColor: AppColors.divider,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ],
                const Spacer(),
                if (_overLimit) _buildLimitBanner(),
                PrimaryButton(
                  label:
                      _isProcessing ? 'Processing...' : 'Process Receipts',
                  onPressed:
                      (_uploadedPaths.isEmpty || _isProcessing || _overLimit)
                          ? null
                          : _processReceipts,
                  leadingIcon: Icons.auto_awesome_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primary),
            SizedBox(height: 8),
            Text(
              'Tap to take photo or select from gallery',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailGrid() {
    return SizedBox(
      height: 180,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _uploadedPaths.length + 1,
        itemBuilder: (context, index) {
          // Last cell: "Add more" button
          if (index == _uploadedPaths.length) {
            return GestureDetector(
              onTap: _isProcessing ? null : _pickImages,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.primary),
                    SizedBox(height: 4),
                    Text('Add',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 12)),
                  ],
                ),
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_uploadedPaths[index]),
                  fit: BoxFit.cover,
                ),
              ),
              if (!_isProcessing)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _uploadedPaths.removeAt(index)),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectionRow() {
    if (_uploadedPaths.isEmpty) {
      return Text(
        '0 receipts selected',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }
    return Row(
      children: [
        Text(
          '${_uploadedPaths.length} receipt(s) selected',
          style:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _isProcessing ? null : _pickImages,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add more'),
        ),
      ],
    );
  }

  Widget _buildLimitBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
              color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Free plan is limited to ${AppConstants.freeBatchUploadLimit} receipts per batch. Upgrade to process more.',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processReceipts() async {
    final ownerGcash =
        context.read<AuthProvider>().currentOwner?.gcashNumber ?? '';
    final ocrService = context.read<OcrService>();

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
    });

    try {
      final rawResults = await ocrService.extractBatch(
        List.from(_uploadedPaths),
        onProgress: (done, _) {
          if (mounted) setState(() => _processedCount = done);
        },
      );

      final parser = ReceiptParser();
      final ocrResults = rawResults.map((r) {
        try {
          return parser.parse(
            imagePath: r.path,
            rawText: r.text,
            ownerGcashNumber: ownerGcash,
          );
        } catch (_) {
          return OcrResult(
            imagePath: r.path,
            rawText: r.text,
            needsManualReview: true,
            reviewReason: 'Failed to parse receipt',
          );
        }
      }).toList();

      if (!mounted) return;
      context.push(Routes.ocrReview, extra: ocrResults);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing failed: $e'),
          action: SnackBarAction(
              label: 'Retry', onPressed: _processReceipts),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
      final file = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (file != null && mounted) {
        setState(() => _uploadedPaths.add(file.path));
      }
    } else {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty && mounted) {
        setState(() =>
            _uploadedPaths.addAll(files.map((f) => f.path)));
      }
    }
  }
}
