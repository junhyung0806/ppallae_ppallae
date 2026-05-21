import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HoverOverflowText extends StatefulWidget {
  const HoverOverflowText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;

  @override
  State<HoverOverflowText> createState() => _HoverOverflowTextState();
}

class _HoverOverflowTextState extends State<HoverOverflowText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _isHovered = false;
  bool _isOverflowing = false;
  double _overflowWidth = 0;
  double _lineHeight = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(widget.style);

    if (!kIsWeb) {
      return Text(
        widget.text,
        style: effectiveStyle,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: widget.textAlign,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateMetrics(
            maxWidth: constraints.maxWidth,
            style: effectiveStyle,
          );
        });

        if (!_isOverflowing || !_isHovered) {
          return MouseRegion(
            onEnter: (_) {
              _isHovered = true;
              _syncAnimation();
              setState(() {});
            },
            onExit: (_) {
              _isHovered = false;
              _syncAnimation();
              setState(() {});
            },
            child: Text(
              widget.text,
              style: effectiveStyle,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.textAlign,
            ),
          );
        }

        return MouseRegion(
          onEnter: (_) {
            _isHovered = true;
            _syncAnimation();
            setState(() {});
          },
          onExit: (_) {
            _isHovered = false;
            _syncAnimation();
            setState(() {});
          },
          child: ClipRect(
            child: SizedBox(
              height: _lineHeight,
              width: constraints.maxWidth,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = -_overflowWidth * _controller.value;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.text,
                    style: effectiveStyle,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: widget.textAlign,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateMetrics({
    required double maxWidth,
    required TextStyle style,
  }) {
    if (!mounted || maxWidth <= 0) {
      return;
    }

    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final nextLineHeight = painter.preferredLineHeight;
    final double nextOverflow =
        math.max<double>(0, painter.width - maxWidth).toDouble();
    final nextIsOverflowing = nextOverflow > 2;

    if (_lineHeight != nextLineHeight ||
        _overflowWidth != nextOverflow ||
        _isOverflowing != nextIsOverflowing) {
      _lineHeight = nextLineHeight;
      _overflowWidth = nextOverflow;
      _isOverflowing = nextIsOverflowing;
      _syncAnimation();
      setState(() {});
    }
  }

  void _syncAnimation() {
    if (!_isHovered || !_isOverflowing) {
      _controller.stop();
      _controller.value = 0;
      return;
    }

    final durationMs = math.max(5000, (_overflowWidth * 42).round());
    _controller.duration = Duration(milliseconds: durationMs);
    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }
}
