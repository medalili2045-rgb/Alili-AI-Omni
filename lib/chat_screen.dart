import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'providers.dart';
import 'settings_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _c = TextEditingController();
  final _sc = ScrollController();
  Uint8List? _img;
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage("ar-SA");
  }

  @override
  void dispose() {
    _c.dispose();
    _sc.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) {
        _sc.animateTo(
          _sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) {
      final b = await f.readAsBytes();
      if (mounted) setState(() => _img = b);
    }
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'csv', 'json'],
    );
    if (r != null && r.files.single.path != null) {
      final f = r.files.single;
      final b = await f.readAsBytes();
      final content = String.fromCharCodes(b);
      if (mounted) {
        setState(() {
          _c.text = "حلل هذا الملف (${f.name}):\n\n${content.substring(0, content.length > 5000 ? 5000 : content.length)}";
        });
      }
    }
  }

  void _showAttachmentMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.image, color: Colors.grey[400]),
              title: Text('صورة', style: TextStyle(color: Colors.grey[300])),
              onTap: () {
                Navigator.pop(c);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.file, color: Colors.grey[400]),
              title: Text('ملف', style: TextStyle(color: Colors.grey[300])),
              onTap: () {
                Navigator.pop(c);
                _pickFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _listen() async {
    if (!_listening) {
      final ok = await _speech.initialize();
      if (ok) {
        HapticFeedback.lightImpact();
        setState(() => _listening = true);
        _speech.listen(
          onResult: (v) => setState(() => _c.text = v.recognizedWords),
          localeId: "ar_SA",
        );
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() => _listening = false);
      _speech.stop();
    }
  }

  void _send() {
    if (_c.text.isEmpty && _img == null) return;
    HapticFeedback.mediumImpact();
    ref.read(chatProvider.notifier).send(_c.text, _img, ref.read(settingsProvider));
    _c.clear();
    setState(() => _img = null);
  }

  void _showSettings() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => FractionallySizedBox(
        heightFactor: 0.85,
        child: const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(chatProvider);
    final isGen = ref.watch(isGeneratingProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen(chatProvider, (_, __) {
      if (settings.smartScroll) _scrollDown();
    });

    final bgColor = settings.amoled ? Colors.black : const Color(0xFF0F0F0F);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Alili Omni',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.gear, color: Colors.grey[500], size: 22),
            onPressed: _showSettings,
          ),
          IconButton(
            icon: Icon(PhosphorIconsRegular.trash, color: Colors.grey[500], size: 22),
            onPressed: () {
              HapticFeedback.heavyImpact();
              ref.read(chatProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _sc,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: msgs.length,
              itemBuilder: (c, i) {
                final m = msgs[i];
                if (!m.isUser && m.text.isEmpty && m.imageBase64 == null) {
                  return _typingIndicator();
                }
                return _bubble(m, settings);
              },
            ),
          ),
          if (_img != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF141414),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _img!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      cacheWidth: 80,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('صورة مرفقة', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.x, color: Colors.grey[500], size: 18),
                    onPressed: () => setState(() => _img = null),
                  ),
                ],
              ),
            ),
          
          // زرا البحث والتفكير
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleToggle(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  active: settings.useSearch,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(settingsProvider.notifier).update(settings.copyWith(useSearch: !settings.useSearch));
                  },
                ),
                const SizedBox(width: 12),
                _circleToggle(
                  icon: PhosphorIconsRegular.brain,
                  active: settings.useThinking,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(settingsProvider.notifier).update(settings.copyWith(useThinking: !settings.useThinking));
                  },
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            color: bgColor,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(PhosphorIconsRegular.plus, color: Colors.grey[500], size: 24),
                  onPressed: _showAttachmentMenu,
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 110),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _c,
                            maxLines: 5,
                            minLines: 1,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'اسأل، ارسم، أو اطلب كود...',
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _listening ? PhosphorIconsRegular.microphone : PhosphorIconsRegular.microphoneSlash,
                            color: _listening ? Colors.white : Colors.grey[500],
                            size: 22,
                          ),
                          onPressed: _listen,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: isGen ? null : _send,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isGen ? Colors.grey[800] : Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGen ? PhosphorIconsRegular.stop : PhosphorIconsRegular.arrowUp,
                                color: Colors.grey[300],
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _circleToggle({required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? Colors.grey[700] : Colors.grey[900],
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Colors.grey[500]! : Colors.grey[850]!,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.grey[500],
          size: 16,
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Text('يفكر...', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m, AppSettings s) {
    final fontSize = 14.0 * s.fontScale;
    final codeFontSize = 13.0 * s.fontScale;

    if (m.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (m.imageBase64 != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(m.imageBase64!, fit: BoxFit.cover, cacheWidth: 600),
                ),
              if (m.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(color: Colors.white, fontSize: fontSize, height: 1.5),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIconsRegular.sparkle, size: 12, color: Colors.grey[400]),
              ),
              const SizedBox(width: 6),
              Text(
                'Alili',
                style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (m.imageBase64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(m.imageBase64!, fit: BoxFit.cover, cacheWidth: 600),
            ),
          if (m.imageBase64 != null) const SizedBox(height: 6),
          if (m.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: m.imageBase64 != null ? 6 : 0),
              child: MarkdownBody(
                data: m.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: Colors.grey[300], fontSize: fontSize, height: 1.6),
                  code: TextStyle(
                    backgroundColor: const Color(0xFF1A1A1A),
                    color: Colors.grey[300],
                    fontFamily: 'monospace',
                    fontSize: codeFontSize,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
