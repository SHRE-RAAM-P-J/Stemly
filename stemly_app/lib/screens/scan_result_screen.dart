import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../visualiser/projectile_motion.dart';
import '../visualiser/free_fall_component.dart';
import '../visualiser/shm_component.dart';
import '../visualiser/visualiser_models.dart';

class ScanResultScreen extends StatefulWidget {
  final String topic;
  final List<String> variables;
  final Map<String, dynamic> notesJson;
  final String imagePath;

  const ScanResultScreen({
    super.key,
    required this.topic,
    required this.variables,
    required this.notesJson,
    required this.imagePath,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final Map<String, bool> expanded = {};
  
  // Visualiser state
  VisualTemplate? visualiserTemplate;
  Widget? visualiserWidget;
  bool loadingVisualiser = true;
  
  final String serverIp = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    for (var key in widget.notesJson.keys) {
      expanded[key] = false;
    }
    _loadVisualiser();
  }
  
  Future<void> _loadVisualiser() async {
    setState(() => loadingVisualiser = true);
    
    try {
      // Call backend to get visualiser template
      final url = Uri.parse('$serverIp/visualiser/generate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': widget.topic,
          'variables': widget.variables,
        }),
      );
      if (response.statusCode == 200) {
        print("✅ API RAW RESPONSE: ${response.body}");
        final data = jsonDecode(response.body);
        final templateJson = data['template'] as Map<String, dynamic>;
        final template = VisualTemplate.fromJson(templateJson);
        
        // Create Widget based on template ID
        final templateId = template.templateId.toLowerCase();
        Widget? newWidget;
        
        final p = template.parameters;
        double getVal(String key) => p[key]?.value ?? 0.0;
        
        if (templateId.contains('projectile')) {
          print("🎯 Creating projectile motion widget...");
          newWidget = ProjectileMotionWidget(
            U: getVal('U'),
            theta: getVal('theta'),
            g: getVal('g'),
          );
        } else if (templateId.contains('free') || templateId.contains('fall')) {
          print("🎯 Creating free fall widget...");
          newWidget = FreeFallWidget(
            h: getVal('h'),
            g: getVal('g'),
          );
        } else if (templateId.contains('shm') || templateId.contains('harmonic')) {
          print("🎯 Creating SHM widget...");
          newWidget = SHMWidget(
            A: getVal('A'),
            m: getVal('m'),
            k: getVal('k'),
          );
        } else if (templateId.contains('kinematics') || templateId.contains('motion')) {
          print("🎯 Creating Kinematics widget...");
          newWidget = KinematicsWidget(
            u: getVal('u'),
            a: getVal('a'),
            tMax: getVal('t_max'),
          );
        } else if (templateId.contains('optics') || templateId.contains('lens')) {
          print("🎯 Creating Optics widget...");
          newWidget = OpticsWidget(
            f: getVal('f'),
            u: getVal('u'),
            h_o: getVal('h_o'),
          );
        } else {
          print("⚠️ Template ID '$templateId' not recognized");
        }
        
        if (mounted) {
          setState(() {
            visualiserTemplate = template;
            visualiserWidget = newWidget;
            loadingVisualiser = false;
          });
        }
      } else {
        print('Visualiser API error: ${response.statusCode} - ${response.body}');
        if (mounted) setState(() => loadingVisualiser = false);
      }
    } catch (e) {
      print('Error loading visualiser: $e');
      if (mounted) setState(() => loadingVisualiser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final deepBlue = cs.primary;
    final primaryColor = cs.primaryContainer;
    final cardColor = theme.cardColor;
    final background = theme.scaffoldBackgroundColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: deepBlue),

          title: Text(
            "Scan Result",
            style: TextStyle(
              color: deepBlue,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: deepBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,

                  indicator: BoxDecoration(
                    color: deepBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),

                  labelColor: cs.onPrimaryContainer,
                  unselectedLabelColor: deepBlue,

                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),

                  tabs: const [
                    Tab(text: "AI Visualiser"),
                    Tab(text: "AI Notes"),
                  ],
                ),
              ),
            ),
          ),
        ),

        body: TabBarView(
          children: [
            _visualiser(deepBlue),
            _notes(cardColor, deepBlue),
          ],
        ),
      ),
    );
  }

  Widget _visualiser(Color deepBlue) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FLAME ANIMATION CARD
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: loadingVisualiser
                  ? const Center(child: CircularProgressIndicator())
                  : visualiserWidget != null
                      ? visualiserWidget!
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.animation, size: 48, color: deepBlue.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'No visualisation available\nfor "${widget.topic}"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: deepBlue.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 28),

          _title("Topic", deepBlue),
          _value(widget.topic, deepBlue),
          const SizedBox(height: 24),

          _title("Variables", deepBlue),
          _value(widget.variables.join(", "), deepBlue),
          
          const SizedBox(height: 30),
          _title("Chat with AI", deepBlue),
          const SizedBox(height: 10),
          _buildChatInterface(deepBlue, theme.cardColor),
        ],
      ),
    );
  }

  // Chat State
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isSendingMessage = false;

  Widget _buildChatInterface(Color deepBlue, Color cardColor) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? deepBlue : deepBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: isUser ? null : Radius.zero,
                      ),
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Change parameters (e.g., 'set velocity to 20')...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isSendingMessage 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: deepBlue))
                    : Icon(Icons.send_rounded, color: deepBlue),
                  onPressed: _isSendingMessage ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _isSendingMessage = true;
      _chatController.clear();
    });

    try {
      // Prepare current parameters
      final currentParams = <String, dynamic>{};
      if (visualiserTemplate != null) {
        visualiserTemplate!.parameters.forEach((key, val) {
          currentParams[key] = val.value;
        });
      }

      final url = Uri.parse('$serverIp/visualiser/update');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'template_id': visualiserTemplate?.templateId ?? '',
          'parameters': currentParams,
          'user_prompt': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedParams = data['parameters'] as Map<String, dynamic>;
        final aiResponse = data['ai_response'] as String? ?? "Done.";

        // Update Template Parameters locally
        if (visualiserTemplate != null) {
          updatedParams.forEach((key, value) {
            if (visualiserTemplate!.parameters.containsKey(key)) {
               // Create a new TemplateParameter with updated value
               final oldParam = visualiserTemplate!.parameters[key]!;
               visualiserTemplate!.parameters[key] = TemplateParameter(
                 name: oldParam.name,
                 value: (value is num) ? value.toDouble() : oldParam.value,
                 min: oldParam.min,
                 max: oldParam.max,
                 unit: oldParam.unit,
                 label: oldParam.label,
               );
            }
          });
          
          // Re-create widget with new values
          _updateVisualiserWidget(visualiserTemplate!.templateId, updatedParams);
        }

        setState(() {
          _chatMessages.add({'role': 'ai', 'content': aiResponse});
          _isSendingMessage = false;
        });
      } else {
        setState(() {
          _chatMessages.add({'role': 'ai', 'content': "Error updating parameters."});
          _isSendingMessage = false;
        });
      }
    } catch (e) {
      print("Chat Error: $e");
      setState(() {
        _chatMessages.add({'role': 'ai', 'content': "Failed to connect."});
        _isSendingMessage = false;
      });
    }
  }

  void _updateVisualiserWidget(String templateId, Map<String, dynamic> params) {
    // Helper to extract value safely
    double getVal(String key) => (params[key] is num) ? (params[key] as num).toDouble() : 0.0;

    Widget? newWidget;
    final tid = templateId.toLowerCase();

    if (tid.contains('projectile')) {
      newWidget = ProjectileMotionWidget(
        U: getVal('U'),
        theta: getVal('theta'),
        g: getVal('g'),
      );
    } else if (tid.contains('free') || tid.contains('fall')) {
      newWidget = FreeFallWidget(
        h: getVal('h'),
        g: getVal('g'),
      );
    } else if (tid.contains('shm') || tid.contains('harmonic')) {
      newWidget = SHMWidget(
        A: getVal('A'),
        m: getVal('m'),
        k: getVal('k'),
      );
    } else if (tid.contains('kinematics')) {
      newWidget = KinematicsWidget(
        u: getVal('u'),
        a: getVal('a'),
        tMax: getVal('t_max'),
      );
    } else if (tid.contains('optics')) {
      newWidget = OpticsWidget(
        f: getVal('f'),
        u: getVal('u'),
        h_o: getVal('h_o'),
      );
    }

    if (newWidget != null) {
      setState(() {
        visualiserWidget = newWidget;
        
        // Update the template object's internal values so future chats know current state
        if (visualiserTemplate != null) {
           params.forEach((key, value) {
             if (visualiserTemplate!.parameters.containsKey(key)) {
               // Create a new TemplateParameter with updated value
               final oldParam = visualiserTemplate!.parameters[key]!;
               visualiserTemplate!.parameters[key] = TemplateParameter(
                 name: oldParam.name,
                 value: (value is num) ? value.toDouble() : oldParam.value,
                 min: oldParam.min,
                 max: oldParam.max,
                 unit: oldParam.unit,
                 label: oldParam.label,
               );
             }
           });
        }
      });
    }
  }

  Widget _notes(Color cardColor, Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.notesJson.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          return _expandableCard(
            title: _formatKey(key),
            expanded: expanded[key]!,
            onTap: () {
              setState(() {
                expanded[key] = !expanded[key]!;
              });
            },
            child: _buildContent(value, deepBlue),
            cardColor: cardColor,
            deepBlue: deepBlue,
          );
        }).toList(),
      ),
    );
  }

  Widget _expandableCard({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
    required Color cardColor,
    required Color deepBlue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: deepBlue,
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic value, Color deepBlue) {
    if (value is String) {
      return Text(
        value,
        style: TextStyle(fontSize: 15, color: deepBlue),
      );
    }

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var e in value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text("• $e",
                  style: TextStyle(fontSize: 15, color: deepBlue)),
            ),
        ],
      );
    }

    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var e in value.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text("${e.key}: ${e.value}",
                  style: TextStyle(fontSize: 15, color: deepBlue)),
            ),
        ],
      );
    }

    return const Text("Unsupported format");
  }

  Widget _title(String text, Color deepBlue) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: deepBlue,
      ),
    );
  }

  Widget _value(String text, Color deepBlue) {
    return Text(
      text,
      style: TextStyle(fontSize: 17, color: deepBlue),
    );
  }

  String _formatKey(String raw) {
    if (raw.isEmpty) return "";
    return raw
        .replaceAll("_", " ")
        .trim()
        .replaceFirst(raw[0], raw[0].toUpperCase());
  }
}
