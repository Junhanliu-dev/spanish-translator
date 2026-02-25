import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Expandable search field for the history screen.
///
/// Slides down when visible, with debounced search callback.
class HistorySearchBar extends StatefulWidget {
  const HistorySearchBar({
    super.key,
    required this.isVisible,
    required this.onSearch,
    required this.onClose,
  });

  /// Whether the search bar is visible.
  final bool isVisible;

  /// Called with the search query after a 300ms debounce.
  final ValueChanged<String> onSearch;

  /// Called when the search bar is closed.
  final VoidCallback onClose;

  @override
  State<HistorySearchBar> createState() => _HistorySearchBarState();
}

class _HistorySearchBarState extends State<HistorySearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      offset: widget.isVisible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: widget.isVisible ? 1.0 : 0.0,
        child: widget.isVisible
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search translations...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _controller.clear();
                        widget.onClose();
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
