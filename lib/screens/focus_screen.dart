import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/user_record_provider.dart';

const _background = Color(0xFFF4F9F4);
const _ink = Color(0xFF35413A);
const _mutedInk = Color(0xFF89938C);
const _mint = Color(0xFF72D695);
const _softYellow = Color(0xFFFFEDB5);
const _white = Color(0xFFFFFFFF);

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    required this.task,
    this.initialDuration = const Duration(minutes: 25),
    super.key,
  });

  final Task task;
  final Duration initialDuration;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  late int timeLeft;
  bool isRunning = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    timeLeft = widget.initialDuration.inSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (isRunning) {
      _pauseTimer();
      return;
    }

    _startTimer();
  }

  void _startTimer() {
    if (timeLeft <= 0 || _isCompleting) {
      return;
    }

    _timer?.cancel();
    setState(() {
      isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      if (timeLeft <= 1) {
        setState(() {
          timeLeft = 0;
          isRunning = false;
        });
        _timer?.cancel();
        unawaited(_completeFocusSession());
        return;
      }

      setState(() {
        timeLeft -= 1;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  Future<void> _confirmGiveUp() async {
    final shouldGiveUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '确定要放弃吗？',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '小树会很伤心的，你的专注能量也会溜走哦 🍂',
            style: TextStyle(
              color: _mutedInk,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('继续专注'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE17A67),
              ),
              child: const Text('残忍放弃'),
            ),
          ],
        );
      },
    );

    if (shouldGiveUp == true && mounted) {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  Future<void> _completeFocusSession() async {
    if (_isCompleting) {
      return;
    }
    _isCompleting = true;

    final taskProvider = context.read<TaskProvider>();
    final userRecordProvider = context.read<UserRecordProvider?>();
    var latestTask = widget.task;
    for (final task in taskProvider.tasks) {
      if (task.id == widget.task.id) {
        latestTask = task;
        break;
      }
    }
    if (!latestTask.isCompleted) {
      await taskProvider.updateTask(latestTask.markCompleted());
      await userRecordProvider?.addFocusSession(widget.initialDuration);
    }

    if (!mounted) {
      return;
    }

    final shouldReturn = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '专注完成',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _CompletionDialog(
          onReturn: () => Navigator.pop(dialogContext, true),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curve, child: child),
        );
      },
    );

    if (shouldReturn == true && mounted) {
      Navigator.pop(context);
    }
  }

  String get _formattedTime {
    final minutes = timeLeft ~/ 60;
    final seconds = timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              const Text(
                '这一刻，只做眼前这一件事',
                style: TextStyle(
                  color: _mutedInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dialSize = constraints.maxWidth.clamp(260.0, 360.0);
                  return Center(
                    child: Container(
                      width: dialSize,
                      height: dialSize,
                      decoration: BoxDecoration(
                        color: _white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _mint.withValues(alpha: 0.12),
                            blurRadius: 32,
                            spreadRadius: 8,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              isRunning ? '👨‍💻' : '☕️',
                              key: ValueKey(isRunning),
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formattedTime,
                              style: TextStyle(
                                color: isRunning ? _mint : _mutedInk,
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 0,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isRunning ? '专注进行中，保持呼吸' : '休息一下，准备好了再开始',
                            style: const TextStyle(
                              color: _mutedInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 42),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: Material(
                  color: isRunning ? _softYellow : _mint,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: _toggleTimer,
                    borderRadius: BorderRadius.circular(999),
                    child: Center(
                      child: Text(
                        isRunning ? '⏸️ 暂停一下' : '🚀 开始专注',
                        style: TextStyle(
                          color: isRunning
                              ? const Color(0xFF8A7335)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _confirmGiveUp,
                style: TextButton.styleFrom(
                  foregroundColor: _mutedInk,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('🥺 放弃挣扎'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  const _CompletionDialog({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 330,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF2),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _mint.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 760),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: const Text('🎉', style: TextStyle(fontSize: 82)),
              ),
              const SizedBox(height: 12),
              const Text(
                '🏆 专注完成！',
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '太棒了！不仅干掉了待办，还给小树积攒了 50 点能量！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onReturn,
                  style: FilledButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '满载而归',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
