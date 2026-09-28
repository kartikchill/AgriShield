import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/language_notifier.dart';

class AccessibleAudioButton extends StatefulWidget {
  final String textToSpeak;
  final String? label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const AccessibleAudioButton({
    super.key, 
    required this.textToSpeak,
    this.label,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  State<AccessibleAudioButton> createState() => _AccessibleAudioButtonState();
}

class _AccessibleAudioButtonState extends State<AccessibleAudioButton> {
  late FlutterTts _ttsEngine;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _ttsEngine = FlutterTts();

    _ttsEngine.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });

    _ttsEngine.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _ttsEngine.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      await _ttsEngine.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    // Stop any ongoing playback first
    await _ttsEngine.stop();

    // Map the active language code to a TTS locale
    final langCode = LanguageNotifier.instance.languageCode;
    String ttsLocale = 'en-IN';
    if (langCode == 'hi') {
      ttsLocale = 'hi-IN';
    } else if (langCode == 'mr') {
      ttsLocale = 'mr-IN';
    }

    await _ttsEngine.setLanguage(ttsLocale);
    
    // Optional: Tune pitch/rate if needed, but defaults are generally fine.
    await _ttsEngine.setPitch(1.0);
    await _ttsEngine.speak(widget.textToSpeak);
  }

  @override
  void dispose() {
    _ttsEngine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final defaultIcon = widget.icon ?? Icons.volume_up;
        final activeIcon = Icons.record_voice_over;
        final baseColor = widget.color ?? const Color(0xFF1B4D3E);
        final activeColor = Colors.orange[700]!;

        if (widget.label != null) {
          return GestureDetector(
            onTap: _speak,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _isPlaying ? activeColor : baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isPlaying ? activeIcon : defaultIcon, color: widget.textColor ?? Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return IconButton(
            icon: Icon(
              _isPlaying ? activeIcon : defaultIcon,
              color: _isPlaying ? activeColor : baseColor,
            ),
            onPressed: _speak,
            tooltip: 'Say it Out Loud',
          );
        }
      },
    );
  }
}
