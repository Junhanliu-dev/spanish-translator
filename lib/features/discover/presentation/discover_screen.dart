import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../discover_view_model.dart';

/// Discover screen for looking up artworks, sculptures, and landmarks.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final DiscoverViewModel _viewModel;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _viewModel = DiscoverViewModel(
      apiClient: ServiceLocator.apiClient,
      historyRepo: ServiceLocator.historyRepo,
    );
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _viewModel.setQuery(_textController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final isSearching = _viewModel.state == DiscoverState.searching;
          final hasResult = _viewModel.state == DiscoverState.success &&
              _viewModel.result != null;
          final hasError = _viewModel.state == DiscoverState.error;

          return GestureDetector(
            onTap: () => _focusNode.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Search input.
                    TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _viewModel.search(),
                      decoration: InputDecoration(
                        hintText:
                            'Name of art, sculpture, or landmark...',
                        prefixIcon: const Icon(Icons.search, size: 22),
                        suffixIcon: _viewModel.query.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _textController.clear();
                                  _viewModel.clear();
                                },
                                icon: const Icon(Icons.close, size: 20),
                                color: AppColors.stone400,
                              )
                            : null,
                      ),
                    ),
                    // Error message.
                    if (_viewModel.errorMessage != null && hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          _viewModel.errorMessage!,
                          style: const TextStyle(fontFamily: 'Nunito', 
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    // Inline validation error (not API error).
                    if (_viewModel.errorMessage != null && !hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          _viewModel.errorMessage!,
                          style: const TextStyle(fontFamily: 'Nunito', 
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    // Search button.
                    SizedBox(
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isSearching ||
                                _viewModel.query.trim().isEmpty
                            ? null
                            : _viewModel.search,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor:
                              AppColors.terracotta.withValues(alpha: 0.4),
                          disabledForegroundColor:
                              AppColors.white.withValues(alpha: 0.7),
                        ),
                        child: isSearching
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Searching...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.explore, size: 18),
                                  SizedBox(width: 8),
                                  Text('Discover'),
                                ],
                              ),
                      ),
                    ),
                    // Result card.
                    if (hasResult) ...[
                      const SizedBox(height: AppSpacing.xl2),
                      _buildResultCard(context),
                    ],
                    const SizedBox(height: AppSpacing.xl3),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final r = _viewModel.result!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.stone200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with favorite button.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _viewModel.toggleFavorite,
                  icon: Icon(
                    _viewModel.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _viewModel.isFavorite
                        ? AppColors.terracotta
                        : AppColors.stone400,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Type badge + artist/year.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildBadge(r.type),
                if (r.artist != null)
                  _buildBadge(r.artist!, color: AppColors.bilbaoBlue),
                if (r.year != null)
                  _buildBadge(r.year!, color: AppColors.stone600),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Description.
            Text(
              r.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
            // Fun facts.
            if (r.funFacts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fun Facts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.saffronDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...r.funFacts.map(
                (fact) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('  \u2022  '),
                      Expanded(
                        child: Text(
                          fact,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Action row: TTS + copy.
            Row(
              children: [
                // TTS button.
                IconButton.filled(
                  onPressed: _viewModel.isSpeaking
                      ? null
                      : _viewModel.speakDescription,
                  icon: _viewModel.isSpeaking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.volume_up, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.terracottaFaint,
                    foregroundColor: AppColors.terracotta,
                  ),
                  tooltip: 'Listen',
                ),
                const SizedBox(width: AppSpacing.sm),
                // Copy button.
                IconButton.filled(
                  onPressed: () {
                    final text = StringBuffer()
                      ..writeln(r.title)
                      ..writeln(r.description);
                    if (r.funFacts.isNotEmpty) {
                      text.writeln('\nFun Facts:');
                      for (final fact in r.funFacts) {
                        text.writeln('- $fact');
                      }
                    }
                    // ignore: unnecessary_import
                    AppSnackbar.success(context, 'Copied to clipboard');
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.stone100,
                    foregroundColor: AppColors.stone700,
                  ),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, {Color? color}) {
    final badgeColor = color ?? AppColors.terracotta;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}
