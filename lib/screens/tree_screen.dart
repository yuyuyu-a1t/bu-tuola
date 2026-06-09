import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/main_navigation_controller.dart';
import '../models/tree_growth_stage.dart';
import '../providers/task_provider.dart';
import '../providers/user_record_provider.dart';
import 'tasks_screen.dart';

const _background = Color(0xFFFFFCF7);
const _ink = Color(0xFF233D34);
const _mutedInk = Color(0xFF748079);
const _green = Color(0xFF58BE85);
const _deepGreen = Color(0xFF16844F);
const _softGreen = Color(0xFFEAF8EF);
const _softYellow = Color(0xFFFFF8E7);
const _paper = Color(0xFFFFFFFF);
const _girlAsset = 'assets/images/my_girl.png';
const _terrariumAsset = 'assets/images/tree_terrarium.png';

class TreeScreen extends StatelessWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserRecordProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final record = userProvider.record;
    final pendingTasks = taskProvider.tasks
        .where((task) => !task.isCompleted)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 128),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PageHeader(),
              const SizedBox(height: 6),
              _ProfileOverviewCard(
                registeredDays: record.registeredDaysOn(DateTime.now()),
                energy: record.energy,
                streakDays: record.consecutiveCheckInDays,
                nudge: userProvider.headerNudge,
              ),
              const SizedBox(height: 10),
              _CheckInBanner(
                isCheckedIn: userProvider.hasCheckedInToday,
                onTap: userProvider.hasCheckedInToday
                    ? null
                    : () => userProvider.checkIn(),
              ),
              const SizedBox(height: 10),
              _GrowthCard(
                stage: userProvider.currentStage,
                encouragement: userProvider.treeEncouragement,
                progress: userProvider.treeProgress,
                progressText: userProvider.treeProgressText,
              ),
              const SizedBox(height: 14),
              const _SectionTitle(),
              const SizedBox(height: 9),
              _GoalRow(
                icon: '📝',
                title: pendingTasks.isEmpty
                    ? '先写一个标题，也算把任务拽进现实。'
                    : pendingTasks.first.title,
                subtitle: pendingTasks.isEmpty ? '完成可获得 +5 能量' : '先完成最小的一步',
                onTap: () => _openTasks(context),
              ),
              const SizedBox(height: 8),
              _GoalRow(
                icon: '📋',
                title: '去干掉今天的任务 🚀',
                onTap: () => _openTasks(context),
              ),
              const SizedBox(height: 12),
              _QuoteCard(quote: userProvider.dailyAntiProcrastinationQuote),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.only(left: 2, right: 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '✨ 摆烂回收站',
                maxLines: 1,
                style: TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '把拖延交给过去，把行动留给现在 🌱',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.68),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({
    required this.registeredDays,
    required this.energy,
    required this.streakDays,
    required this.nudge,
  });

  final int registeredDays;
  final int energy;
  final int streakDays;
  final String nudge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SoftCard(
          color: const Color(0xFFF5FBF6),
          borderColor: const Color(0xFFCDEAD8),
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final leftWidth = constraints.maxWidth < 360
                    ? constraints.maxWidth - 124
                    : 226.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 16,
                      top: 17,
                      bottom: 15,
                      width: leftWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '拖延症抗体 · 第 $registeredDays 天',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _deepGreen,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nudge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _mutedInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  icon: '⚡',
                                  value: energy.toString(),
                                  label: '总能量',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatTile(
                                  icon: '🔥',
                                  value: '$streakDays 天',
                                  label: '连续签',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -10,
                      bottom: -10,
                      width: 200,
                      height: 200,
                      child: Image.asset(
                        _terrariumAsset,
                        key: const ValueKey('my-page-tree-terrarium'),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        errorBuilder: (_, _, _) {
                          return const Align(
                            alignment: Alignment.bottomRight,
                            child: Text('🌳', style: TextStyle(fontSize: 92)),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -106,
          right: 4,
          width: 124,
          height: 120,
          child: IgnorePointer(
            child: Semantics(
              label: '趴在成长卡片上打招呼的卡通少女',
              image: true,
              child: Image.asset(
                _girlAsset,
                key: const ValueKey('my-page-girl'),
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, _, _) {
                  return const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text('👩‍🏫💚', style: TextStyle(fontSize: 54)),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _deepGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _mutedInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInBanner extends StatelessWidget {
  const _CheckInBanner({required this.isCheckedIn, required this.onTap});

  final bool isCheckedIn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF5BC68B), Color(0xFF8AD6A9)],
            ),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🗓️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCheckedIn ? '今日已签到 ✅' : '点击签到，领取今日能量',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCheckedIn ? '明日再来领能量 ›' : '+10 能量 ›',
                  style: const TextStyle(
                    color: _deepGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.stage,
    required this.encouragement,
    required this.progress,
    required this.progressText,
  });

  final TreeGrowthStage stage;
  final String encouragement;
  final double progress;
  final String progressText;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: _softYellow,
      borderColor: const Color(0xFFF5DFA3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '小树成长中 🌱',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7C9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LV.${stage.index + 1} ${stage.displayName}',
                  style: const TextStyle(
                    color: Color(0xFF70A33D),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stage.moodText,
            style: const TextStyle(
              color: _mutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5D7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(stage.emoji, style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      encouragement,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _ProgressBar(progress: progress),
                    const SizedBox(height: 5),
                    Text(
                      progressText,
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _softGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '💡 只要每天进步一点点，小树就会越来越茂盛！',
                        style: TextStyle(
                          color: _deepGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 9,
        color: const Color(0xFFE9ECE7),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: _green),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '🎯 今日小目标',
      style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _softGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(icon, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _ink,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: const Color(0xFFF0FAF5),
      borderColor: const Color(0xFFCBEAD8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          const Text('💗', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('💌', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.color,
    required this.borderColor,
    required this.padding,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
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
