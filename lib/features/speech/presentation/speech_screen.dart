import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/speech_state.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/language_toggle_pill.dart';
import '../speech_view_model.dart';
import 'widgets/mic_button.dart';
import 'widgets/source_panel.dart';
import 'widgets/translation_panel.dart';

/// Full-screen speech translation screen.
///
/// Displays source and translation panels, a mic button with recording
/// animations, and language swap/save controls.
class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late final SpeechViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SpeechViewModel(
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

  void _handleMicTap() {
    if (_viewModel.state == SpeechState.idle ||
        _viewModel.state == SpeechState.success) {
      _viewModel.startRecording();
    } else if (_viewModel.state == SpeechState.recording) {
      _viewModel.stopRecording();
    }
  }

  void _showCopiedSnackBar() {
    AppSnackbar.success(context, 'Copied to clipboard');
  }

  void _showSavedSnackBar() {
    AppSnackbar.success(context, 'Saved to History');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Speech'),
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
          final isProcessing = _viewModel.state == SpeechState.processing;

          return SafeArea(
            child: Column(
              children: [
                // Scrollable content area.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        // Source panel.
                        SourcePanel(
                          text: _viewModel.sourceText,
                          detectedLanguage: _viewModel.detectedLanguage,
                          isLoading: isProcessing &&
                              _viewModel.sourceText == null,
                          onCopy: _viewModel.sourceText != null
                              ? () {
                                  _viewModel
                                      .copyText(_viewModel.sourceText!);
                                  _showCopiedSnackBar();
                                }
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Translation panel.
                        TranslationPanel(
                          text: _viewModel.translatedText,
                          targetLanguage: _viewModel.targetLanguageDisplay,
                          isTTSPlaying: _viewModel.isTTSPlaying,
                          isSaved: _viewModel.isSaved,
                          isLoading: isProcessing &&
                              _viewModel.translatedText == null,
                          onPlayTTS: _viewModel.playTTS,
                          onStopTTS: _viewModel.stopTTS,
                          onCopy: _viewModel.translatedText != null
                              ? () {
                                  _viewModel.copyText(
                                    _viewModel.translatedText!,
                                  );
                                  _showCopiedSnackBar();
                                }
                              : null,
                          onSave: _viewModel.translatedText != null
                              ? () async {
                                  await _viewModel.saveToHistory();
                                  if (mounted) _showSavedSnackBar();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom section: mic button + action buttons.
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xl2,
                    left: AppSpacing.pageHorizontal,
                    right: AppSpacing.pageHorizontal,
                  ),
                  child: Column(
                    children: [
                      MicButton(
                        state: _viewModel.state,
                        onTap: _handleMicTap,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Swap / Save buttons row.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Swap languages button.
                          Tooltip(
                            message: 'Conversation mode -- swap languages',
                            child: IconButton(
                              onPressed: _viewModel.swapLanguages,
                              icon: AnimatedRotation(
                                turns: _viewModel.isSwapped ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.swap_horiz),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.stone100,
                              ),
                            ),
                          ),
                          // Language direction indicator.
                          Text(
                            '${_viewModel.sourceLanguageDisplay}'
                            ' → '
                            '${_viewModel.targetLanguageDisplay}',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.stone500,
                            ),
                          ),
                          // Save all button.
                          IconButton(
                            onPressed: _viewModel.translatedText != null &&
                                    !_viewModel.isSaved
                                ? () async {
                                    await _viewModel.saveToHistory();
                                    if (mounted) _showSavedSnackBar();
                                  }
                                : null,
                            icon: Icon(
                              _viewModel.isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                            color: _viewModel.isSaved
                                ? AppColors.terracotta
                                : AppColors.stone400,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.stone100,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
