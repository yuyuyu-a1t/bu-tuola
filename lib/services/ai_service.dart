import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/task.dart';
import '../models/task_enums.dart';

class AIService {
  AIService._();

  static final AIService instance = AIService._();

  static const String apiUrl = 'https://api.siliconflow.cn/v1/chat/completions';
  static const String modelName = 'Qwen/Qwen2.5-7B-Instruct';
  static const String chatSystemPrompt =
      "你是名叫“课伴”的大学生拖延急救助手。只使用自然、清晰的简体中文回答，"
      "除非用户明确要求翻译，否则不要混入英文单词或奇怪字符。"
      "语气温暖、轻松，可以使用一个合适的 Emoji，但不要说空泛鸡汤或只回复客套话。"
      "每次回答 25 到 70 个汉字，并且必须给出能马上执行的帮助。"
      "用户说“救命我不想干活”时，给出一个 3 分钟内可以开始的具体动作，"
      "例如打开任务并写下标题，不要只建议制定计划或休息。"
      "用户说“帮我安排今天”时，请用户发来任务清单，并告诉他如何先挑最急和最小的任务。"
      "用户说“把大任务拆小”但没有提供任务名时，明确请他发来具体任务，不要假装已经拆解。";
  static const String breakdownSystemPrompt =
      '你是面向大学生的任务拆解专家。理解用户输入的中文或英文任务，但必须使用简体中文输出。'
      '将任务拆成 3 个今天就能开始、每步约 2 到 15 分钟的具体动作。'
      '如果任务很宽泛，例如 study english 或 memorize words，不要制定长期学习计划，'
      '而是先选定一个很小的练习范围，再完成一次短练习，最后记录结果。'
      '禁止虚构用户正在使用的 App、网站、账号、课程或材料；'
      '禁止擅自指定用户没有提供的单词、文章、软件名称或学习资源。'
      '禁止出现不合理的数量或时长；禁止使用“制定计划”“坚持学习”等空泛表述。'
      '每一步只包含一个动作，表达自然简短。'
      '宽泛任务的合理示例：'
      'study english 可拆为 ["从现有材料中选一段短英语内容","听读一遍并记下3个生词","用其中1个生词写一句话"]；'
      'memorize words 可拆为 ["从现有材料中圈出5个单词","逐个朗读并写下中文意思","遮住释义自测并标记没记住的词"]。'
      '严格只返回 JSON 字符串数组，例如：["步骤一","步骤二","步骤三"]，不要返回其他内容。';
  static const String debugAndroidProxy = String.fromEnvironment(
    'SILICONFLOW_DEBUG_PROXY',
    defaultValue: '127.0.0.1:7890',
  );
  static const String apiKey = String.fromEnvironment('SILICONFLOW_API_KEY');
  static const Duration requestTimeout = Duration(seconds: 12);

  final Random _random = Random();

  Future<String> chatWithAI(String message) async {
    final content = await _postRequest(
      systemPrompt: chatSystemPrompt,
      userPrompt: message,
      temperature: 0.45,
      maxTokens: 100,
    );

    final reply = content.trim();
    if (!isUsefulAiChatReply(message, reply)) {
      throw const AIServiceException('AI 返回的聊天内容质量不合格');
    }

    return reply;
  }

  Future<List<String>> breakDownTask(String taskName) async {
    final content = await _postRequest(
      systemPrompt: breakdownSystemPrompt,
      userPrompt: _buildBreakdownUserPrompt(taskName),
      temperature: 0.3,
      maxTokens: 180,
    );

    final steps = decodeBreakdownSteps(content);

    if (steps.length != 3) {
      throw const AIServiceException('AI 返回的任务拆解格式不完整');
    }
    if (steps.any(_isLowQualityBreakdownStep)) {
      throw const AIServiceException('AI 返回的任务拆解不够具体或不合理');
    }

    return steps;
  }

  List<String> fallbackBreakDownTask(String taskName) {
    final cleanTaskName = taskName.trim().isEmpty ? '这个任务' : taskName.trim();
    return <String>[
      '先打开和“$cleanTaskName”有关的材料，不要求马上做完。',
      '只完成最小的一步，比如写标题、列清单或看 3 分钟。',
      '保存当前进度，给自己一个“已经启动了”的信号。',
    ];
  }

