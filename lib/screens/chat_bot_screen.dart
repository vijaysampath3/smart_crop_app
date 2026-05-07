import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:smart_crop_assistant/core/config/app_secrets.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? content;

  ChatMessage({required this.text, required this.isUser, this.content});
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speechToText.initialize();
    } catch (e) {
      // Ignore initialization errors
    }
    setState(() {});
  }

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I can help you with your crops today. What would you like to know?',
      isUser: false,
    ),
    ChatMessage(
      text: 'My tomato leaves are turning yellow. What should I do?',
      isUser: true,
    ),
    ChatMessage(
      text: 'Yellow leaves on tomatoes can be caused by several factors. Here are some recommendations:',
      isUser: false,
      content: _buildRecommendationContent(),
    ),
  ];

  static Widget _buildRecommendationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildBulletPoint(
          icon: Icons.pest_control,
          iconColor: Colors.red[500]!,
          title: 'Pest:',
          description: 'Check for aphids or spider mites under the leaves.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          icon: Icons.compost,
          iconColor: Colors.amber[500]!,
          title: 'Fertilizer:',
          description: 'Add nitrogen-rich organic compost or liquid seaweed.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          icon: Icons.water_drop,
          iconColor: Colors.blue[500]!,
          title: 'Watering:',
          description: 'Ensure deep, consistent watering at the base of the plant.',
        ),
      ],
    );
  }

  static Widget _buildBulletPoint({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF1E293B), // slate-800
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> getBotResponse(String message) async {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Typing...',
        isUser: false,
      ));
      _isTyping = true;
    });

    try {
      final String apiKey = AppSecrets.githubApiKey;
      final response = await http.post(
        Uri.parse('https://models.inference.ai.azure.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'api-key': apiKey,
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert agricultural assistant. Give short and practical advice to farmers.'
            },
            {'role': 'user', 'content': message},
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final botText = data['choices'][0]['message']['content'];

        setState(() {
          final int typeIndex = _messages.lastIndexWhere((m) => m.text == 'Typing...');
          if (typeIndex != -1) _messages.removeAt(typeIndex);
          
          _messages.add(ChatMessage(
            text: botText,
            isUser: false,
          ));
          _isTyping = false;
        });
      } else {
        setState(() {
          final int typeIndex = _messages.lastIndexWhere((m) => m.text == 'Typing...');
          if (typeIndex != -1) _messages.removeAt(typeIndex);
          debugPrint(response.body);
          _messages.add(ChatMessage(
            text: 'Error ${response.statusCode}: ${response.body}',
            isUser: false,
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        final int typeIndex = _messages.lastIndexWhere((m) => m.text == 'Typing...');
        if (typeIndex != -1) _messages.removeAt(typeIndex);
        
        _messages.add(ChatMessage(
          text: 'Failed to connect. Please check your internet connection.',
          isUser: false,
        ));
        _isTyping = false;
      });
    }
  }

  void _startListening() async {
    try {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _stopListening();
              _handleSubmitted(_textController.text);
            }
          },
        );
      }
    } catch (e) {
      // Ignore errors if permission is denied
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    getBotResponse(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildBottomActionArea(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), // Placeholder for texture
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF10B981)), // primary
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farmer Chat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981), // primary text
                      letterSpacing: -0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Online. Ready to assist.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B), // slate-500
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(Icons.more_vert),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // slate-100
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF64748B), size: 20), // slate-500
        onPressed: () {},
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0, bottom: 4.0),
                    child: Text(
                      'Farmer',
                      style: TextStyle(
                        color: Color(0xFF64748B), // slate-500
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // primary
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981), // primary
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1), width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                // Using a generic robot icon for the assistant if image is not right
                child: Icon(Icons.smart_toy, color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                      'Farm AI Assistant',
                      style: TextStyle(
                        color: Color(0xFF64748B), // slate-500
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9), // slate-100
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Color(0xFF1E293B), // slate-800
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (message.content != null) message.content!,
                      ],
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

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickSuggestions(),
            const SizedBox(height: 16),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Why this crop?',
      'Pest control tips',
      'Fertilizer guide',
      'Weather advice',
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return OutlinedButton(
            onPressed: () {
              _textController.text = suggestions[index];
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
              side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              suggestions[index],
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // slate-100
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: const Color(0xFF64748B), // slate-500
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Ask your farming question...',
                hintStyle: TextStyle(
                  color: Color(0xFF64748B), // slate-500
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(
                color: Color(0xFF1E293B), // slate-800
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF64748B), // red-500 or slate-500
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), // primary
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () {
                _handleSubmitted(_textController.text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
