import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Guide'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '🎴 Getting Started',
              'New to the app? Start here!',
              [
                '1. Create a new deck or import an existing one',
                '2. Add flashcards with questions and answers',
                '3. Choose a study mode or game to practice',
                '4. Track your progress and improve your learning',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '📚 Study Mode',
              'Traditional flashcard review with audio',
              [
                '• Click "Study" on any deck to start',
                '• Use arrow buttons to navigate between cards',
                '• Tap the speaker icon to hear pronunciation',
                '• Switch between front and back sides',
                '• Enable shuffle for random review',
                '• Try spaced retention for optimized learning',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '🎮 Game Modes',
              'Make learning fun with games!',
              [
                '**Typing Game**: Type answers from visual prompts',
                '• Select question and answer sides',
                '• Type your answer and submit',
                '• Get instant feedback and scoring',
                '',
                '**Audio Typing Game**: Listen and type what you hear',
                '• Click speaker to play audio',
                '• Type the word or phrase you hear',
                '• Use hints if you get stuck',
                '',
                '**Multiple Choice**: Select correct answers',
                '• Choose from 4 possible answers',
                '• Build speed and accuracy',
                '',
                '**Match Game**: Match corresponding cards',
                '• Find pairs of matching content',
                '• Test your memory and recognition',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '🔊 Audio Features',
              'Enhanced text-to-speech for better learning',
              [
                '• Automatic language detection',
                '• High-quality voice synthesis',
                '• Support for 9+ languages',
                '• Natural speech rate (0.90)',
                '• Click language button to change TTS language',
                '',
                '**Supported Languages:**',
                '• English (en-US)',
                '• Chinese (zh-CN)', 
                '• Japanese (ja-JP)',
                '• Korean (ko-KR)',
                '• Arabic (ar-SA)',
                '• Russian (ru-RU)',
                '• Thai (th-TH)',
                '• Hindi (hi-IN)',
                '• Hebrew (he-IL)',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '📁 Import & Export',
              'Share and backup your flashcards',
              [
                '**Import Decks:**',
                '• Click "Import Deck" on home screen',
                '• Upload a JSON file with deck data',
                '• Format: {"title": "Name", "headers": ["Front", "Back"], "cards": [{"sides": ["Q1", "A1"]}]',
                '',
                '**Export Decks:**',
                '• Click "Export" on any deck',
                '• Download as JSON file',
                '• Share with others or backup locally',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '⚙️ Settings & Customization',
              'Personalize your learning experience',
              [
                '• Compact mode for smaller screens',
                '• Theme selection (light/dark)',
                '### Audio Settings',
                '- Click the **Help button** (❓) in the top-right for comprehensive guides',
                '- **Language button**: In Study Mode, look for [🤖] button in the top bar',
                '- **🤖 Auto-detect mode**: Automatically switches voices based on content language',
                '- Chinese text → Chinese voice',
                '- English text → English voice',
                '- Best for mixed-language decks',
                '- **Manual language selection**: Choose a specific language for all content',
                '- All text uses the selected voice',
                '- Consistent pronunciation practice',
                '- **Override auto-detection**: Manual selection overrides automatic detection',
                '- **Sound Effects**: Games now include audio feedback',
                '- 🎵 Game start sound when any game begins',
                '- 🎯 Correct answer sound for right responses',
                '- ❌ Error sound for wrong answers',
                '- 🏁 Game over sound when completed',
                '- 🔇 **Mute/Unmute**: Click speaker icon in any game or home screen to toggle sounds',
                '- Enhanced TTS provides natural pronunciation',
                '- Adjustable speech rate in `lib/services/enhanced_tts_service.dart`',
                '• Change speech rate: setSpeechRate(0.90)',
                '• Modify voice selection in _setOptimalVoices()',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '🎯 Learning Tips',
              'Get the most out of your study sessions',
              [
                '• Start with study mode to familiarize content',
                '• Use games to test your knowledge',
                '• Enable spaced retention for long-term memory',
                '• Practice with audio for pronunciation',
                '• Mix different game modes for variety',
                '• Review difficult cards more frequently',
                '• Import decks from others for new content',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '🔧 Troubleshooting',
              'Common issues and solutions',
              [
                '**Audio not working?**',
                '• Check browser permissions for audio',
                '• Try refreshing the page',
                '• Ensure speakers/headphones are connected',
                '',
                '**Game not starting?**',
                '• Make sure deck has cards',
                '• Check question/answer side selection',
                '• Try different game modes',
                '',
                '**Import not working?**',
                '• Verify JSON format is correct',
                '• Check file size (should be < 1MB)',
                '• Ensure required fields: title, headers, cards',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '📱 Keyboard Shortcuts',
              'Navigate faster with shortcuts',
              [
                '• **Space**: Play audio (when available)',
                '• **Enter**: Submit answer (in games)',
                '• **Arrow Keys**: Navigate cards (study mode)',
                '• **Tab**: Move between input fields',
                '• **Escape**: Close dialogs/menus',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '💡 Pro Tips',
              'Advanced features for power users',
              [
                '• Create decks with 3+ sides for complex content',
                '• Use spaced retention for exam preparation',
                '• Mix languages in same deck for bilingual practice',
                '• Export progress data to track improvement',
                '• Share decks with study groups',
                '• Use audio typing for pronunciation practice',
                '• Combine multiple games for comprehensive review',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              '🌐 Web vs Mobile',
              'Platform-specific features',
              [
                '**Web Version:**',
                '• Full feature support',
                '• Keyboard shortcuts available',
                '• Easy sharing via URL',
                '• No installation required',
                '',
                '**Mobile Version:**',
                '• Touch-optimized interface',
                '• On-the-go learning',
                '• Offline capability',
                '• Native app experience',
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.contact_support,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Need More Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Check the GitHub repository for updates\n'
                    '• Report issues or request features\n'
                    '• Share your feedback and suggestions\n'
                    '• Join our community of learners',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              point,
              style: const TextStyle(fontSize: 14),
            ),
          )),
        ],
      ),
    );
  }
}
