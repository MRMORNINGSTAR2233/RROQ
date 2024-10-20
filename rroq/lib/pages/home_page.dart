import 'dart:convert';
import '/components/input_widget.dart';
import '/components/message_widget.dart';
import '/const/api_key.dart';
import '/const/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _isTyping = false;
  final String _apiKey = apiKey; // Make sure this is your Groq API key
  String? _selectedModel;

  final List<Map<String, String>> _models = [
    {'name': 'Llama 3 Groq 70B Tool Use (Preview)', 'id': 'llama3-groq-70b-8192-tool-use-preview'},
    {'name': 'Llama 3 Groq 8B Tool Use (Preview)', 'id': 'llama3-groq-8b-8192-tool-use-preview'},
    {'name': 'Llama 3.1 70B', 'id': 'llama-3.1-70b-versatile'},
    {'name': 'Llama 3.1 8B', 'id': 'llama-3.1-8b-instant'},
    {'name': 'Llama 3.2 1B (Preview)', 'id': 'llama-3.2-1b-preview'},
    {'name': 'Llama 3.2 3B (Preview)', 'id': 'llama-3.2-3b-preview'},
    {'name': 'Llama 3.2 11B Vision (Preview)', 'id': 'llama-3.2-11b-vision-preview'},
    {'name': 'Llama 3.2 90B (Preview)', 'id': 'llama-3.2-90b-vision-preview'},
    {'name': 'Meta Llama 3 70B', 'id': 'llama3-70b-8192'},
    {'name': 'Meta Llama 3 8B', 'id': 'llama3-8b-8192'},
    {'name': 'Mixtral 8x7B', 'id': 'mixtral-8x7b-32768'},
  ];

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _selectedModel == null) return;
    setState(() {
      _messages.add("You: ${_controller.text}");
      _messages.add("AI: Typing...");
      _isTyping = true;
    });
    final message = _controller.text;
    _controller.clear();
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _selectedModel,
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            ..._messages
                .where((msg) => msg.startsWith("You: ") || msg.startsWith("AI: "))
                .map((msg) {
              final parts = msg.split(': ');
              return {
                'role': parts[0].toLowerCase() == 'you' ? 'user' : 'assistant',
                'content': parts.sublist(1).join(': '),
              };
            }),
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'];
        setState(() {
          _messages.removeLast();
          _messages.add("AI: $aiMessage");
          _isTyping = false;
        });
      } else {
        throw Exception('Failed to get response from Groq API');
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add("Error: Failed to send message. $e");
        _isTyping = false;
      });
    }
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat App"),
        leading: IconButton(
          icon: SvgPicture.asset(
            widget.isDarkMode ? AssetsIcons.moon : AssetsIcons.sun,
          ),
          onPressed: widget.toggleTheme,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              AssetsIcons.newChat,
            ),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedModel,
              isExpanded: true,
              hint: Text('Select a model'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedModel = newValue;
                });
              },
              items: _models.map<DropdownMenuItem<String>>((Map<String, String> model) {
                return DropdownMenuItem<String>(
                  value: model['id'],
                  child: Text(model['name']!, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isAIMessage = _messages[index].startsWith("AI: ");
                return MessageWidget(
                  message: _messages[index],
                  isAIMessage: isAIMessage,
                );
              },
            ),
          ),
          InputWidget(
            controller: _controller,
            onSend: _selectedModel != null ? () => _sendMessage() : () {},
          ),
        ],
      ),
    );
  }
}