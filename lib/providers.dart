import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
final isGeneratingProvider = StateProvider<bool>((ref) => false);

class AppSettings {
  final String model;
  final String systemPrompt;
  final double temperature;
  final bool useSearch;
  final bool useThinking;
  final bool amoled;
  final double fontScale;
  final bool showTimestamps;
  final bool autoSpeak;
  final double voiceSpeed;
  final double voicePitch;
  final bool soundEffects;
  final bool haptics;
  final int hapticIntensity;
  final bool autoSendVoice;
  final bool smartScroll;

  AppSettings({
    this.model = 'glm',
    this.systemPrompt = 'أنت مساعد ذكي.',
    this.temperature = 0.5,
    this.useSearch = false,
    this.useThinking = false,
    this.amoled = false,
    this.fontScale = 1.0,
    this.showTimestamps = true,
    this.autoSpeak = false,
    this.voiceSpeed = 0.5,
    this.voicePitch = 1.0,
    this.soundEffects = true,
    this.haptics = true,
    this.hapticIntensity = 1,
    this.autoSendVoice = false,
    this.smartScroll = true,
  });

  AppSettings copyWith({
    String? model,
    String? systemPrompt,
    double? temperature,
    bool? useSearch,
    bool? useThinking,
    bool? amoled,
    double? fontScale,
    bool? showTimestamps,
    bool? autoSpeak,
    double? voiceSpeed,
    double? voicePitch,
    bool? soundEffects,
    bool? haptics,
    int? hapticIntensity,
    bool? autoSendVoice,
    bool? smartScroll,
  }) {
    return AppSettings(
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      useSearch: useSearch ?? this.useSearch,
      useThinking: useThinking ?? this.useThinking,
      amoled: amoled ?? this.amoled,
      fontScale: fontScale ?? this.fontScale,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      voicePitch: voicePitch ?? this.voicePitch,
      soundEffects: soundEffects ?? this.soundEffects,
      haptics: haptics ?? this.haptics,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      autoSendVoice: autoSendVoice ?? this.autoSendVoice,
      smartScroll: smartScroll ?? this.smartScroll,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences prefs;
  SettingsNotifier(this.prefs) : super(AppSettings(
    model: prefs.getString('model') ?? 'glm',
    systemPrompt: prefs.getString('system_prompt') ?? 'أنت مساعد ذكي.',
    temperature: prefs.getDouble('temperature') ?? 0.5,
    useSearch: prefs.getBool('use_search') ?? false,
    useThinking: prefs.getBool('use_thinking') ?? false,
    amoled: prefs.getBool('amoled') ?? false,
    fontScale: prefs.getDouble('font_scale') ?? 1.0,
    showTimestamps: prefs.getBool('show_timestamps') ?? true,
    autoSpeak: prefs.getBool('auto_speak') ?? false,
    voiceSpeed: prefs.getDouble('voice_speed') ?? 0.5,
    voicePitch: prefs.getDouble('voice_pitch') ?? 1.0,
    soundEffects: prefs.getBool('sound_effects') ?? true,
    haptics: prefs.getBool('haptics') ?? true,
    hapticIntensity: prefs.getInt('haptic_intensity') ?? 1,
    autoSendVoice: prefs.getBool('auto_send_voice') ?? false,
    smartScroll: prefs.getBool('smart_scroll') ?? true,
  ));

  void update(AppSettings s) {
    state = s;
    prefs.setString('model', s.model);
    prefs.setString('system_prompt', s.systemPrompt);
    prefs.setDouble('temperature', s.temperature);
    prefs.setBool('use_search', s.useSearch);
    prefs.setBool('use_thinking', s.useThinking);
    prefs.setBool('amoled', s.amoled);
    prefs.setDouble('font_scale', s.fontScale);
    prefs.setBool('show_timestamps', s.showTimestamps);
    prefs.setBool('auto_speak', s.autoSpeak);
    prefs.setDouble('voice_speed', s.voiceSpeed);
    prefs.setDouble('voice_pitch', s.voicePitch);
    prefs.setBool('sound_effects', s.soundEffects);
    prefs.setBool('haptics', s.haptics);
    prefs.setInt('haptic_intensity', s.hapticIntensity);
    prefs.setBool('auto_send_voice', s.autoSendVoice);
    prefs.setBool('smart_scroll', s.smartScroll);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPrefsProvider));
});

