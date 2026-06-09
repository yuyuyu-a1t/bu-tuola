import 'package:class_buddy_lite/screens/main_screen.dart';
import 'package:class_buddy_lite/models/task.dart';
import 'package:class_buddy_lite/models/task_enums.dart';
import 'package:class_buddy_lite/models/task_step.dart';
import 'package:class_buddy_lite/models/user_record.dart';
import 'package:class_buddy_lite/providers/task_provider.dart';
import 'package:class_buddy_lite/providers/user_record_provider.dart';
import 'package:class_buddy_lite/screens/ai_chat_screen.dart';
import 'package:class_buddy_lite/screens/focus_screen.dart';
import 'package:class_buddy_lite/screens/home_screen.dart';
import 'package:class_buddy_lite/screens/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('main navigation switches pages', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider.memory()),
          ChangeNotifierProvider(
            create: (_) => UserRecordProvider.memory(
              UserRecord(createdAt: DateTime(2026, 6, 1)),
            ),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    expect(find.text('首页'), findsWidgets);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('小树'), findsNothing);

    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();

    expect(find.text('任务'), findsWidgets);
  });

  testWidgets('main navigation opens the AI assistant page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider.memory()),
          ChangeNotifierProvider(
            create: (_) => UserRecordProvider.memory(
              UserRecord(createdAt: DateTime(2026, 6, 1)),
            ),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.tap(find.text('AI助手'));
    await tester.pumpAndSettle();

    expect(find.text('🚑 拖延急救站'), findsOneWidget);
  });

  testWidgets('AI assistant page shows quick action pills', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider.memory()),
          ChangeNotifierProvider(
            create: (_) => UserRecordProvider.memory(
              UserRecord(createdAt: DateTime(2026, 6, 1)),
            ),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.tap(find.text('AI助手'));
    await tester.pumpAndSettle();

    expect(find.text('💊 救命我不想干活'), findsOneWidget);
    expect(find.text('📅 帮我安排今天'), findsOneWidget);
    expect(find.text('欢迎来到拖延急救站 👋'), findsOneWidget);
    expect(find.text('✨ 试试一键拆解'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('AI quick action replies locally before remote AI', (
    WidgetTester tester,
  ) async {
    var remoteCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AiChatScreen(
          remoteReply: (message) async {
            remoteCallCount++;
            return '先打开任务材料，写一个标题；做到这里就已经成功启动了。';
          },
        ),
      ),
    );

    await tester.tap(find.text('💊 救命我不想干活'));
    await tester.pump();

    expect(find.text('💊 救命我不想干活'), findsNWidgets(2));
    expect(find.textContaining('糊弄式启动也算赢'), findsOneWidget);
    expect(remoteCallCount, 0);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(remoteCallCount, 1);
    expect(find.textContaining('成功启动了'), findsOneWidget);
  });

  testWidgets('AI quick action responds on pointer down', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiChatScreen(
          remoteReply: (_) async => '先打开任务材料，写一个标题；做到这里就已经成功启动了。',
        ),
      ),
    );

    final quickAction = find.text('💊 救命我不想干活');
    final gesture = await tester.startGesture(tester.getCenter(quickAction));
    await tester.pump();

    expect(find.text('💊 救命我不想干活'), findsNWidgets(2));
    expect(find.textContaining('糊弄式启动也算赢'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  });

  testWidgets(
    'AI assistant keeps local advice when remote reply is malformed',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AiChatScreen(remoteReply: (_) async => '早起的鸟儿有虫吃resco'),
        ),
      );

      await tester.tap(find.text('📅 帮我安排今天'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.textContaining('今天先排 3 件'), findsOneWidget);
      expect(find.textContaining('resco'), findsNothing);
    },
  );

  testWidgets('home screen renders soft pastel dashboard and opens tasks', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final tasks = [
      Task(
        id: 'home-focus-task',
        title: '先写实验报告标题',
        priority: TaskPriority.high,
        createdAt: now,
      ),
      Task(
        id: 'home-done-task',
        title: '背 5 个单词',
        priority: TaskPriority.medium,
        isCompleted: true,
        createdAt: now,
        completedAt: now,
      ),
      Task(
        id: 'home-second-task',
        title: '整理数据库报告',
        priority: TaskPriority.medium,
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider.memory(tasks)),
          ChangeNotifierProvider(
            create: (_) => UserRecordProvider.memory(
              UserRecord(
                energy: 120,
                consecutiveCheckInDays: 5,
                lastCheckInDate: now,
                totalFocusSeconds: 3900,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.byKey(const ValueKey('home-girl-avatar')), findsOneWidget);

    expect(find.text('✅ 连续签到 5 天'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-motivation-quote')), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('5 天'), findsOneWidget);
    expect(find.text('今日待办'), findsOneWidget);
    expect(find.text('全部 2 项 >'), findsOneWidget);
    expect(find.text('先写实验报告标题'), findsOneWidget);
    expect(find.text('背 5 个单词'), findsNothing);
    expect(find.text('中优'), findsNothing);
    expect(find.text('高优'), findsOneWidget);
    expect(find.text('小提示：25分钟专注+5分钟休息...'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();

    expect(find.text('累计专注时长'), findsOneWidget);
    expect(find.text('1 小时 5 分钟'), findsOneWidget);
    expect(find.text('01:05:00'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日待办'));
    await tester.pumpAndSettle();

    expect(find.text('🎯 待办消灭计划'), findsOneWidget);
  });

  testWidgets('home split cards navigate to AI assistant and tree screens', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider.memory()),
          ChangeNotifierProvider(
            create: (_) => UserRecordProvider.memory(
              UserRecord(
                energy: 120,
                consecutiveCheckInDays: 5,
                lastCheckInDate: now,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.ensureVisible(find.text('AI 助手建议'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 助手建议'));
    await tester.pumpAndSettle();

    expect(find.text('🚑 拖延急救站'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ai-back-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('小树状态 >'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('小树状态 >'));
    await tester.pumpAndSettle();

    expect(find.text('✨ 摆烂回收站'), findsOneWidget);
  });

  testWidgets('tree task shortcut opens the task page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider.memory()),
          ChangeNotifierProvider(
            create: (_) => UserRecordProvider.memory(
              UserRecord(createdAt: DateTime(2026, 6, 1)),
            ),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('✨ 摆烂回收站'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-page-girl')), findsOneWidget);

    await tester.ensureVisible(find.text('去干掉今天的任务 🚀'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('去干掉今天的任务 🚀'));
    await tester.pumpAndSettle();

    expect(find.text('🎯 待办消灭计划'), findsOneWidget);
  });

  testWidgets('task header shows live total pending and completed statistics', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tasks = [
      Task(id: 'today-pending', title: '今天创建', createdAt: now),
      Task(
        id: 'today-completed',
        title: '今天完成',
        isCompleted: true,
        createdAt: yesterday,
        completedAt: now,
      ),
      Task(id: 'old-pending', title: '旧任务', createdAt: yesterday),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskProvider.memory(tasks),
        child: const MaterialApp(home: TasksScreen()),
      ),
    );

    expect(find.text('总待办 2 项 · 已完成 1 项 · 🤖 AI 可帮你拆解大任务'), findsOneWidget);
  });

  testWidgets('completing the final AI subtask completes its parent task', (
    WidgetTester tester,
  ) async {
    final provider = TaskProvider.memory([
      Task(
        id: 'ai-task',
        title: '完成实验报告',
        useAiAutoSplit: true,
        subTasks: const [
          TaskStep(id: 'step-1', title: '第一步', isCompleted: true),
          TaskStep(id: 'step-2', title: '第二步', isCompleted: true),
          TaskStep(id: 'step-3', title: '第三步'),
        ],
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TasksScreen()),
      ),
    );

    await tester.tap(find.text('第三步'));
    await tester.pumpAndSettle();

    expect(provider.tasks.single.isCompleted, isTrue);
    expect(provider.tasks.single.completedAt, isNotNull);
  });

  testWidgets(
    'pending task opens focus screen and completed task hides actions',
    (WidgetTester tester) async {
      final tasks = [
        Task(id: 'pending-focus', title: '准备英语演讲'),
        Task(id: 'completed-focus', title: '已经完成的任务', isCompleted: true),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => TaskProvider.memory(tasks),
          child: const MaterialApp(home: TasksScreen()),
        ),
      );

      expect(find.text('🍅 专注 25min'), findsOneWidget);
      expect(find.text('🤖 让真实 AI 拆解'), findsOneWidget);

      await tester.tap(find.text('🍅 专注 25min'));
      await tester.pumpAndSettle();

      expect(find.text('这一刻，只做眼前这一件事'), findsOneWidget);
      expect(find.text('准备英语演讲'), findsOneWidget);
    },
  );

  testWidgets('focus timer completes task and rewards tree energy', (
    WidgetTester tester,
  ) async {
    final task = Task(id: 'focus-reward', title: '专注完成这件事');
    final taskProvider = TaskProvider.memory([task]);
    final userRecordProvider = UserRecordProvider.memory();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: taskProvider),
          ChangeNotifierProvider.value(value: userRecordProvider),
        ],
        child: MaterialApp(
          home: FocusScreen(
            task: task,
            initialDuration: const Duration(seconds: 1),
          ),
        ),
      ),
    );

    expect(find.text('00:01'), findsOneWidget);
    await tester.tap(find.text('🚀 开始专注'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 600));

    expect(taskProvider.tasks.single.isCompleted, isTrue);
    expect(userRecordProvider.record.energy, 50);
    expect(userRecordProvider.record.totalFocusSeconds, 1);
    expect(find.text('🏆 专注完成！'), findsOneWidget);
    expect(find.text('满载而归'), findsOneWidget);
  });

  testWidgets('home task card keeps the main bottom navigation visible', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TaskProvider.memory([
              Task(id: 'home-task', title: '首页任务', createdAt: now),
            ]),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                UserRecordProvider.memory(UserRecord(createdAt: now)),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.ensureVisible(find.text('今日待办'));
    await tester.tap(find.text('今日待办'));
    await tester.pumpAndSettle();

    expect(find.text('🎯 待办消灭计划'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('AI助手'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('creates a task from the bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskProvider.memory(),
        child: const MaterialApp(home: TasksScreen()),
      ),
    );

    expect(find.text('空空如也，今天也是没有作业的一天吗？'), findsOneWidget);

    await tester.tap(find.text('新建'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '先写实验报告标题');
    await tester.tap(find.text('确认创建'));
    await tester.pumpAndSettle();

    expect(find.text('先写实验报告标题'), findsOneWidget);
    expect(find.text('🤖 让真实 AI 拆解'), findsOneWidget);
  });
}
