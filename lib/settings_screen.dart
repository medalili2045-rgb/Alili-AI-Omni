import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: s.amoled ? Colors.black : const Color(0xFF0F0F0F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.gear, color: Colors.grey[400], size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'الإعدادات',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.x, color: Colors.grey[500], size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _sectionTitle('🎨 المظهر'),
                  _switchTile(
                    ref,
                    title: 'وضع AMOLED',
                    subtitle: 'أسود نقي، يوفر البطارية',
                    value: s.amoled,
                    onChanged: (v) => n.update(s.copyWith(amoled: v)),
                  ),
                  _switchTile(
                    ref,
                    title: 'الطوابع الزمنية',
                    subtitle: 'إظهار وقت كل رسالة',
                    value: s.showTimestamps,
                    onChanged: (v) => n.update(s.copyWith(showTimestamps: v)),
                  ),
                  _sliderTile(
                    ref,
                    title: 'حجم الخط',
                    value: s.fontScale,
                    min: 0.8,
                    max: 1.4,
                    label: '${(s.fontScale * 100).toInt()}%',
                    onChanged: (v) => n.update(s.copyWith(fontScale: v)),
                  ),

                  _sectionTitle('🔊 الصوت'),
                  _switchTile(
                    ref,
                    title: 'قراءة الردود تلقائياً',
                    subtitle: 'نطق كل رد بعد ظهوره',
                    value: s.autoSpeak,
                    onChanged: (v) => n.update(s.copyWith(autoSpeak: v)),
                  ),
                  _switchTile(
                    ref,
                    title: 'مؤثرات صوتية',
                    subtitle: 'صوت خفيف عند الإرسال والاستلام',
                    value: s.soundEffects,
                    onChanged: (v) => n.update(s.copyWith(soundEffects: v)),
                  ),
                  _sliderTile(
                    ref,
                    title: 'سرعة الصوت',
                    value: s.voiceSpeed,
                    min: 0.2,
                    max: 1.0,
                    label: '${(s.voiceSpeed * 100).toInt()}%',
                    onChanged: (v) => n.update(s.copyWith(voiceSpeed: v)),
                  ),
                  _sliderTile(
                    ref,
                    title: 'نبرة الصوت',
                    value: s.voicePitch,
                    min: 0.5,
                    max: 1.5,
                    label: '${(s.voicePitch * 100).toInt()}%',
                    onChanged: (v) => n.update(s.copyWith(voicePitch: v)),
                  ),

                  _sectionTitle('📳 الاهتزاز'),
                  _switchTile(
                    ref,
                    title: 'تفعيل الاهتزاز',
                    subtitle: 'اهتزاز خفيف عند التفاعل',
                    value: s.haptics,
                    onChanged: (v) => n.update(s.copyWith(haptics: v)),
                  ),
                  if (s.haptics)
                    _segmentedTile(
                      ref,
                      title: 'شدة الاهتزاز',
                      value: s.hapticIntensity,
                      options: const ['خفيف', 'متوسط', 'قوي'],
                      onChanged: (v) => n.update(s.copyWith(hapticIntensity: v)),
                    ),

                  _sectionTitle('🧠 الذكاء'),
                  _dropdownTile(
                    ref,
                    title: 'النموذج الأساسي',
                    value: s.model,
                    options: const {
                      'glm': 'GLM-5.3 (برمجة)',
                      'gemini': 'Gemini 4 (عام)',
                      'ernie': 'ERNIE 5.5 (أحدث)',
                    },
                    onChanged: (v) => n.update(s.copyWith(model: v)),
                  ),
                  _sliderTile(
                    ref,
                    title: 'درجة الإبداع',
                    value: s.temperature,
                    min: 0.0,
                    max: 1.0,
                    label: '${(s.temperature * 100).toInt()}%',
                    onChanged: (v) => n.update(s.copyWith(temperature: v)),
                  ),
                  _switchTile(
                    ref,
                    title: 'البحث في الويب',
                    subtitle: 'مصادر موثقة مع كل إجابة',
                    value: s.useSearch,
                    onChanged: (v) => n.update(s.copyWith(useSearch: v)),
                  ),
                  _switchTile(
                    ref,
                    title: 'التفكير العميق',
                    subtitle: 'تحليل خطوة بخطوة',
                    value: s.useThinking,
                    onChanged: (v) => n.update(s.copyWith(useThinking: v)),
                  ),

                  _sectionTitle('💬 الإدخال'),
                  _switchTile(
                    ref,
                    title: 'إرسال تلقائي بعد التحدث',
                    subtitle: 'يرسل فوراً عند انتهاء الصوت',
                    value: s.autoSendVoice,
                    onChanged: (v) => n.update(s.copyWith(autoSendVoice: v)),
                  ),
                  _switchTile(
                    ref,
                    title: 'التمرير الذكي',
                    subtitle: 'ينزل تلقائياً عند وصول رد جديد',
                    value: s.smartScroll,
                    onChanged: (v) => n.update(s.copyWith(smartScroll: v)),
                  ),

                  _sectionTitle('🗂️ البيانات'),
                  _dangerTile(
                    ref,
                    title: 'مسح كل المحادثات',
                    subtitle: 'لا يمكن التراجع',
                    icon: PhosphorIconsRegular.trash,
                    onTap: () => _confirmClear(context, ref),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Alili Omni v13.0',
                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _switchTile(
    WidgetRef ref, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11))
          : null,
      value: value,
      activeColor: Colors.grey[400],
      activeTrackColor: Colors.grey[700],
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }

  Widget _sliderTile(
    WidgetRef ref, {
    required String title,
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.grey[400],
            inactiveColor: Colors.grey[800],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _segmentedTile(
    WidgetRef ref, {
    required String title,
    required int value,
    required List<String> options,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: List.generate(options.length, (i) {
                final selected = value == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.grey[700] : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        options[i],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(
    WidgetRef ref, {
    required String title,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF1A1A1A),
            underline: const SizedBox(),
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
            items: options.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                HapticFeedback.selectionClick();
                onChanged(v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _dangerTile(
    WidgetRef ref, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11))
          : null,
      onTap: onTap,
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('تأكيد', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم مسح كل المحادثات نهائياً.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clear();
              Navigator.pop(c);
            },
            child: const Text('مسح', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
