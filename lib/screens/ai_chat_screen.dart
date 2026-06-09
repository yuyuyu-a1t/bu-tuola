import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ai_service.dart';

const _background = Color(0xFFFFFCF7);
const _ink = Color(0xFF274238);
const _mutedInk = Color(0xFF78837C);
const _green = Color(0xFF63B87A);
const _softGreen = Color(0xFFEAF6E7);
const _softYellow = Color(0xFFFFF0C7);
const _softPink = Color(0xFFFFE6E5);
const _softBlue = Color(0xFFEAF2EA);
const _paper = Color(0xFFFFFFFF);
const _robotAsset = 'assets/images/ai_robot.png';
const _aiReplyTimeout = Duration(seconds: 10);
const _remoteReplyStartDelay = Duration(milliseconds: 320);

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.remoteReply});

  final Future<String> Function(String message)? remoteReply;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetMessage]) {
    final message = (presetMessage ?? _inputController.text).trim();
    if (message.isEmpty) {
      return;
    }

    _inputController.clear();
    final fallbackReplyIndex = _messages.length + 1;
    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _messages.add(
        _ChatMessage(
          text: _fallbackReplyFor(message),
          isUser: false,
          isLocalFallback: true,
        ),
      );
    });
    _scrollToBottom();

    unawaited(_upgradeReplyWithRemoteAI(message, fallbackReplyIndex));
  }

  Future<void> _upgradeReplyWithRemoteAI(String message, int replyIndex) async {
    await Future<void>.delayed(_remoteReplyStartDelay);
    if (!mounted) {
      return;
    }

    try {
      final remoteReply = widget.remoteReply ?? AIService.instance.chatWithAI;
      final reply = await remoteReply(message).timeout(_aiReplyTimeout);
      if (!mounted) {
        return;
      }
      if (!isUsefulAiChatReply(message, reply)) {
        throw const AIServiceException('远端回复质量不合格，保留本地急救建议');
      }

      setState(() {
        if (replyIndex < _messages.length &&
            _messages[replyIndex].isLocalFallback) {
          _messages[replyIndex] = _ChatMessage(text: reply, isUser: false);
        }
      });
    } catch (error) {
      debugPrint('AI chat failed: $error');
    } finally {
      if (mounted) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: [
                  const _PageHeader(),
                  const SizedBox(height: 18),
                  _QuickActionRow(
                    onAction: (message) {
                      _inputFocusNode.unfocus();
                      _sendMessage(message);
                    },
                  ),
                  const SizedBox(height: 18),
                  _WelcomeCard(onTry: () => _sendMessage(_quickActions.first)),
                  if (_messages.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _ConversationCard(messages: _messages),
                  ],
                  const SizedBox(height: 16),
                  const _RescueTipCard(),
                ],
              ),
            ),
            _ChatComposer(
              controller: _inputController,
              focusNode: _inputFocusNode,
              onSend: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop) ...[
          Material(
            key: const ValueKey('ai-back-button'),
            color: _paper,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _ink,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚑 拖延急救站',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '把卡住的任务丢过来，我来帮你拆成能马上开始的小步骤。',
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.68),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.translate(
              offset: const Offset(-4, 8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  _robotAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 64)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < _quickActions.length; index++) ...[
            _QuickActionPill(
              label: _quickActions[index],
              color: _quickActionColors[index % _quickActionColors.length],
              onPressed: () => onAction(_quickActions[index]),
            ),
            if (index != _quickActions.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onPressed(),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.72),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onTry});

  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Image.asset(
              _robotAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 50)),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '欢迎来到拖延急救站 👋',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  '别担心，不用一下子搞定全部。把卡住的事发给我，我先帮你拆开一点点。',
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: _green,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onTry,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      child: Text(
                        '✨ 试试一键拆解',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
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

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.messages});

  final List<_ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Column(
        children: [
          for (final message in messages) _ChatBubble(message: message),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const _AssistantAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? _softGreen : _paper,
                borderRadius: message.isUser
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  if (message.isLocalFallback) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '正在后台悄悄优化回答…',
                      style: TextStyle(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const _UserAvatar(),
          ],
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _softGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _green.withValues(alpha: 0.12), blurRadius: 10),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          _robotAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return const Center(
              child: Text('🤖', style: TextStyle(fontSize: 22)),
            );
          },
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _softYellow,
        shape: BoxShape.circle,
      ),
      child: const Text('👩‍🎓', style: TextStyle(fontSize: 22)),
    );
  }
}

class _RescueTipCard extends StatelessWidget {
  const _RescueTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      decoration: BoxDecoration(
        color: _softYellow.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Text('✨', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日急救建议',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '先做最小的一步，状态会慢慢回来～',
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text('🪴', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: _background,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _softGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: _green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                onTapOutside: (_) => focusNode.unfocus(),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '把拖延症状丢过来...',
                  hintStyle: TextStyle(
                    color: _mutedInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Semantics(
            button: true,
            label: '发送消息',
            child: Material(
              color: _green,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onSend,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _paper.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.07),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLocalFallback = false,
  });

  final String text;
  final bool isUser;
  final bool isLocalFallback;
}

const _quickActions = <String>['💊 救命我不想干活', '📅 帮我安排今天', '🧩 把大任务拆小'];

const _quickActionColors = <Color>[_softYellow, _softPink, _softBlue];

String _fallbackReplyFor(String message) {
  final lowerMessage = message.toLowerCase();
  if (lowerMessage.contains('english') || message.contains('英语')) {
    return '英语急救版：先学 5 个单词，或听 2 分钟材料。别立大旗，先骗大脑启动。🌱';
  }
  if (message.contains('不想干活')) {
    return '先别干“大活”。只做 3 分钟：打开任务，写一个标题。糊弄式启动也算赢。✨';
  }
  if (message.contains('安排今天')) {
    return '今天先排 3 件：最急的、最小的、最想逃的。先从最小的开刀，别逞强。🍵';
  }
  if (message.contains('拆小') || message.contains('大任务')) {
    return '拆成：打开材料、写第一句、保存进度。你看，任务已经被我切碎了。🌱';
  }
  if (message.contains('5 分钟') || message.contains('开始')) {
    return '计时 5 分钟，只许开始，不许完美。结束后你可以理直气壮休息。⏳';
  }

  return '先把它缩成一个动作：打开材料，做最小一口。完成后再决定要不要继续。✨';
}
