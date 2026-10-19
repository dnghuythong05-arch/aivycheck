import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gps_config.dart';
import 'gps_service.dart';

class GpsStatusBar extends StatefulWidget {
  final GpsConfig config;
  final String title;
  final String message;
  final String? details;
  final GpsNoticeType noticeType;
  final bool busy;
  final bool showActions;
  final bool draggable;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRetry;
  final VoidCallback? onClearPlace;

  const GpsStatusBar({
    super.key,
    required this.config,
    required this.message,
    this.title = 'Vị trí chấm công',
    this.details,
    this.noticeType = GpsNoticeType.info,
    this.busy = false,
    this.showActions = true,
    this.draggable = false,
    this.onOpenSettings,
    this.onRetry,
    this.onClearPlace,
  });

  @override
  State<GpsStatusBar> createState() => _GpsStatusBarState();
}

class _GpsStatusBarState extends State<GpsStatusBar> {
  double progress = 0;
  bool dragging = false;

  bool get hasDetails => widget.details?.trim().isNotEmpty == true;
  bool get hasContent => widget.showActions || hasDetails;

  Color get color {
    final colors = AiVieTheme.of(context);
    switch (widget.noticeType) {
      case GpsNoticeType.info:
        return colors.primary;
      case GpsNoticeType.success:
        return colors.success;
      case GpsNoticeType.warning:
        return colors.warning;
      case GpsNoticeType.error:
        return colors.error;
    }
  }

  IconData get icon {
    switch (widget.noticeType) {
      case GpsNoticeType.info:
        return Icons.location_on_outlined;
      case GpsNoticeType.success:
        return Icons.check_circle_outline_rounded;
      case GpsNoticeType.warning:
        return Icons.info_outline_rounded;
      case GpsNoticeType.error:
        return Icons.location_off_outlined;
    }
  }

  void toggleExpanded() {
    setState(() {
      dragging = false;
      progress = progress >= 0.5 ? 0 : 1;
    });
  }

  void finishDrag(double velocity) {
    setState(() {
      dragging = false;
      if (velocity < -250) {
        progress = 1;
      } else if (velocity > 250) {
        progress = 0;
      } else {
        progress = progress >= 0.5 ? 1 : 0;
      }
    });
  }

  Widget statusRow() {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: widget.busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: typography.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(widget.message, style: AiVieTheme.secondary(context)),
            ],
          ),
        ),
        if (widget.onClearPlace != null && widget.config.hasCenter) ...[
          const SizedBox(width: 8),
          if (MediaQuery.sizeOf(context).width >= 600)
            TextButton.icon(
              onPressed: widget.busy ? null : widget.onClearPlace,
              style: TextButton.styleFrom(foregroundColor: colors.error),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Xóa địa điểm'),
            )
          else
            IconButton(
              tooltip: 'Xóa địa điểm',
              onPressed: widget.busy ? null : widget.onClearPlace,
              color: colors.error,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
        if (widget.draggable && hasContent) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: progress >= 0.5
                ? 'Thu gọn thông tin GPS'
                : 'Mở thông tin GPS',
            onPressed: toggleExpanded,
            icon: Icon(
              progress >= 0.5
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: colors.muted,
            ),
          ),
        ],
      ],
    );
  }

  Widget content() {
    final theme = Theme.of(context);
    final colors = AiVieTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showActions) ...[
          Text(
            widget.config.hasCenter
                ? 'Phạm vi chấm công: '
                      '${gpsMetersText(widget.config.radiusMeters)} m'
                : 'Chưa thiết lập địa điểm chấm công.',
            style: AiVieTheme.secondary(context, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.onRetry != null)
                OutlinedButton.icon(
                  onPressed: widget.busy ? null : widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Cập nhật vị trí'),
                ),
              if (widget.onOpenSettings != null)
                OutlinedButton.icon(
                  onPressed: widget.busy ? null : widget.onOpenSettings,
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: const Text('Địa điểm chấm công'),
                ),
            ],
          ),
        ],
        if (hasDetails) ...[
          if (widget.showActions) const SizedBox(height: 8),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              iconColor: colors.muted,
              collapsedIconColor: colors.muted,
              title: Text(
                'Xem chi tiết',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.details!,
                    style: AiVieTheme.secondary(
                      context,
                      fontSize: 12,
                    ).copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.border),
    );

    if (!widget.draggable) {
      return Material(
        color: colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              statusRow(),
              if (hasContent) ...[const SizedBox(height: 14), content()],
            ],
          ),
        ),
      );
    }

    final media = MediaQuery.of(context);
    final availableHeight = math.max(
      0.0,
      media.size.height - media.viewInsets.bottom,
    );
    final expandedHeight = math.min(
      180.0,
      math.max(60.0, availableHeight * 0.22),
    );
    final duration = dragging || media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Material(
      color: colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: hasContent
                ? (_) => setState(() => dragging = true)
                : null,
            onVerticalDragUpdate: hasContent
                ? (details) {
                    setState(() {
                      progress = (progress - details.delta.dy / expandedHeight)
                          .clamp(0.0, 1.0)
                          .toDouble();
                    });
                  }
                : null,
            onVerticalDragEnd: hasContent
                ? (details) => finishDrag(details.velocity.pixelsPerSecond.dy)
                : null,
            onVerticalDragCancel: hasContent ? () => finishDrag(0) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderStrong,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  statusRow(),
                ],
              ),
            ),
          ),
          if (hasContent)
            ClipRect(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                height: expandedHeight * progress,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: content(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
