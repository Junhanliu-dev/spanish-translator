import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../photo_view_model.dart';
import 'widgets/camera_viewfinder_overlay.dart';

/// Camera capture screen for the photo translation feature.
///
/// Uses [ImagePicker] directly for camera access rather than the camera
/// package, which requires heavy platform setup. Shows a stylized capture
/// UI with gallery and shutter buttons.
class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  late final PhotoViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PhotoViewModel(
      apiClient: ServiceLocator.apiClient,
      historyRepo: ServiceLocator.historyRepo,
      languagePrefs: ServiceLocator.languagePrefs,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    HapticFeedback.mediumImpact();
    final path = await _viewModel.capturePhoto();
    if (path != null && mounted) {
      context.push('/photo/preview', extra: path);
    }
  }

  Future<void> _pickFromGallery() async {
    final path = await _viewModel.pickFromGallery();
    if (path != null && mounted) {
      context.push('/photo/preview', extra: path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              // Camera placeholder / viewfinder background.
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.stone950,
                child: const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: AppColors.stone700,
                  ),
                ),
              ),
              // Viewfinder overlay.
              const CameraViewfinderOverlay(),
              // Top bar: back button.
              Positioned(
                top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
                left: AppSpacing.sm,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              // Bottom controls.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: AppSpacing.xl3,
                    right: AppSpacing.xl3,
                    top: AppSpacing.xl2,
                    bottom:
                        MediaQuery.paddingOf(context).bottom + AppSpacing.xl2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button.
                      Semantics(
                        label: 'Choose from photo library',
                        button: true,
                        child: IconButton(
                          onPressed: _pickFromGallery,
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 28,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ),
                      // Shutter button.
                      GestureDetector(
                        onTap: _viewModel.state == PhotoState.capturing
                            ? null
                            : _capturePhoto,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child:
                                  _viewModel.state == PhotoState.capturing
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.stone900,
                                          ),
                                        )
                                      : null,
                            ),
                          ),
                        ),
                      ),
                      // Placeholder for flash toggle (future).
                      const SizedBox(width: 48, height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
