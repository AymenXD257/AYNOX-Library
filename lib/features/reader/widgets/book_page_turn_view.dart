import 'dart:math' as math;
import 'package:flutter/material.dart';

class BookPageTurnView extends StatefulWidget {
  final int itemCount;
  final int initialPage;
  final String mode; // 'curl', 'slide', 'scroll'
  final bool isRtl;
  final Widget Function(BuildContext context, int pageIndex) pageBuilder;
  final ValueChanged<int>? onPageChanged;

  const BookPageTurnView({
    super.key,
    required this.itemCount,
    this.initialPage = 0,
    this.mode = 'curl',
    this.isRtl = false,
    required this.pageBuilder,
    this.onPageChanged,
  });

  @override
  State<BookPageTurnView> createState() => BookPageTurnViewState();
}

class BookPageTurnViewState extends State<BookPageTurnView> with SingleTickerProviderStateMixin {
  late int _currentPage;
  late PageController _pageController;
  late ScrollController _scrollController;

  // For realistic curl animation
  late AnimationController _curlController;
  double _dragProgress = 0.0;
  bool _isDraggingNext = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, math.max(0, widget.itemCount - 1));
    _pageController = PageController(initialPage: _currentPage);
    _scrollController = ScrollController();
    _curlController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant BookPageTurnView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage && _currentPage != widget.initialPage) {
      jumpToPage(widget.initialPage);
    }
  }

  void jumpToPage(int page) {
    if (page < 0 || page >= widget.itemCount) return;
    setState(() {
      _currentPage = page;
    });
    if (widget.mode == 'scroll') {
      // In scroll mode, jump approximately
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final target = (page / math.max(1, widget.itemCount)) * max;
        _scrollController.jumpTo(target);
      }
    } else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(page);
      }
    }
    widget.onPageChanged?.call(page);
  }

  void nextPage() {
    if (_currentPage < widget.itemCount - 1) {
      if (widget.mode == 'curl') {
        _animateCurl(toNext: true);
      } else if (_pageController.hasClients) {
        _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      if (widget.mode == 'curl') {
        _animateCurl(toNext: false);
      } else if (_pageController.hasClients) {
        _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    }
  }

  void _animateCurl({required bool toNext}) {
    setState(() {
      _isDraggingNext = toNext;
    });
    _curlController.forward(from: 0.0).then((_) {
      _curlController.reset();
      setState(() {
        if (toNext && _currentPage < widget.itemCount - 1) {
          _currentPage++;
        } else if (!toNext && _currentPage > 0) {
          _currentPage--;
        }
      });
      widget.onPageChanged?.call(_currentPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _curlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const Center(child: Text('No pages available'));
    }

    if (widget.mode == 'scroll') {
      return ListView.builder(
        controller: _scrollController,
        itemCount: widget.itemCount,
        itemBuilder: (context, i) {
          return SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: widget.pageBuilder(context, i),
          );
        },
      );
    }

    if (widget.mode == 'slide') {
      return PageView.builder(
        controller: _pageController,
        itemCount: widget.itemCount,
        reverse: widget.isRtl,
        onPageChanged: (i) {
          setState(() {
            _currentPage = i;
          });
          widget.onPageChanged?.call(i);
        },
        itemBuilder: (context, i) {
          return widget.pageBuilder(context, i);
        },
      );
    }

    // Default: Realistic Page Curl Mode with interactive drag & 3D shadow illusion
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final delta = details.primaryDelta ?? 0;
        final isForward = widget.isRtl ? delta > 0 : delta < 0;
        setState(() {
          _dragProgress = (delta.abs() / 250).clamp(0.0, 1.0);
          _isDraggingNext = isForward;
        });
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final shouldTurn = velocity.abs() > 200 || _dragProgress > 0.35;
        if (shouldTurn) {
          _animateCurl(toNext: _isDraggingNext);
        }
        setState(() {
          _dragProgress = 0.0;
        });
      },
      child: AnimatedBuilder(
        animation: _curlController,
        builder: (context, _) {
          final animVal = _curlController.isAnimating ? _curlController.value : _dragProgress;
          final nextPageIndex = _isDraggingNext ? _currentPage + 1 : _currentPage - 1;
          final hasTargetPage = nextPageIndex >= 0 && nextPageIndex < widget.itemCount;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Underneath page (destination)
              if (animVal > 0 && hasTargetPage)
                widget.pageBuilder(context, nextPageIndex),

              // Current page being curled away
              Transform(
                alignment: widget.isRtl
                    ? (_isDraggingNext ? Alignment.centerRight : Alignment.centerLeft)
                    : (_isDraggingNext ? Alignment.centerLeft : Alignment.centerRight),
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY((_isDraggingNext ? -1 : 1) * animVal * (math.pi / 2.6)),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: animVal > 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: (0.45 * (1 - animVal)).clamp(0.0, 0.5)),
                              blurRadius: 16 * animVal,
                              offset: Offset((_isDraggingNext ? -1 : 1) * 12 * animVal, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: widget.pageBuilder(context, _currentPage),
                ),
              ),

              // Page curl edge glow/shadow overlay
              if (animVal > 0.05)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: widget.isRtl ? Alignment.centerLeft : Alignment.centerRight,
                          end: widget.isRtl ? Alignment.centerRight : Alignment.centerLeft,
                          colors: [
                            Colors.black.withValues(alpha: (0.35 * animVal).clamp(0.0, 0.35)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
