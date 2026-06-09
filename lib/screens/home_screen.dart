import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/main_navigation_controller.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/tree_growth_stage.dart';
import '../models/user_record.dart';
import '../providers/task_provider.dart';
import '../providers/user_record_provider.dart';
import 'ai_chat_screen.dart';
import 'tasks_screen.dart';
import 'tree_screen.dart';

const _background = Color(0xFFFEFAF5);
const _ink = Color(0xFF2A312D);
const _mutedInk = Color(0xFF8B918A);
const _softGreen = Color(0xFFE8F7E8);
const _softGreenStrong = Color(0xFF82D39A);
const _softPink = Color(0xFFFFEDF1);
const _softPeach = Color(0xFFFFF1D8);
const _softBlue = Color(0xFFE8F1FF);
const _softYellow = Color(0xFFFFF6D8);
const _white = Color(0xFFFFFFFF);
const _deepBlue = Color(0xFF3C6EA8);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final userRecordProvider = context.watch<UserRecordProvider>();
    final tasks = taskProvider.tasks;
    final record = userRecordProvider.record;
    final todayTasks = _todayTasks(tasks);
    final completedTodayCount = todayTasks
        .where((task) => task.isCompleted)
        .length;
    final progress = todayTasks.isEmpty
        ? 0.0
        : completedTodayCount / todayTasks.length;
    final todayEnergy = _todayEnergy(tasks: tasks, record: record);
    final pendingTodayTasks = todayTasks
        .where((task) => !task.isCompleted)
        .toList(growable: false);
    final visibleTasks = pendingTodayTasks.take(3).toList(growable: false);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(record: record),
              const SizedBox(height: 20),
              const _BannerCard(),
              const SizedBox(height: 18),
              _BentoDataRow(
                completed: completedTodayCount,
                total: todayTasks.length,
                progress: progress,
                todayEnergy: todayEnergy,
                streakDays: record.consecutiveCheckInDays,
              ),
              const SizedBox(height: 18),
              _TaskSectionCard(
                tasks: visibleTasks,
                total: pendingTodayTasks.length,
              ),
              const SizedBox(height: 18),
              _SplitCards(record: record),
              const SizedBox(height: 18),
              const _BottomTip(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.record});

  final UserRecord record;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0BE),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD978).withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Text(
            '👧',
            key: ValueKey('home-girl-avatar'),
            style: TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingFor(now.hour),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(now),
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _softGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '✅ 连续签到 ${record.consecutiveCheckInDays} 天',
                  style: const TextStyle(
                    color: Color(0xFF4D9E67),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderIconButton(
          icon: Icons.timer_outlined,
          onTap: () => _showFocusStats(context, record),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: _ink, size: 22),
        ),
      ),
    );
  }
}

class _BannerCard extends StatefulWidget {
  const _BannerCard();

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  late final String quote;

