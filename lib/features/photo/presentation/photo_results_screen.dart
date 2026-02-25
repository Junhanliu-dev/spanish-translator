import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/openai_client.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../photo_view_model.dart';
import 'widgets/menu_item_row.dart';
import 'widgets/menu_section_header.dart';

/// Results screen showing translated menu items from a photo.
///
/// Has two tabs: Translation (structured menu) and Original Photo.
class PhotoResultsScreen extends StatefulWidget {
  const PhotoResultsScreen({
    super.key,
    required this.imagePath,
  });

  /// Path to the source image file.
  final String imagePath;

  @override
  State<PhotoResultsScreen> createState() => _PhotoResultsScreenState();
}

class _PhotoResultsScreenState extends State<PhotoResultsScreen>
    with SingleTickerProviderStateMixin {
  late final PhotoViewModel _viewModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = PhotoViewModel(
      apiClient: ServiceLocator.apiClient,
      historyRepo: ServiceLocator.historyRepo,
      languagePrefs: ServiceLocator.languagePrefs,
    );
    // Start processing immediately.
    _viewModel.processImage(widget.imagePath);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showSavedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF81C784), size: 20),
            SizedBox(width: 8),
            Text('Saved to History'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final isLoading = _viewModel.state == PhotoState.processing;
        final hasError = _viewModel.state == PhotoState.error;
        final hasResult = _viewModel.state == PhotoState.success;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => context.go('/photo'),
            ),
            title: Text(
              isLoading ? 'Reading Menu...' : 'Menu Translation',
            ),
            actions: [
              if (hasResult) ...[
                IconButton(
                  onPressed: _viewModel.isSaved
                      ? null
                      : () async {
                          await _viewModel.saveToHistory();
                          if (mounted) _showSavedSnackBar();
                        },
                  icon: Icon(
                    _viewModel.isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                  color: _viewModel.isSaved
                      ? AppColors.terracotta
                      : null,
                ),
              ],
            ],
            bottom: hasResult
                ? TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Translation'),
                      Tab(text: 'Original Photo'),
                    ],
                    indicatorColor: AppColors.terracotta,
                    labelColor: AppColors.white,
                    unselectedLabelColor:
                        AppColors.white.withValues(alpha: 0.7),
                  )
                : null,
          ),
          body: isLoading
              ? _buildLoadingState()
              : hasError
                  ? _buildErrorState()
                  : hasResult
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTranslationTab(),
                            _buildOriginalPhotoTab(),
                          ],
                        )
                      : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        // Background image with overlay.
        Positioned.fill(
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.85)
                : AppColors.stone950.withValues(alpha: 0.85),
          ),
        ),
        // Loading content.
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.terracotta,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Reading and translating\nyour menu...',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.stone700,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error,
              color: AppColors.terracotta,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Couldn\'t read this menu',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _viewModel.errorMessage ??
                  'Try retaking the photo with better lighting.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.stone600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => context.go('/photo'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retake Photo'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.go('/text'),
              icon: const Icon(Icons.text_fields),
              label: const Text('Enter Text Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationTab() {
    final result = _viewModel.menuResult;
    if (result == null) return const SizedBox.shrink();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: _itemCount(result),
      itemBuilder: (context, index) {
        final widget = _buildListItem(result, index);
        return widget;
      },
    );
  }

  int _itemCount(MenuTranslationResponse result) {
    // sections + items + scan another page button.
    var count = 0;
    for (final section in result.sections) {
      count++; // section header
      count += section.items.length;
    }
    count++; // scan another page button
    return count;
  }

  Widget _buildListItem(MenuTranslationResponse result, int listIndex) {
    var currentIndex = 0;
    var globalItemIndex = 0;

    for (final section in result.sections) {
      // Section header.
      if (currentIndex == listIndex) {
        return MenuSectionHeader(
          originalTitle: section.originalTitle,
          translatedTitle: section.translatedTitle,
        );
      }
      currentIndex++;

      // Items in this section.
      for (final item in section.items) {
        if (currentIndex == listIndex) {
          final itemIndex = globalItemIndex;
          return MenuItemRow(
            item: item,
            isExpanded: _viewModel.expandedItemIndex == itemIndex,
            onTap: () => _viewModel.toggleItemExpansion(itemIndex),
          )
              .animate()
              .fadeIn(
                duration: 200.ms,
                delay: Duration(milliseconds: 50 * (listIndex % 10)),
              );
        }
        currentIndex++;
        globalItemIndex++;
      }
    }

    // Scan Another Page button.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      child: OutlinedButton.icon(
        onPressed: () => context.go('/photo'),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Scan Another Page'),
      ),
    );
  }

  Widget _buildOriginalPhotoTab() {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, size: 48),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Original photo -- zoom to read small text',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.stone500,
            ),
          ),
        ),
      ],
    );
  }
}