  Future<Task?> parseTaskFromSpeech(String speech) async {
    final content = await _postRequest(
      systemPrompt:
          '你是一个NLP解析器。用户会输入一句随意的牢骚或计划，请从中提取出\'任务核心动作\'作为标题，并推测一个类别（比如 学习, 运动, 日常）。请严格返回 JSON 格式：{"title": "提取的任务名", "category": "提取的类别"}。不要有其他多余字符。',
      userPrompt: speech,
      temperature: 0.2,
      maxTokens: 120,
    );

    final parsedJson = _decodeJsonObject(content);
    final title = parsedJson['title']?.toString().trim() ?? '';
    final category = parsedJson['category']?.toString().trim() ?? '';

    if (title.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    return Task(
      id: _generateUuid(),
      title: title,
      type: taskTypeFromAiCategory(category),
      priority: TaskPriority.medium,
      useAiAutoSplit: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Task fallbackTaskFromSpeech(String speech) {
    final now = DateTime.now();
    final cleanSpeech = speech.trim();
    return Task(
      id: _generateUuid(),
      title: _fallbackTaskTitleFromSpeech(cleanSpeech),
      type: taskTypeFromAiCategory(cleanSpeech),
      priority: TaskPriority.medium,
      useAiAutoSplit: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<String> _postRequest({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 256,
  }) async {
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) {
      throw const AIServiceException('请输入内容后再请求 AI');
    }
    if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.trim().isEmpty) {
      throw const AIServiceException(
        '请通过 --dart-define=SILICONFLOW_API_KEY=你的_Key 配置 AI 服务',
      );
    }

    final requestBody = <String, Object>{
      'model': modelName,
      'messages': <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': cleanPrompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': false,
      'enable_thinking': false,
    };

    late http.Response response;
    try {
      response = await _sendRequest(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
    } on TimeoutException {
      throw const AIServiceException('AI 请求超时，请稍后再试');
    } on Object catch (error) {
      throw AIServiceException('网络请求失败：$error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AIServiceException(
        'AI 服务返回异常：HTTP ${response.statusCode} ${response.body}',
      );
    }

    try {
      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('响应不是 JSON 对象');
      }

      final choices = payload['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const FormatException('响应缺少 choices');
      }

      final firstChoice = choices.first;
      if (firstChoice is! Map) {
        throw const FormatException('choices[0] 不是对象');
      }

      final message = firstChoice['message'];
      if (message is! Map) {
        throw const FormatException('响应缺少 message');
      }

      final content = message['content']?.toString().trim() ?? '';
      if (content.isEmpty) {
        throw const FormatException('AI 返回内容为空');
      }

      return content;
    } on Object catch (error) {
      throw AIServiceException('AI 响应解析失败：$error');
    }
  }

  Future<http.Response> _sendRequest(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    if (kDebugMode && Platform.isAndroid && debugAndroidProxy.isNotEmpty) {
      final proxyHttpClient = HttpClient()
        ..findProxy = (_) => 'PROXY $debugAndroidProxy';
      final proxyClient = IOClient(proxyHttpClient);
      try {
        return await proxyClient
            .post(uri, headers: headers, body: body)
            .timeout(requestTimeout);
      } on Object {
        // Physical debug devices may not have the emulator proxy bridge.
      } finally {
        proxyClient.close();
      }
    }

    return http.post(uri, headers: headers, body: body).timeout(requestTimeout);
  }

  Map<String, dynamic> _decodeJsonObject(String content) {
    final cleanContent = _stripMarkdownFence(content.trim());
    final start = cleanContent.indexOf('{');
    final end = cleanContent.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw const AIServiceException('AI 未返回可解析的 JSON');
    }

    try {
      final decoded = jsonDecode(cleanContent.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw const FormatException('JSON 根节点不是对象');
    } on Object catch (error) {
      throw AIServiceException('任务解析 JSON 失败：$error');
    }
  }

  @visibleForTesting
  List<String> decodeBreakdownSteps(String content) {
    final cleanContent = _stripMarkdownFence(content.trim());
    final start = cleanContent.indexOf('[');
    final end = cleanContent.lastIndexOf(']');

    if (start != -1 && end > start) {
      try {
        final decoded = jsonDecode(cleanContent.substring(start, end + 1));
        if (decoded is List) {
          final steps = decoded
              .map((item) => _cleanStepLine(item.toString()))
              .where((line) => line.isNotEmpty)
              .take(3)
              .toList(growable: false);
          if (steps.length == 3) {
            return steps;
          }
        }
      } on FormatException {
        // Fall through to the line parser for models that return near-JSON.
      }
    }

    final quotedSteps = RegExp(r'"([^"\r\n]+)"')
        .allMatches(cleanContent)
        .map((match) => _cleanStepLine(match.group(1) ?? ''))
        .where((line) => line.isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (quotedSteps.length == 3) {
      return quotedSteps;
    }

    return cleanContent
        .split(RegExp(r'\r?\n|[；;]'))
        .map(_cleanStepLine)
        .where((line) => line.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  String _stripMarkdownFence(String text) {
    return text
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  String _cleanStepLine(String line) {
    return line
        .trim()
        .replaceFirst(RegExp(r'^[-*]\s*'), '')
        .replaceFirst(RegExp(r'^\d+[.、)]\s*'), '')
        .trim();
  }

  bool _isLowQualityBreakdownStep(String step) {
    final lowerStep = step.toLowerCase();
    if (_containsAny(lowerStep, const <String>[
      '制定学习计划',
      '制定计划',
      '坚持学习',
      '每天安排',
      '注册新账户',
      '登录账户',
      '创建账户',
      '打开网站',
      '英语学习应用',
      '初级词汇表',
      '打开app',
      '打开 app',
      '30个小时',
      '30 个小时',
    ])) {
      return true;
    }

    final hourMatch = RegExp(r'(\d+)\s*(?:个)?小时').firstMatch(step);
    final hours = int.tryParse(hourMatch?.group(1) ?? '');
    return hours != null && hours > 2;
  }

  String _buildBreakdownUserPrompt(String taskName) {
    final cleanTaskName = taskName.trim();
    final words = cleanTaskName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    final isShortEnglishTitle =
        RegExp(r'^[a-zA-Z\s-]+$').hasMatch(cleanTaskName) && words.length <= 4;

    if (!isShortEnglishTitle) {
      return '任务标题：$cleanTaskName';
    }

    return '任务标题：$cleanTaskName\n'
        '补充约束：这是一个信息不足的宽泛英文标题。用户没有指定 App、网站、账号、材料、'
        '单词表或具体学习内容。不要猜测这些信息，也不要随机指定单词；'
        '请让用户先从现有内容中选择一个很小的范围，再练习并自测。';
  }

  String _fallbackTaskTitleFromSpeech(String speech) {
    final compactSpeech = speech
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[。！？!?，,；;]+$'), '')
        .trim();
    if (compactSpeech.isEmpty) {
      return '先写一个任务标题';
    }

    final cleaned = compactSpeech
        .replaceFirst(RegExp(r'^(帮我|我要|我想|记得|提醒我|今天|明天)\s*'), '')
        .trim();
    final title = cleaned.isEmpty ? compactSpeech : cleaned;
    if (title.length <= 24) {
      return title;
    }

    return '${title.substring(0, 24)}...';
  }

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

TaskType taskTypeFromAiCategory(String category) {
  final text = category.trim().toLowerCase();
  if (_containsAny(text, const <String>['学习', '作业', '课程', 'study'])) {
    return TaskType.assignment;
  }
  if (_containsAny(text, const <String>['复习', '背书', 'review'])) {
    return TaskType.review;
  }
  if (_containsAny(text, const <String>['考试', '测验', 'exam'])) {
    return TaskType.exam;
  }
  if (_containsAny(text, const <String>['项目', '报告', '论文', 'project'])) {
    return TaskType.project;
  }
  if (_containsAny(text, const <String>[
    '运动',
    '日常',
    '生活',
    '跑步',
    'daily',
    'life',
  ])) {
    return TaskType.life;
  }

  return TaskType.other;
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool isUsefulAiChatReply(String message, String reply) {
  final cleanMessage = message.trim();
  final cleanReply = reply.trim();
  if (cleanReply.length < 12 || cleanReply.length > 140) {
    return false;
  }
  if (cleanReply.contains('\uFFFD')) {
    return false;
  }

  final inputContainsLatin = RegExp(r'[A-Za-z]').hasMatch(cleanMessage);
  final replyContainsLatinFragment = RegExp(
    r'[A-Za-z]{3,}',
  ).hasMatch(cleanReply);
  if (!inputContainsLatin && replyContainsLatinFragment) {
    return false;
  }

  final compactReply = cleanReply.replaceAll(RegExp(r'\s+'), '');
  if (_containsAny(compactReply, const <String>[
        '早起的鸟儿有虫吃',
        '好呀一起分解吧',
        '好呀～一起分解吧',
        '别急慢慢来',
      ]) &&
      compactReply.length < 26) {
    return false;
  }

  if (cleanMessage.contains('不想干活') &&
      !_containsAny(cleanReply, const <String>[
        '打开',
        '写',
        '读',
        '整理',
        '完成',
        '做',
        '收拾',
        '选择',
      ])) {
    return false;
  }
  if (cleanMessage.contains('安排今天') &&
      (!_containsAny(cleanReply, const <String>['任务', '待办', '事情']) ||
          !_containsAny(cleanReply, const <String>['清单', '发来', '最急', '优先']))) {
    return false;
  }
  if ((cleanMessage.contains('拆小') || cleanMessage.contains('大任务')) &&
      (!_containsAny(cleanReply, const <String>['任务', '事情']) ||
          !_containsAny(cleanReply, const <String>['具体', '发来', '告诉', '拆成']))) {
    return false;
  }

  return true;
}
