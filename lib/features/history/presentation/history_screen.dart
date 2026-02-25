import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../history_view_model.dart';
import 'widgets/history_detail_sheet.dart';
import 'widgets/history_filter_chips.dart';
import 'widgets/history_list_item.dart';
import 'widgets/history_search_bar.dart';

/// The history screen showing all past translations with search and filters.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HistoryViewModel(
      historyRepo: ServiceLocator.historyRepo,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onItemTap(int index) {
    final translation = _viewModel.translations[index];
    HistoryDetailSheet.show(
      context,
      translation: translation,
      onDelete: () async {
        final deleted =
            await _viewModel.deleteTranslation(translation.id!);
        if (deleted != null && mounted) {
          AppSnackbar.withUndo(
            context,
            message: 'Translation deleted',
            onUndo: () => _viewModel.undoDelete(deleted),
          );
        }
      },
      onToggleFavorite: () {
        _viewModel.toggleFavorite(
          translation.id!,
          translation.isFavorite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _viewModel.toggleSearch,
              ),
            ],
          ),
          body: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable:
                    ServiceLocator.connectivityService.isConnected,
                builder: (context, isConnected, _) {
                  return ConnectivityBanner(isConnected: isConnected);
                },
              ),

              // Search bar.
              HistorySearchBar(
                isVisible: _viewModel.isSearchVisible,
                onSearch: (query) => _viewModel.setSearchQuery(query),
                onClose: _viewModel.toggleSearch,
              ),

              // Filter chips.
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                child: HistoryFilterChips(
                  activeFilter: _viewModel.activeFilter,
                  onFilterChanged: (filter) =>
                      _viewModel.setFilter(filter),
                ),
              ),

              // Content.
              Expanded(
                child: _viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _viewModel.translations.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildList(theme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    if (_viewModel.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.stone300),
            const SizedBox(height: 12),
            Text(
              "No results for '${_viewModel.searchQuery}'",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.stone500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try different keywords.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.stone400,
              ),
            ),
          ],
        ),
      );
    }

    if (_viewModel.activeFilter != null) {
      final filterLabel = _viewModel.activeFilter!;
      final iconData = switch (filterLabel) {
        'speech' => Icons.mic,
        'photo' => Icons.camera_alt,
        _ => Icons.text_fields,
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 48, color: AppColors.stone300),
            const SizedBox(height: 12),
            Text(
              'No $filterLabel translations',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.stone500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your $filterLabel translations appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.stone400,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.stone300),
          const SizedBox(height: 12),
          Text(
            'No translations yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your translations will be saved here automatically.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.stone400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.home),
            child: const Text('Start Translating'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    final grouped = _viewModel.groupedByDate;
    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl6),
      itemCount: entries.fold<int>(
        0,
        (sum, e) => sum + 1 + e.value.length,
      ),
      itemBuilder: (context, index) {
        var offset = 0;
        for (final entry in entries) {
          if (index == offset) {
            // Date header.
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                AppSpacing.sm,
              ),
              child: Text(
                entry.key.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.stone500,
                  letterSpacing: 1.0,
                ),
              ),
            );
          }
          offset++;

          if (index < offset + entry.value.length) {
            final itemIndex = index - offset;
            final translation = entry.value[itemIndex];
            final globalIndex =
                _viewModel.translations.indexOf(translation);
            return HistoryListItem(
              translation: translation,
              onTap: () => _onItemTap(globalIndex),
              onDismissed: () async {
                final deleted = await _viewModel.deleteTranslation(
                  translation.id!,
                );
                if (deleted != null && context.mounted) {
                  AppSnackbar.withUndo(
                    context,
                    message: 'Translation deleted',
                    onUndo: () => _viewModel.undoDelete(deleted),
                  );
                }
              },
              onToggleFavorite: () => _viewModel.toggleFavorite(
                translation.id!,
                translation.isFavorite,
              ),
            );
          }
          offset += entry.value.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}
