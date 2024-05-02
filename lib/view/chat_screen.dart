import 'dart:async';
import 'package:chat_gpt_flutter/const.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _openAi = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 10),
      // connectTimeout: const Duration(seconds: 10),
    ),
    enableLog: true,
    // orgId: "org-6VWqtvRCWWvzmrZKYB6lqNbY",
  );

  final _currentUser = ChatUser(id: "1", firstName: "Arun", lastName: "Raj");

  final _gptChatUser = ChatUser(id: "2", firstName: "Chat", lastName: "GPT");

  final List<ChatMessage> _messages = [];

  final List<ChatUser> _typingUser = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 166, 126, 1),
        title: const Text(
          'Chat GPT',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: DashChat(
        currentUser: _currentUser,
        typingUsers: _typingUser,
        messageOptions: MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: const Color.fromRGBO(0, 166, 126, 1),
          textColor: Colors.white,
          messageTextBuilder: (message,
              [ChatMessage? previousMessage, ChatMessage? nextMessage]) {
            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(milliseconds: 500),
                    backgroundColor: Color.fromRGBO(0, 166, 126, 1),
                    content: Text(
                      'Message copied to clipboard.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const Icon(
                    Icons.content_copy,
                    color: Colors.white,
                    size: 15,
                  ),
                ],
              ),
            );
          },
        ),
        onSend: (ChatMessage message) {
          getChatResponse(message);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _typingUser.add(_gptChatUser);
    });

    List<Messages> messageHistory = _messages.reversed.map((e) {
      if (e.user == _currentUser) {
        return Messages(role: Role.user, content: e.text);
      } else {
        return Messages(role: Role.assistant, content: e.text);
      }
    }).toList();

    try {
      final request = ChatCompleteText(
        model: GptTurbo0301ChatModel(),
        messages: messageHistory,
        maxToken: 200,
      );
      final response = await _openAi.onChatCompletion(request: request);

      for (var element in response!.choices) {
        if (element.message != null) {
          setState(() {
            _messages.insert(
              0,
              ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content,
              ),
            );
          });
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromRGBO(0, 166, 126, 1),
          content: Text(
            'Request timed out.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      setState(() {
        _typingUser.remove(_gptChatUser);
      });
    } finally {
      setState(() {
        _typingUser.remove(_gptChatUser);
      });
    }
  }
}
