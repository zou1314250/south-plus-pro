part of 'board_thread_list_screen.dart';

sealed class _BoardListItem {
  const _BoardListItem();

  static List<_BoardListItem> fromPage(ForumThreadPage page) {
    final threads = page.threads;
    return [
      ...page.ads.map(_BoardAdItem.new),
      ...threads.map(_BoardThreadItem.new),
    ];
  }
}

class _BoardThreadItem extends _BoardListItem {
  const _BoardThreadItem(this.thread);

  final ForumThread thread;
}

class _BoardAdItem extends _BoardListItem {
  const _BoardAdItem(this.ad);

  final ForumBoardAd ad;
}

class _BoardThreadListSkeleton extends StatelessWidget {
  const _BoardThreadListSkeleton();

  @override
  Widget build(BuildContext context) {
    const itemCount = 9;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final hasPreview = index % 3 != 1;

        return _ListLine(
          minHeight: hasPreview ? 86 : 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.86 : 0.72,
                      child: const SkeletonBlock(
                        height: 15,
                        borderRadius: 999,
                      ),
                    ),
                    if (hasPreview) ...[
                      const SizedBox(height: 7),
                      const FractionallySizedBox(
                        widthFactor: 0.62,
                        child: SkeletonBlock(height: 12, borderRadius: 999),
                      ),
                    ],
                    const SizedBox(height: 7),
                    FractionallySizedBox(
                      widthFactor: index % 4 == 0 ? 0.5 : 0.42,
                      child: const SkeletonBlock(
                        height: 12,
                        borderRadius: 999,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SkeletonBlock(width: 50, height: 24, borderRadius: 999),
            ],
          ),
        );
      },
    );
  }
}

class _BoardAdBanner extends StatelessWidget {
  const _BoardAdBanner({
    required this.ad,
    required this.onTap,
  });