  @override
  void initState() {
    super.initState();
    quote = _motivationQuotes[Random().nextInt(_motivationQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: _softGreen,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFE4F7E4), Color(0xFFF4FBEC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -0.15,
                child: const Text('🐱', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote,
                    key: const ValueKey('home-motivation-quote'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('💚', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoDataRow extends StatelessWidget {
  const _BentoDataRow({
    required this.completed,
    required this.total,
    required this.progress,
    required this.todayEnergy,
    required this.streakDays,
  });

  final int completed;
  final int total;
  final double progress;
  final int todayEnergy;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProgressBento(
            completed: completed,
            total: total,
            progress: progress,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _EnergyBento(todayEnergy: todayEnergy)),
        const SizedBox(width: 10),
        Expanded(child: _StreakBento(streakDays: streakDays)),
      ],
    );
  }
}

class _ProgressBento extends StatelessWidget {
  const _ProgressBento({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: _softGreen,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            '$completed/$total',
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '今日进度',
            style: TextStyle(
              color: _mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          _SoftProgressBar(progress: progress, color: _softGreenStrong),
        ],
      ),
    );
  }
}

class _EnergyBento extends StatelessWidget {
  const _EnergyBento({required this.todayEnergy});

  final int todayEnergy;

  @override
  Widget build(BuildContext context) {
    final filledBlocks = (todayEnergy / 10).clamp(0, 4).round();

    return _SoftCard(
      color: _softPink,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡️', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            '+$todayEnergy',
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '今日能量',
            style: TextStyle(
              color: _mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: index < filledBlocks
                          ? const Color(0xFFFFA6B8)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (index != 3) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakBento extends StatelessWidget {
  const _StreakBento({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: _softPeach,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📅', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          Text(
            '$streakDays 天',
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '连续签到',
            style: TextStyle(
              color: _mutedInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const Text('保持住呀', style: TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _TaskSectionCard extends StatelessWidget {
  const _TaskSectionCard({required this.tasks, required this.total});

  final List<Task> tasks;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: _white,
      padding: EdgeInsets.zero,
      onTap: () => _openTasks(context),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '今日待办',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  '全部 $total 项 >',
                  style: const TextStyle(
                    color: _mutedInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  '今天暂时没有待办，先舒展一下肩膀吧 🍵',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              )
            else
              for (var index = 0; index < tasks.length; index++) ...[
                _TaskTile(task: tasks[index]),
                if (index != tasks.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: _DottedLine(),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: task.isCompleted ? _softGreenStrong : _softGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 18,
            color: task.isCompleted ? Colors.white : _softGreenStrong,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: task.isCompleted ? _mutedInk : _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_isHighPriority(task)) ...[
                    const _TinyTag(label: '高优', color: Color(0xFFFFE0E6)),
                    const SizedBox(width: 8),
                  ],
                  _TinyTag(
                    label: _timeLabel(task),
                    color: const Color(0xFFF4F1EA),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SplitCards extends StatelessWidget {
  const _SplitCards({required this.record});

  final UserRecord record;

  @override
  Widget build(BuildContext context) {
    final treeProgress = record.treeGrowthStage.progressForEnergy(
      record.energy,
    );

    return SizedBox(
      height: 214,
      child: Row(
        children: [
          Expanded(
            child: _SoftCard(
              color: _softBlue,
              padding: const EdgeInsets.all(16),
              onTap: () => _openAiAssistant(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AI 助手建议',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Text('🤖', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '任务太大？让我帮你拆解~',
                    style: TextStyle(
                      color: _mutedInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _deepBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      '一键拆解任务 ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SoftCard(
              color: _softGreen,
              padding: const EdgeInsets.all(16),
              onTap: () => _openMyPage(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '小树状态 >',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${record.energy}/200',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SoftProgressBar(
                    progress: treeProgress,
                    color: _softGreenStrong,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTip extends StatelessWidget {
  const _BottomTip();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: _softYellow,
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 11),
      child: Row(
        children: const [
          Text('💡', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '小提示：25分钟专注+5分钟休息...',
              style: TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          Text('🐱', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.color,
    required this.padding,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftProgressBar extends StatelessWidget {
  const _SoftProgressBar({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: Colors.white.withValues(alpha: 0.78),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinePainter(),
      size: const Size(double.infinity, 1),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE3E1DA)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _openTasks(BuildContext context) {
  final controller = context.read<MainNavigationController?>();
  if (controller != null) {
    controller.openTasks();
    return;
  }

  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const TasksScreen()));
}

void _showFocusStats(BuildContext context, UserRecord record) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final totalSeconds = record.totalFocusSeconds;
      final completedPomodoros =
          totalSeconds ~/ const Duration(minutes: 25).inSeconds;

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFA),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _softGreenStrong.withValues(alpha: 0.16),
                  blurRadius: 28,
                  spreadRadius: 6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5ECE5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _softGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _softGreenStrong.withValues(alpha: 0.16),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Text('⏱️', style: TextStyle(fontSize: 38)),
                ),
                const SizedBox(height: 16),
                const Text(
                  '累计专注时长',
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _focusDurationLabel(totalSeconds),
                  key: const ValueKey('total-focus-duration'),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _focusClockLabel(totalSeconds),
                  style: const TextStyle(
                    color: _softGreenStrong,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _softYellow.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    completedPomodoros == 0
                        ? '🍅 完成第一个番茄钟后，专注时长会在这里慢慢长大。'
                        : '🍅 相当于完成了 $completedPomodoros 个完整番茄钟，继续保持这个节奏。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _softGreenStrong,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      '知道了',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _openAiAssistant(BuildContext context) {
  final controller = context.read<MainNavigationController?>();
  if (controller != null) {
    controller.openAiAssistant();
    return;
  }

  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AiChatScreen()));
}

void _openMyPage(BuildContext context) {
  final controller = context.read<MainNavigationController?>();
  if (controller != null) {
    controller.openMyPage();
    return;
  }

  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const TreeScreen()));
}

List<Task> _todayTasks(List<Task> tasks) {
  final now = DateTime.now();
  return tasks
      .where((task) {
        return task.isDueOn(now) ||
            _isSameDate(task.createdAt, now) ||
            _isSameDate(task.completedAt, now);
      })
      .toList(growable: false);
}

int _todayEnergy({required List<Task> tasks, required UserRecord record}) {
  final now = DateTime.now();
  final taskEnergy = tasks
      .where((task) => task.isCompleted && _isSameDate(task.completedAt, now))
      .fold<int>(0, (sum, task) => sum + task.energyReward);
  final checkInEnergy = record.hasCheckedInOn(now) ? 10 : 0;
  final allClearEnergy = record.hasClaimedAllClearRewardOn(now) ? 20 : 0;

  return taskEnergy + checkInEnergy + allClearEnergy;
}

String _greetingFor(int hour) {
  if (hour >= 5 && hour < 11) {
    return '早上好 ☀️';
  }
  if (hour >= 11 && hour < 14) {
    return '中午好 ☀️';
  }
  if (hour >= 14 && hour < 18) {
    return '下午好 🌤️';
  }
  if (hour >= 18 && hour < 23) {
    return '晚上好 🌙';
  }

  return '晚安 🌙';
}

String _dateLabel(DateTime date) {
  const weekdays = <int, String>{
    DateTime.monday: '星期一',
    DateTime.tuesday: '星期二',
    DateTime.wednesday: '星期三',
    DateTime.thursday: '星期四',
    DateTime.friday: '星期五',
    DateTime.saturday: '星期六',
    DateTime.sunday: '星期日',
  };

  return '${date.month}月${date.day}日 ${weekdays[date.weekday]}';
}

bool _isHighPriority(Task task) =>
    task.isHighPriority || task.priority == TaskPriority.high;

String _focusDurationLabel(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '$hours 小时 $minutes 分钟';
  }
  return '$minutes 分钟';
}

String _focusClockLabel(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String _timeLabel(Task task) {
  final deadline = task.deadline;
  if (deadline != null) {
    return '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
  }
  if (task.isCompleted) {
    return '已完成';
  }

  return '今天';
}

bool _isSameDate(DateTime? a, DateTime b) {
  return a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

const _motivationQuotes = <String>[
  '✨ 骗骗大脑：咱们今天就只干两分钟，两分钟后我绝不拦你。',
  '✨ 完美主义是拖延的帮凶，咱们今天只求“搞完”，不求“搞好”。',
  '✨ 只要在文档上敲下名字，就算是完成任务的 1% 了！',
  '✨ 觉得难？那就把它拆碎，碎到你不好意思不去做。',
  '👀 别看了，你的作业没长手，它不会自己写自己的。',
  '🧎 我知道你现在很想躺下，但再拖下去，明天就该跪下了。',
  '🧠 与其在脑子里疯狂内耗，不如在纸上随便发疯。',
  '🗑️ 承认吧，你就是想糊弄。那就理直气壮地先糊弄个开头吧！',
  '☕️ 累了就歇会儿，但歇完了记得回来把这个小怪兽打败哦。',
  '🫂 不想做也没关系，这是人类的正常出厂设置，深呼吸一下再试试？',
  '🌱 万事开头难，中间难，结尾也难。但只要开始了，就成功了一大半！',
  '🪴 小树饿得肚子咕咕叫了，随便动动手指，给它赚点口粮吧！',
  '🍃 把不想干的坏情绪扔进来，说不定能长出一片小叶子呢。',
  '🔋 能量条还空着呢，随便搞定一件小事，把它填满吧！',
];
