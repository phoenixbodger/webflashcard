# Web Flashcard App 🎴

A powerful, multi-language flashcard application with enhanced text-to-speech capabilities and multiple game modes for effective learning.

## ✨ Features

### 🎴 Core Flashcard Functionality
- **Multi-sided cards** with custom headers
- **Import/Export** decks in JSON format
- **Local storage** for offline use
- **Deck management** with create, edit, delete operations

### 🎮 Interactive Learning Games
- **Study Mode**: Traditional flashcard review with audio
- **Typing Game**: Type answers from visual prompts
- **Audio Typing Game**: Type what you hear
- **Multiple Choice Game**: Select correct answers
- **Match Game**: Card matching exercises

### 🔊 Enhanced Audio Features
- **High-quality TTS** with optimized speech rate (0.90)
- **Multi-language support** with automatic detection
- **Premium voice selection** for natural sound
- **Language switching** for:
  - English (en-US)
  - Chinese (zh-CN)
  - Japanese (ja-JP)
  - Korean (ko-KR)
  - Arabic (ar-SA)
  - Russian (ru-RU)
  - Thai (th-TH)
  - Hindi (hi-IN)
  - Hebrew (he-IL)

### 🎯 Advanced Study Features
- **Comprehensive Help Section** with detailed guides
- **Spaced Retention** mode for optimized learning
- **Shuffle mode** for random review
- **Progress tracking** with scores and accuracy
- **Hint system** for difficult cards
- **Timer functionality** for speed practice

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Web browser (for web deployment)
- Android Studio/Xcode (for mobile deployment)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter_flashcard.git
   cd flutter_flashcard
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Web version
   flutter run -d chrome
   
   # Mobile version
   flutter run
   ```

## 📱 Usage

### Creating Decks
1. Click "Create New Deck" on the home screen
2. Enter deck title and headers (e.g., "Front", "Back")
3. Add cards with content for each side
4. Save your deck

### Importing Decks
1. Click "Import Deck" 
2. Upload a JSON file with deck data
3. Format:
   ```json
   {
     "title": "My Deck",
     "headers": ["Front", "Back"],
     "cards": [
       {"sides": ["Hello", "你好"]},
       {"sides": ["Thank you", "谢谢"]}
     ]
   }
   ```

### Study Modes

#### 📚 Study Mode
- Click "Study" on any deck
- Navigate cards with arrow buttons
- Use speaker icon for audio pronunciation
- Switch between card sides
- Enable shuffle or spaced retention

#### 🎮 Game Modes
- **Typing Game**: Type answers from visual prompts
- **Audio Typing Game**: Listen and type what you hear
- **Multiple Choice**: Select correct answers from options
- **Match Game**: Match corresponding cards

### Audio Settings
- Click the **Help button** (❓) in the top-right for comprehensive guides
- Click language button (EN, ES, FR, etc.) to change TTS language
- Audio automatically detects content language
- Enhanced TTS provides natural pronunciation
- Adjustable speech rate in `lib/services/enhanced_tts_service.dart`

## 🔧 Customization

### Changing Speech Rate
Edit `lib/services/enhanced_tts_service.dart`:
```dart
await _flutterTts!.setSpeechRate(0.90); // Adjust this value
```

### Voice Selection
Edit the voice list in `_setOptimalVoices()`:
```dart
final voices = [
  {"name": "Alex", "locale": "en-US"},        // Male voice
  {"name": "Samantha", "locale": "en-US"},     // Female voice
  {"name": "Microsoft David", "locale": "en-US"}, // Windows voice
];
```

### Adding New Languages
Add language detection in `_detectLanguage()`:
```dart
if (text.contains(RegExp(r'[CHARACTER_RANGE]'))) {
  return 'language-code';
}
```

## 🌐 Deployment

### Web Deployment
1. **Build for web**
   ```bash
   flutter build web --web-renderer canvaskit
   ```

2. **Deploy to GitHub Pages**
   ```bash
   # Install gh-pages
   npm install -g gh-pages
   
   # Deploy
   gh-pages -d build/web
   ```

3. **Enable GitHub Pages**
   - Go to repository settings
   - Enable GitHub Pages from `gh-pages` branch

### Mobile Deployment

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── models/
│   └── flashcard_model.dart      # Data models
├── services/
│   ├── enhanced_tts_service.dart # Enhanced TTS functionality
│   ├── import_service.dart       # Deck import/export
│   └── settings_service.dart     # App settings
├── screens/
│   ├── home_screen.dart          # Main screen
│   ├── deck_management_screen.dart # Deck CRUD
│   ├── deck_viewer_screen.dart   # Study mode
│   ├── typing_game_screen.dart   # Typing game
│   ├── audio_typing_game_screen.dart # Audio typing
│   ├── multiple_choice_game_screen.dart # Multiple choice
│   └── match_game_screen.dart     # Match game
└── main.dart                     # App entry point
```

## 🎯 Key Features Explained

### Enhanced TTS Service
- **Automatic language detection** based on character content
- **High-quality voice selection** with platform optimization
- **Optimal speech rate** (0.90) for intermediate learners
- **Multi-language support** with seamless switching

### Spaced Retention Algorithm
- Tracks card difficulty and review frequency
- Optimizes learning schedule based on performance
- Adapts to individual learning patterns

### Game Mechanics
- **Scoring system** with accuracy tracking
- **Hint system** with point deduction
- **Timer functionality** for speed practice
- **Progress tracking** across sessions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Flutter TTS community for audio functionality
- Enhanced TTS integration for improved learning experience

## 📞 Support

For issues, questions, or feature requests:
- Create an issue on GitHub
- Check existing documentation
- Review code comments for implementation details

---

**Happy Learning! 🎓**