  final ForumBoardAd ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ad.imageUrl;
    if (imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 6, 28, 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
            final height = math.max(width / 4.65, 56.0);

            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: double.infinity,
                    height: height,
                    child: CachedForumImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: width.ceil(),
                      memCacheHeight: height.ceil(),
                      errorWidget: (context) {
                        return Container(
                          alignment: Alignment.center,
                          color: AppColors.surfaceTint,
                          child: Text(
                            ad.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: _ListLine(
          minHeight: 76,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.link,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      ad.subtitle == null || ad.subtitle!.isEmpty
                          ? '广告'
                          : ad.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '广告',
                  style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubBoardPanel extends StatelessWidget {
  const _SubBoardPanel({
    required this.boards,
    required this.onBoardTap,
  });

  final List<ForumBoard> boards;
  final ValueChanged<ForumBoard> onBoardTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined,
                  color: AppColors.textMuted, size: 15),
              const SizedBox(width: 5),
              Text(
                '子版块',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final board in boards)
                  _SubBoardChip(
                    board: board,
                    onTap: () => onBoardTap(board),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubBoardChip extends StatelessWidget {
  const _SubBoardChip({
    required this.board,
    required this.onTap,
  });

  final ForumBoard board;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inkSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34, maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.subdirectory_arrow_right_outlined,
                  color: AppColors.brand, size: 14),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  board.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.link,
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubBoardOnlyHint extends StatelessWidget {
  const _SubBoardOnlyHint();

  @override
  Widget build(BuildContext context) {
    return _ListLine(
      minHeight: 74,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '这个板块的主题在子版块中',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListLine extends StatelessWidget {
  const _ListLine({
    required this.child,
    this.minHeight = 64,
  });

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 28, 9),
              child: child,
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.8,
            indent: 20,
            endIndent: 20,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({
    required this.title,
    required this.slug,
    required this.onCompose,
  });

  final String title;
  final String slug;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.header,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: '返回',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.chevron_left, size: 30),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: '发帖',
                onPressed: onCompose,
                icon: Icon(Icons.edit_outlined, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                '南+ South Plus',
                style: TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.link,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / $slug',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.repository,
    required this.onTap,
  });

  final ForumThread thread;
  final ForumRepository repository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewImageUrl = thread.previewImageUrl;
    return PerfTrace.span(
      'BoardThreadRow.build',
      () {
        return Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: onTap,
            child: _ListLine(
              minHeight: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: thread.isSticky
                                ? AppColors.brandDark
                                : AppColors.text,
                            fontSize: 15.5,
                            height: 1.35,
                            fontWeight: thread.isSticky
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        if (thread.bodyPreview != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            thread.bodyPreview!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ],
                        if (previewImageUrl != null) ...[
                          const SizedBox(height: 10),
                          _ThreadPreviewImage(url: previewImageUrl),
                        ],
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            if (thread.author != null)
                              InkWell(
                                onTap: thread.authorUrl == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => UserProfileScreen(
                                              userUrl: thread.authorUrl!,
                                              repository: repository,
                                            ),
                                          ),
                                        ),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    thread.author!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                '匿名',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                thread.lastPost == null
                                    ? ''
                                    : ' - 发布于 ${thread.lastPost}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    constraints: const BoxConstraints(minWidth: 50),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.inkSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${thread.replies} 回',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      arguments: {'hasPreview': previewImageUrl != null},
    );
  }
}

class _ThreadPreviewImage extends StatefulWidget {
  const _ThreadPreviewImage({required this.url});

  final String url;

  @override
  State<_ThreadPreviewImage> createState() => _ThreadPreviewImageState();
}

class _ThreadPreviewImageState extends State<_ThreadPreviewImage> {
  Size? _imageSize;
  String? _metadataRequestUrl;

  @override
  void initState() {
    super.initState();
    _imageSize = ForumImageMetadataCache.instance.peek(widget.url);
  }

  @override
  void didUpdateWidget(covariant _ThreadPreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;
    _imageSize = ForumImageMetadataCache.instance.peek(widget.url);
    _metadataRequestUrl = null;
  }

  void _ensureMetadata(ImageProvider provider) {
    if (_imageSize != null || _metadataRequestUrl == widget.url) return;
    final url = widget.url;
    _metadataRequestUrl = url;
    ForumImageMetadataCache.instance.get(url, provider).then((size) {
      if (!mounted || widget.url != url) return;
      if (size == null) {
        _metadataRequestUrl = null;
        return;
      }
      if (size == _imageSize) {
        return;
      }
      setState(() {
        _imageSize = size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _imageSize == null
            ? ThreadPreviewImageLayout.fallback(constraints.maxWidth)
            : ThreadPreviewImageLayout.resolve(
                imageSize: _imageSize!,
                maxWidth: constraints.maxWidth,
              );
        final spec = ForumImageDecodeSpec.forDisplay(
          logicalSize: layout.size,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          maxLongEdge: 960,
        );

        return RepaintBoundary(
          child: CachedForumImage(
            url: widget.url,
            width: layout.size.width,
            height: layout.size.height,
            fit: layout.fit,
            memCacheWidth: spec.memCacheWidth,
            memCacheHeight: spec.memCacheHeight,
            maxWidthDiskCache: spec.maxWidthDiskCache,
            maxHeightDiskCache: spec.maxHeightDiskCache,
            placeholder: (context) => _ThreadPreviewPlaceholder(
              layout: layout,
            ),
            imageBuilder: (context, provider) {
              _ensureMetadata(provider);
              return PerfTrace.span(
                'BoardThreadPreviewImage.build',
                () {
                  return _ThreadPreviewFrame(
                    layout: layout,
                    child: Image(
                      image: provider,
                      width: layout.size.width,
                      height: layout.size.height,
                      fit: layout.fit,
                    ),
                  );
                },
                arguments: {'resolved': _imageSize != null},
              );
            },
            errorWidget: (context) => _ThreadPreviewError(
              width: layout.size.width,
              height: layout.size.height,
            ),
          ),
        );
      },
    );
  }
}

class _ThreadPreviewFrame extends StatelessWidget {
  const _ThreadPreviewFrame({
    required this.layout,
    required this.child,
  });

  final ThreadPreviewImageLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: layout.size.width,
          height: layout.size.height,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.surfaceTint),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ThreadPreviewPlaceholder extends StatelessWidget {
  const _ThreadPreviewPlaceholder({required this.layout});

  final ThreadPreviewImageLayout layout;

  @override
  Widget build(BuildContext context) {
    return _ThreadPreviewFrame(
      layout: layout,
      child: const SizedBox.expand(),
    );
  }
}

class _ThreadPreviewError extends StatelessWidget {
  const _ThreadPreviewError({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: AppColors.surfaceTint,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Horizontal tab strip for board topic classifications.
///
/// Mirrors the forum's own `thread_type_*` row: 全部 / 精华 / per-board types
/// such as 同人音声 or 中文音声.
class _ThreadFilterBar extends StatelessWidget {
  const _ThreadFilterBar({
    required this.filters,
    required this.activeId,
    required this.onSelect,
  });

  final List<ForumThreadFilter> filters;
  final String activeId;
  final ValueChanged<ForumThreadFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            return _ThreadFilterChip(
              filter: filter,
              selected: filter.id == activeId,
              onTap: () => onSelect(filter),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadFilterChip extends StatelessWidget {
  const _ThreadFilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final ForumThreadFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : AppColors.inkSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.border,
              width: 0.8,
            ),
          ),
          // A `Container` with `alignment` expands to the widest allowed size,
          // so the old `maxWidth: 168` + `alignment: center` combination made
          // every tab stretch to 168px and two of them filled the whole row.
          // Size to the label instead, and centre it inside a fixed-height row.
          child: SizedBox(
            height: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    filter.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.link,
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
