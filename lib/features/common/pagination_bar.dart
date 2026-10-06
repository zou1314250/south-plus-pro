import 'package:flutter/material.dart';

import '../../models/forum_models.dart';
import '../../theme/app_theme.dart';

/// Page selector used by board, search and any other paged thread list.
///
/// Extracted from the board list so the search screen can reuse it: the board
/// widgets file is a `part of` its screen, so it cannot be imported directly.
class ThreadPaginationBar extends StatelessWidget {
  const ThreadPaginationBar({
    super.key,
    required this.page,
    required this.onPageSelected,
  });

  final ForumThreadPage page;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (page.totalPages <= 1) {
      return const SizedBox(height: 2);
    }
    final visiblePages = _visiblePages();

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageTextButton(
            label: '«',
            enabled: page.hasPrevious,
            onPressed: () => onPageSelected(page.currentPage - 1),
          ),
          _PageNumberButton(
            label: '${visiblePages.first}',
            selected: visiblePages.first == page.currentPage,
            onPressed: () => onPageSelected(visiblePages.first),
          ),
          for (final pageNumber in visiblePages.skip(1))
            _PageNumberButton(
              label: '$pageNumber',
              selected: pageNumber == page.currentPage,
              onPressed: () => onPageSelected(pageNumber),
            ),
          _PageTextButton(
            label: '跳转',
            enabled: true,
            wide: true,
            onPressed: () => _showJumpDialog(context),
          ),
          _PageTextButton(
            label: '»',
            enabled: page.hasNext,
            onPressed: () => onPageSelected(page.currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<int> _visiblePages() {
    const windowSize = 5;
    final total = page.totalPages < 1 ? 1 : page.totalPages;
    final current = page.currentPage.clamp(1, total);
    if (total <= windowSize) {
      return [for (var i = 1; i <= total; i++) i];
    }

    var start = current - 2;
    var end = current + 2;
    if (start < 1) {
      end += 1 - start;
      start = 1;
    }
    if (end > total) {
      start -= end - total;
      end = total;
    }
    if (start < 1) start = 1;
    return [for (var i = start; i <= end; i++) i];
  }

  Future<void> _showJumpDialog(BuildContext context) async {
    final controller = TextEditingController(text: '${page.currentPage}');
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('跳转页码'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '页码',
              helperText: '1 - ${page.totalPages}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final input = int.tryParse(controller.text.trim());
                if (input == null) return;
                Navigator.of(context).pop(input.clamp(1, page.totalPages));
              },
              child: const Text('跳转'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (selected != null) onPageSelected(selected);
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _PageBox(
      label: label,
      onPressed: onPressed,
      background: selected ? AppColors.brand : AppColors.surface,
      foreground: selected ? Colors.white : AppColors.link,
    );
  }
}

class _PageTextButton extends StatelessWidget {
  const _PageTextButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.wide = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return _PageBox(
      label: label,
      onPressed: enabled ? onPressed : null,
      width: wide ? 52 : 34,
      background: AppColors.surface,
      foreground: enabled ? AppColors.link : AppColors.textFaint,
    );
  }
}

class _PageBox extends StatelessWidget {
  const _PageBox({
    required this.label,
    required this.background,
    required this.foreground,
    this.onPressed,
    this.width = 34,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 34,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
