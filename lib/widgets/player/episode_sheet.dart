import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/episode.dart';
import '../../services/video_save_service.dart';
import '../episode_selector.dart';

Future<void> showPlayerEpisodeSheet({
  required BuildContext context,
  required bool isLandscapeFullScreen,
  required String dramaName,
  required List<Episode> episodes,
  required ValueListenable<int> episodeNotifier,
  required ValueChanged<int> onSelectEpisode,
  String? currentCdnUrl,
  String? currentKeyHex,
}) {
  if (isLandscapeFullScreen) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        final media = MediaQuery.of(context);
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _EpisodeSheetPanel(
              width: media.size.width * 0.7,
              height: media.size.height * 0.7,
              dramaName: dramaName,
              episodes: episodes,
              episodeNotifier: episodeNotifier,
              onSelectEpisode: onSelectEpisode,
              titleVerticalPadding: 16,
              currentCdnUrl: currentCdnUrl,
              currentKeyHex: currentKeyHex,
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (context) {
      final media = MediaQuery.of(context);
      final bottomPadding =
          (media.viewPadding.bottom * 0.5).clamp(8.0, 18.0).toDouble();

      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: _EpisodeSheetPanel(
          height: media.size.height * 0.45 + bottomPadding,
          bottomPadding: bottomPadding,
          dramaName: dramaName,
          episodes: episodes,
          episodeNotifier: episodeNotifier,
          onSelectEpisode: onSelectEpisode,
          showHandle: true,
          currentCdnUrl: currentCdnUrl,
          currentKeyHex: currentKeyHex,
        ),
      );
    },
  );
}

class _EpisodeSheetPanel extends StatefulWidget {
  const _EpisodeSheetPanel({
    required this.height,
    required this.dramaName,
    required this.episodes,
    required this.episodeNotifier,
    required this.onSelectEpisode,
    this.width,
    this.bottomPadding = 0,
    this.titleVerticalPadding = 12,
    this.showHandle = false,
    this.currentCdnUrl,
    this.currentKeyHex,
  });

  final double? width;
  final double height;
  final double bottomPadding;
  final double titleVerticalPadding;
  final bool showHandle;
  final String dramaName;
  final List<Episode> episodes;
  final ValueListenable<int> episodeNotifier;
  final ValueChanged<int> onSelectEpisode;
  final String? currentCdnUrl;
  final String? currentKeyHex;

  @override
  State<_EpisodeSheetPanel> createState() => _EpisodeSheetPanelState();
}

class _EpisodeSheetPanelState extends State<_EpisodeSheetPanel> {
  bool _isSaving = false;

  Future<void> _saveCurrentVideo() async {
    if (widget.currentCdnUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取视频信息')),
      );
      return;
    }

    // 获取当前正在播放的集数
    final episodeNotifier = widget.episodeNotifier as ValueNotifier<int>;
    final currentIndex = episodeNotifier.value;
    final currentEpisode = widget.episodes[currentIndex];

    setState(() => _isSaving = true);

    try {
      final result = await VideoSaveService.saveVideo(
        cdnUrl: widget.currentCdnUrl!,
        keyHex: widget.currentKeyHex ?? '',
        dramaName: widget.dramaName,
        episodeName: '第${currentEpisode.index}集',
      );

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('视频已保存: $result')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存视频失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.width == null ? 0.1 : 0.2),
            blurRadius: widget.width == null ? 10 : 20,
            offset: widget.width == null ? const Offset(0, -2) : const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: Column(
          children: [
            if (widget.showHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            _EpisodeSheetHeader(
              dramaName: widget.dramaName,
              episodeCount: widget.episodes.length,
              verticalPadding: widget.titleVerticalPadding,
              onSave: _saveCurrentVideo,
              isSaving: _isSaving,
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.episodeNotifier,
                builder: (context, currentIndex, _) {
                  return EpisodeSelector(
                    episodes: widget.episodes,
                    activeIndex: currentIndex,
                    onSelect: (index) {
                      Navigator.of(context).pop();
                      widget.onSelectEpisode(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeSheetHeader extends StatelessWidget {
  const _EpisodeSheetHeader({
    required this.dramaName,
    required this.episodeCount,
    required this.verticalPadding,
    required this.onSave,
    required this.isSaving,
  });

  final String dramaName;
  final int episodeCount;
  final double verticalPadding;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dramaName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '更新至 $episodeCount 集',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 保存按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSaving ? null : onSave,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSaving
                      ? Colors.grey.withValues(alpha: 0.3)
                      : const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSaving) ...
                      [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ]
                    else
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      isSaving ? '保存中' : '保存',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 关闭按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF424242),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