class ChatMessage {
  final String text;
  final bool isUser;
  final Uint8List? imageBase64;
  ChatMessage({this.text = '', required this.isUser, this.imageBase64});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'imageBase64': imageBase64 != null ? base64Encode(imageBase64!) : null,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    Uint8List? img;
    try {
      if (j['imageBase64'] != null) img = base64Decode(j['imageBase64']);
    } catch (e) {
      img = null;
    }
    return ChatMessage(
      text: j['text'] ?? '',
      isUser: j['isUser'] ?? false,
      imageBase64: img,
    );
  }
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final SharedPreferences prefs;
  final Ref ref;
  List<String> userMemory = [];
  Timer? _flushTimer;
  String _buffer = "";
  int _aiIndex = -1;

  ChatNotifier(this.prefs, this.ref) : super([]) {
    _load();
  }

  void _load() {
    try {
      final d = prefs.getString('chat_history');
      if (d != null && d.isNotEmpty) {
        state = (jsonDecode(d) as List)
            .map((e) => ChatMessage.fromJson(e))
            .toList();
      } else {
        state = [
          ChatMessage(
            text: 'مرحباً! أنا Alili. اسأل، ارسم، أو اطلب كود.',
            isUser: false,
          )
        ];
      }
      userMemory = prefs.getStringList('user_memory') ?? [];
    } catch (e) {
      state = [ChatMessage(text: 'مرحباً!', isUser: false)];
    }
  }

  void _save() {
    prefs.setString('chat_history', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void _flush() {
    if (_buffer.isEmpty || _aiIndex == -1) return;
    final u = List<ChatMessage>.from(state);
    if (_aiIndex < u.length) {
      u[_aiIndex] = ChatMessage(
        text: _buffer,
        isUser: false,
        imageBase64: u[_aiIndex].imageBase64,
      );
      state = u;
    }
  }

  Future<void> send(String text, Uint8List? img, AppSettings s) async {
    ref.read(isGeneratingProvider.notifier).state = true;
    state = [...state, ChatMessage(text: text, isUser: true, imageBase64: img)];
    _save();

    state = [...state, ChatMessage(text: '', isUser: false)];
    _aiIndex = state.length - 1;
    _buffer = "";

    _flushTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => _flush());
    
    final history = state
        .sublist(0, state.length - 2)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    try {
      await for (final chunk in ApiService.chatStream(text, history, userMemory, img, s)) {
        final d = jsonDecode(chunk);
        if (d['type'] == 'text') {
          _buffer += d['text'];
        } else if (d['type'] == 'code_output') {
          _buffer += "\n\n**المخرجات:**\n```\n${d['output']}\n```";
        } else if (d['type'] == 'image') {
          _flushTimer?.cancel();
          final u = List<ChatMessage>.from(state);
          u[_aiIndex] = ChatMessage(
            text: _buffer.isEmpty ? '🎨 الصورة جاهزة' : _buffer,
            isUser: false,
            imageBase64: base64Decode(d['base64']),
          );
          state = u;
          _save();
          ref.read(isGeneratingProvider.notifier).state = false;
          return;
        }
      }
    } catch (e) {
      _buffer += "\n\n(فشل الاتصال بالخادم)";
    } finally {
      _flushTimer?.cancel();
      _flush();
      _save();
      ref.read(isGeneratingProvider.notifier).state = false;
    }
  }

  void clear() {
    state = [ChatMessage(text: 'تم مسح المحادثة.', isUser: false)];
    _save();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.watch(sharedPrefsProvider), ref);
});
