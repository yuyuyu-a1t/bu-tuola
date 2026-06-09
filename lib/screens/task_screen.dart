import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/task_step.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import 'focus_screen.dart';

const _background = Color(0xFFFEFAF5);
const _ink = Color(0xFF2B312D);
const _mutedInk = Color(0xFF8A9189);
const _white = Color(0xFFFFFFFF);
const _softGreen = Color(0xFFE8F7E8);
const _softGreenStrong = Color(0xFF6DD58D);
const _softYellow = Color(0xFFFFF4D9);
const _softOrange = Color(0xFFFFE8CC);
const _softPink = Color(0xFFFFEDF1);
const _softBlue = Color(0xFFEAF3FF);
const _softPurple = Color(0xFFF1ECFF);

final _taskIdRandom = Random();

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TasksScreen();
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;
    final visibleTasks = _filteredTasks(tasks, _filter);
    final pendingCount = tasks.where((task) => !task.isCompleted).length;
    final completedCount = tasks.where((task) => task.isCompleted).length;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(pending: pendingCount, completed: completedCount),
                  const SizedBox(height: 18),
                  _FilterChips(
                    selected: _filter,
                    onSelected: (filter) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (visibleTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 120),
                      child: _EmptyTaskState(),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: visibleTasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _TaskCard(task: visibleTasks[index]);
                      },
                    ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 180,
              bottom: 24,
              child: const _BottomTip(),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _SoftNewTaskButton(
        onTap: () => _showAddTaskBottomSheet(context),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pending, required this.completed});

  final int pending;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text(
                '🎯 待办消灭计划',
                style: TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text('📋 🐱', style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            children: [
              const TextSpan(text: '总待办 '),
              TextSpan(
                text: '$pending',
                style: const TextStyle(
                  color: Color(0xFF58B978),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TextSpan(text: ' 项 · 已完成 '),
              TextSpan(
                text: '$completed',
                style: const TextStyle(
                  color: Color(0xFFF0A45D),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TextSpan(text: ' 项 · 🤖 AI 可帮你拆解大任务'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final _TaskFilter selected;
  final ValueChanged<_TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _TaskFilter.values) ...[
            _FilterChip(
              filter: filter,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            if (filter != _TaskFilter.values.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _TaskFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = filter == _TaskFilter.highPriority
        ? _softOrange
        : _softGreen;
    final selectedTextColor = filter == _TaskFilter.highPriority
        ? const Color(0xFFE7903F)
        : const Color(0xFF4B9F64);

    return Material(
      color: selected ? selectedColor : _white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            filter.label,
            style: TextStyle(
              color: selected ? selectedTextColor : _mutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72, horizontal: 20),
      child: Column(
        children: [
          Text('🍃', style: TextStyle(fontSize: 72)),
          SizedBox(height: 14),
          Text(
            '空空如也，今天也是没有作业的一天吗？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedInk,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isBreakingDown = false;

  Future<void> _breakDownTask() async {
    if (_isBreakingDown) {
      return;
    }

    setState(() {
      _isBreakingDown = true;
    });

    try {
      final steps = await AIService.instance.breakDownTask(widget.task.title);
      if (!mounted) {
        return;
      }
      await _saveBreakdownSteps(steps);
      if (mounted) {
        _showTaskSnackBar(context, '真实 AI 已完成拆解。');
      }
    } catch (error) {
      debugPrint('AI breakdown failed: $error');
      if (!mounted) {
        return;
      }
      final fallbackSteps = AIService.instance.fallbackBreakDownTask(
        widget.task.title,
      );
      await _saveBreakdownSteps(fallbackSteps);
      if (mounted) {
        _showTaskSnackBar(context, '真实 AI 暂时没响应，已使用本地应急拆解。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBreakingDown = false;
        });
      }
    }
  }

  Future<void> _saveBreakdownSteps(List<String> steps) async {
    final currentTask = _latestTask();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final taskSteps = steps
        .take(3)
        .toList(growable: false)
        .asMap()
        .entries
        .map((entry) {
          return TaskStep(
            id: '${currentTask.id}-ai-$timestamp-${entry.key}',
            title: entry.value,
            order: entry.key + 1,
            encouragement: '先完成这一小口。',
          );
        })
        .toList(growable: false);

    await context.read<TaskProvider>().updateTask(
      currentTask.copyWith(subTasks: taskSteps, useAiAutoSplit: true),
    );
  }

  Task _latestTask() {
    final tasks = context.read<TaskProvider>().tasks;
    for (final task in tasks) {
      if (task.id == widget.task.id) {
        return task;
      }
    }

    return widget.task;
  }

  void _toggleTask() {
    final currentTask = _latestTask();
    _runInBackground(
      context.read<TaskProvider>().toggleTaskCompletion(currentTask),
      'Toggle task',
    );
  }

  void _toggleSubtask(TaskStep step) {
    final currentTask = _latestTask();
    final nextSteps = currentTask.subTasks
        .map((item) {
          if (item.id != step.id) {
            return item;
          }
          return item.copyWith(isCompleted: !item.isCompleted);
        })
        .toList(growable: false);
    var nextTask = currentTask.copyWith(subTasks: nextSteps);
    final allSubtasksCompleted =
        nextSteps.isNotEmpty && nextSteps.every((item) => item.isCompleted);
    if (allSubtasksCompleted && !currentTask.isCompleted) {
      nextTask = nextTask.markCompleted();
    }

    _runInBackground(
      context.read<TaskProvider>().updateTask(nextTask),
      'Toggle subtask',
    );
  }

  void _togglePriority() {
    final currentTask = _latestTask();
    _runInBackground(
      context.read<TaskProvider>().updateTask(
        currentTask.copyWith(isHighPriority: !currentTask.isHighPriority),
      ),
      'Toggle high priority',
    );
  }

  void _deleteTask() {
    _runInBackground(
      context.read<TaskProvider>().deleteTask(widget.task.id),
      'Delete task',
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final progress = _SubtaskProgress.fromTask(task);
    final hasSubtasks = task.subTasks.isNotEmpty;

    return _SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundCheckbox(isCompleted: task.isCompleted, onTap: _toggleTask),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: task.isCompleted
                                    ? _mutedInk
                                    : const Color(0xFF333333),
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: Colors.grey.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                          ),
                          if (task.isHighPriority) ...[
                            const SizedBox(width: 5),
                            const Text('⭐', style: TextStyle(fontSize: 15)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _TypeTag(type: task.type),
                    PopupMenuButton<_TaskMenuAction>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: _mutedInk,
                      ),
                      color: _white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _TaskMenuAction.delete:
                            _deleteTask();
                          case _TaskMenuAction.togglePriority:
                            _togglePriority();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _TaskMenuAction.togglePriority,
                          child: Text(
                            task.isHighPriority ? '取消高优先级' : '设为高优先级',
                          ),
                        ),
                        const PopupMenuItem(
                          value: _TaskMenuAction.delete,
                          child: Text('删除'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!task.isCompleted) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _AiBreakdownButton(
                          isLoading: _isBreakingDown,
                          onPressed: _isBreakingDown ? null : _breakDownTask,
                        ),
                        _FocusButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    FocusScreen(task: _latestTask()),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _ProgressLine(progress: progress),
                if (hasSubtasks) ...[
                  const SizedBox(height: 14),
                  const _DottedLine(),
                  const SizedBox(height: 12),
                  _SubtaskList(steps: task.subTasks, onToggle: _toggleSubtask),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(top: 76),
            child: Text('🌿', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }
}

class _RoundCheckbox extends StatelessWidget {
  const _RoundCheckbox({required this.isCompleted, required this.onTap});

  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCompleted ? _softGreenStrong : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? _softGreenStrong : const Color(0xFFB8C8BA),
                width: 1.5,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.type});

  final TaskType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: type.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.softLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

class _AiBreakdownButton extends StatelessWidget {
  const _AiBreakdownButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _mutedInk,
          side: const BorderSide(color: Color(0xFFE5E9E3)),
          backgroundColor: Colors.white.withValues(alpha: 0.68),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        child: Text(isLoading ? '🤖 真实 AI 拆解中...' : '🤖 让真实 AI 拆解'),
      ),
    );
  }
}

class _FocusButton extends StatelessWidget {
  const _FocusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0E6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withValues(alpha: 0.06),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            '🍅 专注 25min',
            style: TextStyle(
              color: Color(0xFFE97843),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final _SubtaskProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '进度 ${progress.completed}/${progress.total}',
          style: const TextStyle(
            color: _mutedInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 6,
            color: const Color(0xFFF0F8F1),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.ratio,
              child: Container(color: const Color(0xFF80D69A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubtaskList extends StatelessWidget {
  const _SubtaskList({required this.steps, required this.onToggle});

  final List<TaskStep> steps;
  final ValueChanged<TaskStep> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _softGreen.withValues(alpha: 0.62),
            Colors.white.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _SubtaskRow(step: steps[index], onToggle: onToggle),
            if (index != steps.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.step, required this.onToggle});

  final TaskStep step;
  final ValueChanged<TaskStep> onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(step),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              step.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: _softGreenStrong,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  color: step.isCompleted ? const Color(0xFFA9B2AA) : _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  decoration: step.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.green.withValues(alpha: 0.18),
                  decorationThickness: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('🌱', style: TextStyle(fontSize: 16)),
          ],
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
      ..color = Colors.green.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
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

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.035),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SoftNewTaskButton extends StatelessWidget {
  const _SoftNewTaskButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _softGreenStrong,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: _softGreenStrong.withValues(alpha: 0.28),
                blurRadius: 18,
                spreadRadius: 3,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('➕', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text(
                '新建',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTip extends StatelessWidget {
  const _BottomTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
      decoration: BoxDecoration(
        color: _softYellow.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.09),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💡', style: TextStyle(fontSize: 16)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              '先完成最小的一步，状态就会慢慢回来～',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 5),
          Text('🐱', style: TextStyle(fontSize: 17)),
        ],
      ),
    );
  }
}

void _showAddTaskBottomSheet(BuildContext context) {
  final taskProvider = context.read<TaskProvider>();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: _AddTaskBottomSheet(
          onCreate: (title, type, isHighPriority, useAiAutoSplit) async {
            final now = DateTime.now();
            final task = Task(
              id: _generateTaskUuid(),
              title: title,
              type: type,
              priority: isHighPriority
                  ? TaskPriority.high
                  : TaskPriority.medium,
              isHighPriority: isHighPriority,
              useAiAutoSplit: useAiAutoSplit,
              createdAt: now,
              updatedAt: now,
            );

            _runInBackground(taskProvider.addTask(task), 'Save manual task');
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
        ),
      );
    },
  );
}

class _AddTaskBottomSheet extends StatefulWidget {
  const _AddTaskBottomSheet({required this.onCreate});

  final Future<void> Function(
    String title,
    TaskType type,
    bool isHighPriority,
    bool useAiAutoSplit,
  )
  onCreate;

  @override
  State<_AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<_AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  TaskType _selectedType = TaskType.assignment;
  bool _isHighPriority = false;
  bool _useAiAutoSplit = true;
  bool _showTitleError = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _showTitleError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _showTitleError = false;
    });

    try {
      await widget.onCreate(
        title,
        _selectedType,
        _isHighPriority,
        _useAiAutoSplit,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E7DF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '新建一个小任务',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_showTitleError) {
                    setState(() {
                      _showTitleError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '比如：先写实验报告标题',
                  filled: true,
                  fillColor: const Color(0xFFFAFBF7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _showTitleError ? '先写点什么吧。' : null,
                ),
              ),
              const SizedBox(height: 16),
              _TaskTypeChoiceRow(
                selectedType: _selectedType,
                onSelected: (type) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                value: _isHighPriority,
                onChanged: (value) {
                  setState(() {
                    _isHighPriority = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '⭐ 高优先级',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SwitchListTile(
                value: _useAiAutoSplit,
                onChanged: (value) {
                  setState(() {
                    _useAiAutoSplit = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '🤖 使用 AI 自动拆解子任务',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _softGreenStrong,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(_isSaving ? '正在创建...' : '确认创建'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTypeChoiceRow extends StatelessWidget {
  const _TaskTypeChoiceRow({
    required this.selectedType,
    required this.onSelected,
  });

  final TaskType selectedType;
  final ValueChanged<TaskType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final type in TaskType.values) ...[
            ChoiceChip(
              label: Text(type.softLabel),
              selected: selectedType == type,
              showCheckmark: false,
              selectedColor: type.softColor,
              backgroundColor: const Color(0xFFF6F6F1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              onSelected: (_) => onSelected(type),
            ),
            if (type != TaskType.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

void _runInBackground(Future<void> future, String label) {
  unawaited(
    future.catchError((Object error, StackTrace stackTrace) {
      debugPrint('$label failed: $error');
    }),
  );
}

void _showTaskSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: _ink,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

List<Task> _filteredTasks(List<Task> tasks, _TaskFilter filter) {
  return switch (filter) {
    _TaskFilter.all => tasks,
    _TaskFilter.inProgress =>
      tasks.where((task) => !task.isCompleted).toList(growable: false),
    _TaskFilter.completed =>
      tasks.where((task) => task.isCompleted).toList(growable: false),
    _TaskFilter.highPriority =>
      tasks.where((task) => task.isHighPriority).toList(growable: false),
  };
}

String _generateTaskUuid() {
  final bytes = List<int>.generate(16, (_) => _taskIdRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

enum _TaskFilter { all, inProgress, completed, highPriority }

extension _TaskFilterInfo on _TaskFilter {
  String get label {
    return switch (this) {
      _TaskFilter.all => '🎛️ 全部',
      _TaskFilter.inProgress => '🕒 进行中',
      _TaskFilter.completed => '✅ 已完成',
      _TaskFilter.highPriority => '⭐ 高优优先级',
    };
  }
}

enum _TaskMenuAction { delete, togglePriority }

class _SubtaskProgress {
  const _SubtaskProgress({required this.completed, required this.total});

  factory _SubtaskProgress.fromTask(Task task) {
    final total = task.subTasks.length;
    final completed = task.subTasks.where((step) => step.isCompleted).length;
    return _SubtaskProgress(completed: completed, total: total);
  }

  final int completed;
  final int total;

  double get ratio {
    if (total == 0) {
      return 0;
    }

    return (completed / total).clamp(0, 1).toDouble();
  }
}

extension _TaskTypeStyle on TaskType {
  String get softLabel {
    return switch (this) {
      TaskType.assignment => '✏️ 学习',
      TaskType.review => '📚 复习',
      TaskType.exam => '🧠 考试',
      TaskType.project => '🧩 项目',
      TaskType.life => '🌿 日常',
      TaskType.other => '💡 灵感',
    };
  }

  Color get softColor {
    return switch (this) {
      TaskType.assignment => _softYellow,
      TaskType.review => _softBlue,
      TaskType.exam => _softPink,
      TaskType.project => _softPurple,
      TaskType.life => _softGreen,
      TaskType.other => const Color(0xFFF3F2ED),
    };
  }
}
