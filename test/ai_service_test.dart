import 'package:class_buddy_lite/models/task_enums.dart';
import 'package:class_buddy_lite/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps SiliconFlow configuration explicit', () {
    expect(AIService.apiUrl, 'https://api.siliconflow.cn/v1/chat/completions');
    expect(AIService.modelName, 'Qwen/Qwen2.5-7B-Instruct');
    expect(AIService.apiKey, isEmpty);
    expect(AIService.chatSystemPrompt, contains('只使用自然、清晰的简体中文回答'));
    expect(AIService.breakdownSystemPrompt, contains('理解用户输入的中文或英文任务'));
    expect(AIService.breakdownSystemPrompt, contains('禁止虚构'));
  });

  test('maps AI category text to task type', () {
    expect(taskTypeFromAiCategory('学习'), TaskType.assignment);
    expect(taskTypeFromAiCategory('运动'), TaskType.life);
    expect(taskTypeFromAiCategory('项目报告'), TaskType.project);
  });

  test('provides local fallback task breakdown', () {
    final steps = AIService.instance.fallbackBreakDownTask('写实验报告');

    expect(steps, hasLength(3));
    expect(steps.first, contains('写实验报告'));
  });

  test('parses near-JSON AI breakdown with a missing comma', () {
    final steps = AIService.instance.decodeBreakdownSteps(
      '["从现有材料中选一段短英语句子","听读一遍并记下3个生词"'
      '"用其中1个生词写一句话"',
    );

    expect(steps, ['从现有材料中选一段短英语句子', '听读一遍并记下3个生词', '用其中1个生词写一句话']);
  });

  test('creates a local fallback task from speech', () {
    final task = AIService.instance.fallbackTaskFromSpeech('明天把数据库报告先开个头');

    expect(task.title, '把数据库报告先开个头');
    expect(task.type, TaskType.project);
    expect(task.useAiAutoSplit, isTrue);
  });

  test('keeps AI service exception printable', () {
    expect(const AIServiceException('网络失败').toString(), '网络失败');
  });

  test('rejects malformed or empty AI chat replies', () {
    expect(isUsefulAiChatReply('帮我安排今天', '早起的鸟儿有虫吃resco'), isFalse);
    expect(isUsefulAiChatReply('把大任务拆小', '好呀～一起分解吧😉'), isFalse);
    expect(isUsefulAiChatReply('救命我不想干活', '先伸个懒腰，然后定个3分钟小计划。🎉'), isFalse);
    expect(
      isUsefulAiChatReply('把大任务拆小', '把具体任务名发给我，我会帮你拆成三个能马上开始的小步骤。'),
      isTrue,
    );
  });
}
