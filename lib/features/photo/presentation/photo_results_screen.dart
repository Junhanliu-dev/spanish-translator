import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/openai_client.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../photo_view_model.dart';
import 'widgets/menu_item_row.dart';
import 'widgets/menu_section_header.dart';
import 'widgets/order_item_row.dart';

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
  late final PageController _photoPageController;
  int _currentPhotoPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _photoPageController = PageController();
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
    _photoPageController.dispose();
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _showSaveTitleDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Menu'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Bar Txepetxa, Calle Mayor...',
              labelText: 'Title',
            ),
            onSubmitted: (value) => Navigator.pop(ctx, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (title == null || !mounted) return;

    await _viewModel.saveToHistory(title: title);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF81C784),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.trim().isEmpty
                      ? 'Saved to History'
                      : 'Saved "${title.trim()}" to History',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddPageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Add Another Page',
                style: const TextStyle(fontFamily: 'Nunito', 
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addPageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addPageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPageFromCamera() async {
    final path = await _viewModel.captureAdditionalPhoto();
    if (path != null) {
      final success = await _viewModel.processAdditionalImage(path);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewModel.errorMessage ?? 'Could not read this page',
            ),
          ),
        );
      }
    }
  }

  Future<void> _addPageFromGallery() async {
    final path = await _viewModel.pickAdditionalFromGallery();
    if (path != null) {
      final success = await _viewModel.processAdditionalImage(path);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewModel.errorMessage ?? 'Could not read this page',
            ),
          ),
        );
      }
    }
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
                      : _showSaveTitleDialog,
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
                    tabs: [
                      const Tab(text: 'Translation'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('My Order'),
                            if (_viewModel.orderTotalCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.saffron,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_viewModel.orderTotalCount}',
                                  style: const TextStyle(fontFamily: 'Nunito', 
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.stone900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        text: _viewModel.pageImagePaths.length > 1
                            ? 'Photos (${_viewModel.pageImagePaths.length})'
                            : 'Original Photo',
                      ),
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
                      ? Column(
                          children: [
                            if (_viewModel.isAddingPage)
                              const LinearProgressIndicator(
                                color: AppColors.terracotta,
                              ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildTranslationTab(),
                                  _buildOrderTab(),
                                  _buildOriginalPhotoTab(),
                                ],
                              ),
                            ),
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
                style: const TextStyle(fontFamily: 'Nunito', 
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
    // sections + items + optional loading card + scan another page button.
    var count = 0;
    for (final section in result.sections) {
      count++; // section header
      count += section.items.length;
    }
    if (_viewModel.isAddingPage) count++; // loading card
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
            isSpeaking: _viewModel.isSpeaking,
            onSpeak: () => _viewModel.speakText(item.originalName),
            onAddToOrder: () => _viewModel.addToOrder(itemIndex),
            orderQuantity: _viewModel.orderItems[itemIndex] ?? 0,
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

    // Loading card while adding a page.
    if (_viewModel.isAddingPage && currentIndex == listIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Reading page ${_viewModel.pageImagePaths.length + 1}...',
              style: const TextStyle(fontFamily: 'Nunito', 
                fontSize: 14,
                color: AppColors.stone500,
              ),
            ),
          ],
        ),
      );
    }

    // Scan Another Page button.
    final pageCount = _viewModel.pageImagePaths.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      child: OutlinedButton.icon(
        onPressed: _viewModel.isAddingPage ? null : _showAddPageSheet,
        icon: const Icon(Icons.add_a_photo),
        label: Text(
          pageCount > 1
              ? 'Scan Another Page ($pageCount scanned)'
              : 'Scan Another Page',
        ),
      ),
    );
  }

  Widget _buildOrderTab() {
    if (!_viewModel.hasOrder) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: AppColors.stone400,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tap + on menu items to\nbuild your order',
                style: const TextStyle(fontFamily: 'Nunito', 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.stone500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final items = _viewModel.orderItemList;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, _) {
              final isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return Divider(
                height: 1,
                indent: AppSpacing.pageHorizontal,
                endIndent: AppSpacing.pageHorizontal,
                color: isDark ? AppColors.stone700 : AppColors.stone200,
              );
            },
            itemBuilder: (context, index) {
              final (idx, item, qty) = items[index];
              return OrderItemRow(
                item: item,
                quantity: qty,
                onAdd: () => _viewModel.addToOrder(idx),
                onRemove: () => _viewModel.removeFromOrder(idx),
              );
            },
          ),
        ),
        // Bottom action area.
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.md,
            AppSpacing.pageHorizontal,
            AppSpacing.md + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Generated phrase card.
              if (_viewModel.orderPhrase != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.saffronFaint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.saffronLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Say this to the waiter:',
                        style: const TextStyle(fontFamily: 'DMSans', 
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.saffronDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _viewModel.orderPhrase!,
                        style: const TextStyle(fontFamily: 'Nunito', 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.stone900,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Action buttons.
              Row(
                children: [
                  // Translate / Speak button.
                  Expanded(
                    child: _viewModel.orderPhrase == null
                        ? FilledButton.icon(
                            onPressed: _viewModel.isGeneratingOrder
                                ? null
                                : () => _viewModel.generateOrderPhrase(),
                            icon: _viewModel.isGeneratingOrder
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.translate),
                            label: Text(
                              _viewModel.isGeneratingOrder
                                  ? 'Translating...'
                                  : 'Translate Order',
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: _viewModel.isSpeakingOrder
                                ? null
                                : () => _viewModel.speakOrder(),
                            icon: Icon(
                              _viewModel.isSpeakingOrder
                                  ? Icons.volume_up
                                  : Icons.volume_up_outlined,
                            ),
                            label: Text(
                              _viewModel.isSpeakingOrder
                                  ? 'Speaking...'
                                  : 'Speak My Order',
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Clear button.
                  OutlinedButton(
                    onPressed: () => _viewModel.clearOrder(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalPhotoTab() {
    final paths = _viewModel.pageImagePaths.isNotEmpty
        ? _viewModel.pageImagePaths
        : [widget.imagePath];

    if (paths.length == 1) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.file(
                File(paths.first),
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
              style: const TextStyle(fontFamily: 'Nunito', 
                fontSize: 12,
                color: AppColors.stone500,
              ),
            ),
          ),
        ],
      );
    }

    // Multiple photos — PageView with page indicator.
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _photoPageController,
            onPageChanged: (page) =>
                setState(() => _currentPhotoPage = page),
            itemCount: paths.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(
                  File(paths[index]),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, size: 48),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(paths.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPhotoPage
                          ? AppColors.terracotta
                          : AppColors.stone400,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Page ${_currentPhotoPage + 1} of ${paths.length}'
                ' -- zoom to read small text',
                style: const TextStyle(fontFamily: 'Nunito', 
                  fontSize: 12,
                  color: AppColors.stone500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
