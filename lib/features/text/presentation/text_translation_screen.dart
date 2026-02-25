import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/language_toggle_pill.dart';
import '../text_view_model.dart';
import 'widgets/clipboard_paste_banner.dart';
import 'widgets/direction_toggle.dart';
import 'widgets/translation_result_card.dart';

/// Full-screen text translation screen.
///
/// Provides a text input field, direction toggle, translate button,
/// result card with collapsible sections, and recent translations.
class TextTranslationScreen extends StatefulWidget {
  const TextTranslationScreen({super.key});

  @override
  State<TextTranslationScreen> createState() => _TextTranslationScreenState();
}

class _TextTranslationScreenState extends State<TextTranslationScreen>
    with WidgetsBindingObserver {
  late final TextViewModel _viewModel;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  String? _clipboardContent;
  bool _clipboardBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _viewModel = TextViewModel(
      apiClient: ServiceLocator.apiClient,
      historyRepo: ServiceLocator.historyRepo,
      languagePrefs: ServiceLocator.languagePrefs,
    );

    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
    _focusNode = FocusNode();

    _viewModel.loadRecentTranslations();
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _focusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  void _onTextChanged() {
    _viewModel.setInputText(_textController.text);
  }

  Future<void> _checkClipboard() async {
    final content = await _viewModel.checkClipboard();
    if (content != null && content != _clipboardContent) {
      setState(() {
        _clipboardContent = content;
        _clipboardBannerDismissed = false;
      });
    }
  }

  void _pasteFromClipboard() {
    if (_clipboardContent != null) {
      _textController.text = _clipboardContent!;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      setState(() {
        _clipboardBannerDismissed = true;
      });
    }
  }

  void _showCopiedSnackBar() {
    AppSnackbar.success(context, 'Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Text Translation'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: ListenableBuilder(
              listenable: ServiceLocator.languagePrefs,
              builder: (context, _) {
                return LanguageTogglePill(
                  selected: ServiceLocator.languagePrefs.targetLanguage,
                  onChanged: (lang) {
                    ServiceLocator.languagePrefs.targetLanguage = lang;
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final isTranslating =
              _viewModel.state == TextTranslationState.translating;
          final hasResult =
              _viewModel.state == TextTranslationState.success &&
                  _viewModel.result != null;
          final hasError =
              _viewModel.state == TextTranslationState.error;

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
                    // Clipboard paste banner.
                    if (_clipboardContent != null &&
                        !_clipboardBannerDismissed)
                      ClipboardPasteBanner(
                        clipboardText: _clipboardContent!,
                        onPaste: _pasteFromClipboard,
                        onDismiss: () {
                          setState(() {
                            _clipboardBannerDismissed = true;
                          });
                        },
                      ),
                    const SizedBox(height: AppSpacing.md),
                    // Text input area.
                    _buildInputField(context),
                    // Error message.
                    if (_viewModel.errorMessage != null && hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          _viewModel.errorMessage!,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    // Direction toggle.
                    DirectionToggle(
                      sourceLanguage: _viewModel.sourceLanguageDisplay,
                      targetLanguage: _viewModel.targetLanguageDisplay,
                      isReversed: _viewModel.isReversed,
                      onToggle: _viewModel.toggleDirection,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Translate button.
                    SizedBox(
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isTranslating ||
                                _viewModel.inputText.trim().isEmpty
                            ? null
                            : _viewModel.translate,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor:
                              AppColors.terracotta.withValues(alpha: 0.4),
                          disabledForegroundColor:
                              AppColors.white.withValues(alpha: 0.7),
                        ),
                        child: isTranslating
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
                                  Text('Translating...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Translate'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                    // Translation result card.
                    if (hasResult) ...[
                      const SizedBox(height: AppSpacing.xl2),
                      TranslationResultCard(
                        result: _viewModel.result!,
                        sourceText: _viewModel.inputText,
                        detectedLanguage: _viewModel.detectedLanguage,
                        contextExpanded: _viewModel.contextExpanded,
                        pronunciationExpanded:
                            _viewModel.pronunciationExpanded,
                        isFavorite: _viewModel.isFavorite,
                        onToggleContext: _viewModel.toggleContext,
                        onTogglePronunciation:
                            _viewModel.togglePronunciation,
                        onCopyTranslation: () {
                          _viewModel
                              .copyText(_viewModel.result!.translatedText);
                          _showCopiedSnackBar();
                        },
                        onCopyAll: () {
                          final all = StringBuffer()
                            ..writeln(_viewModel.result!.translatedText);
                          if (_viewModel.result!.context != null) {
                            all.writeln(
                              '\nContext: ${_viewModel.result!.context}',
                            );
                          }
                          if (_viewModel.result!.pronunciation != null) {
                            all.writeln(
                              '\nPronunciation: '
                              '${_viewModel.result!.pronunciation}',
                            );
                          }
                          _viewModel.copyText(all.toString());
                          _showCopiedSnackBar();
                        },
                        onToggleFavorite: _viewModel.toggleFavorite,
                      ),
                    ],
                    // Recent translations.
                    if (_viewModel.recentTranslations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl2),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Recent',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.stone500,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ..._viewModel.recentTranslations.map((t) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            t.sourceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            t.translatedText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.stone500,
                                    ),
                          ),
                          onTap: () {
                            _textController.text = t.sourceText;
                            _viewModel.translate();
                          },
                        );
                      }),
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

  Widget _buildInputField(BuildContext context) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 4,
      maxLength: 5000,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _viewModel.translate(),
      decoration: InputDecoration(
        hintText: _viewModel.isReversed
            ? 'Type or paste ${_viewModel.sourceLanguageDisplay} text...'
            : 'Type or paste Spanish or Basque text here...',
        counterText: _viewModel.inputText.length > 500
            ? '${_viewModel.inputText.length} characters'
            : '',
        suffixIcon: _viewModel.inputText.isNotEmpty
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
    );
  }
}
