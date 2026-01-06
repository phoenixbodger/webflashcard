import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/flashcard_model.dart';
import '../services/enhanced_tts_service.dart';

class DeckViewerScreen extends StatefulWidget {
  final Deck deck;

  const DeckViewerScreen({super.key, required this.deck});

  @override
  State<DeckViewerScreen> createState() => _DeckViewerScreenState();
}

class _DeckViewerScreenState extends State<DeckViewerScreen> {
  int _currentCardIndex = 0;
  int _currentSideIndex = 0;
  int _firstSideIndex = 0; // Which side to show first (side 1)
  bool _isShuffled = false;
  bool _isSpacedRetention = false; // New spaced retention mode
  List<int> _cardOrder = []; // Stores the order of cards when shuffled
  List<int> _spacedRetentionQueue = []; // Queue for spaced retention
  Map<int, int> _cardRetentionScores = {}; // Track retention scores for each card
  Map<int, int> _cardReviewCounts = {}; // Track how many times each card has been reviewed
  
  // Audio functionality
  final EnhancedTTSService _ttsService = EnhancedTTSService();
  bool _isSpeaking = false;
  String _selectedLanguage = 'auto'; // Default to auto-detect

  @override
  void initState() {
    super.initState();
    // Initialize card order (sequential by default)
    _cardOrder = List.generate(widget.deck.cards.length, (index) => index);
    // Initialize retention scores and review counts
    for (int i = 0; i < widget.deck.cards.length; i++) {
      _cardRetentionScores[i] = 0; // Start with 0 retention score
      _cardReviewCounts[i] = 0; // Start with 0 reviews
    }
    // Default to first side (0), but can be changed
    _currentSideIndex = _firstSideIndex;
    
    // Initialize Enhanced TTS
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deck.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.deck.title),
        ),
        body: const Center(
          child: Text('No cards in this deck'),
        ),
      );
    }

    final currentCard = widget.deck.cards[_cardOrder[_currentCardIndex]];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          TextButton.icon(
            icon: Icon(_isShuffled ? Icons.shuffle_on : Icons.shuffle),
            label: Text(_isShuffled ? 'Shuffled' : 'Shuffle'),
            onPressed: _toggleShuffle,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton.icon(
            icon: Icon(_isSpacedRetention ? Icons.psychology : Icons.psychology_outlined),
            label: Text(_isSpacedRetention ? 'Spaced' : 'Spaced'),
            onPressed: _toggleSpacedRetention,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.language),
            label: Text(_getLanguageDisplayName()),
            onPressed: _showLanguageSelector,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Settings'),
            onPressed: _showSideSettings,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          if (!_isSpacedRetention)
            LinearProgressIndicator(
              value: (_currentCardIndex + 1) / widget.deck.cards.length,
            ),
          if (_isSpacedRetention)
            LinearProgressIndicator(
              value: _getSpacedRetentionProgress(),
              backgroundColor: Colors.grey[300],
              color: _getSpacedRetentionColor(),
            ),
          
          // Card and side counter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!_isSpacedRetention)
                  Text(
                    'Card ${_currentCardIndex + 1} of ${widget.deck.cards.length} • Side ${_currentSideIndex + 1} of ${currentCard.sides.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                if (_isSpacedRetention)
                  Column(
                    children: [
                      Text(
                        'Spaced Retention Mode',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSpacedRetentionStatus(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Side ${_currentSideIndex + 1} of ${currentCard.sides.length}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Flashcard
          Expanded(
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 8,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Side header
                      Text(
                        _getSideHeader(_currentSideIndex),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Current side content
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Speaker button for audio
                              IconButton(
                                onPressed: _isSpeaking ? null : _speakCurrentCard,
                                icon: Icon(
                                  _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                tooltip: 'Read text aloud',
                              ),
                              const SizedBox(height: 8),
                              // Text content
                              Expanded(
                                child: Center(
                                  child: Text(
                                    currentCard.sides[_currentSideIndex],
                                    style: Theme.of(context).textTheme.headlineMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Side navigation buttons
                      if (currentCard.sides.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentSideIndex > 0)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentSideIndex--;
                                  });
                                },
                                child: const Text('Previous Side'),
                              ),
                            if (_currentSideIndex < currentCard.sides.length - 1)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentSideIndex++;
                                  });
                                },
                                child: const Text('Next Side'),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Card navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!_isSpacedRetention)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _currentCardIndex > 0
                            ? () {
                                setState(() {
                                  _currentCardIndex--;
                                  _currentSideIndex = _firstSideIndex;
                                });
                              }
                            : null,
                        child: const Text('Previous Card'),
                      ),
                      ElevatedButton(
                        onPressed: _currentCardIndex < widget.deck.cards.length - 1
                            ? () {
                                setState(() {
                                  _currentCardIndex++;
                                  _currentSideIndex = _firstSideIndex;
                                });
                              }
                            : null,
                        child: const Text('Next Card'),
                      ),
                    ],
                  ),
                if (_isSpacedRetention)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _markCardDifficulty('easy'),
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            label: const Text('Easy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              foregroundColor: Colors.green,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _markCardDifficulty('medium'),
                            icon: const Icon(Icons.help, color: Colors.orange),
                            label: const Text('Medium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              foregroundColor: Colors.orange,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _markCardDifficulty('hard'),
                            icon: const Icon(Icons.error, color: Colors.red),
                            label: const Text('Hard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _getSpacedRetentionQueue().isNotEmpty
                                ? () {
                                    setState(() {
                                      _nextSpacedRetentionCard();
                                    });
                                  }
                                : null,
                            child: const Text('Next Card'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _resetSpacedRetention();
                              });
                            },
                            child: const Text('Reset Progress'),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getSideHeader(int sideIndex) {
    // Use deck headers if available, otherwise use default headers
    if (widget.deck.headers != null && sideIndex < widget.deck.headers!.length) {
      return widget.deck.headers![sideIndex];
    }
    
    // Fallback to default headers
    final headers = ['Side 1', 'Side 2', 'Side 3', 'Side 4', 'Side 5'];
    if (sideIndex < headers.length) {
      return headers[sideIndex];
    }
    return 'Side ${sideIndex + 1}';
  }

  void _toggleShuffle() {
    setState(() {
      if (_isShuffled) {
        // Turn off shuffle - restore sequential order
        _isShuffled = false;
        _cardOrder = List.generate(widget.deck.cards.length, (index) => index);
        _currentCardIndex = 0; // Reset to first card
      } else {
        // Turn on shuffle - randomize order
        _isShuffled = true;
        _cardOrder = List.generate(widget.deck.cards.length, (index) => index);
        _cardOrder.shuffle();
        _currentCardIndex = 0; // Start from first shuffled card
      }
      _currentSideIndex = _firstSideIndex; // Reset to first side
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isShuffled ? 'Shuffle mode enabled' : 'Shuffle mode disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSideSettings() async {
    if (widget.deck.cards.isEmpty) return;
    
    final currentCard = widget.deck.cards[_cardOrder[_currentCardIndex]];
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Which side should be shown first (Side 1)?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < currentCard.sides.length; i++)
              RadioListTile<int>(
                title: Text(_getSideHeader(i)),
                subtitle: Text(
                  currentCard.sides[i].length > 30 
                      ? '${currentCard.sides[i].substring(0, 30)}...'
                      : currentCard.sides[i],
                ),
                value: i,
                groupValue: _firstSideIndex,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (result != null && result != _firstSideIndex) {
      setState(() {
        _firstSideIndex = result;
        _currentSideIndex = _firstSideIndex;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now showing ${_getSideHeader(_firstSideIndex)} first'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Spaced Retention Methods
  void _toggleSpacedRetention() {
    setState(() {
      if (_isSpacedRetention) {
        // Turn off spaced retention - return to normal mode
        _isSpacedRetention = false;
        _currentCardIndex = 0; // Reset to first card
        _currentSideIndex = _firstSideIndex;
      } else {
        // Turn on spaced retention - initialize queue
        _isSpacedRetention = true;
        _initializeSpacedRetention();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSpacedRetention ? 'Spaced retention mode enabled' : 'Spaced retention mode disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _initializeSpacedRetention() {
    _spacedRetentionQueue = List.generate(widget.deck.cards.length, (index) => index);
    _spacedRetentionQueue.shuffle(); // Start with random order
    _currentCardIndex = _spacedRetentionQueue.isNotEmpty ? _spacedRetentionQueue.removeAt(0) : 0;
    _currentSideIndex = _firstSideIndex;
  }

  void _markCardDifficulty(String difficulty) {
    final cardIndex = _currentCardIndex;
    
    setState(() {
      // Update retention score based on difficulty
      switch (difficulty) {
        case 'easy':
          _cardRetentionScores[cardIndex] = (_cardRetentionScores[cardIndex] ?? 0) + 2;
          break;
        case 'medium':
          _cardRetentionScores[cardIndex] = (_cardRetentionScores[cardIndex] ?? 0) + 1;
          break;
        case 'hard':
          _cardRetentionScores[cardIndex] = (_cardRetentionScores[cardIndex] ?? 0) - 1;
          break;
      }
      
      // Update review count
      _cardReviewCounts[cardIndex] = (_cardReviewCounts[cardIndex] ?? 0) + 1;
      
      // Add card back to queue based on retention score
      _addCardToSpacedQueue(cardIndex);
      
      // Move to next card
      _nextSpacedRetentionCard();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as $difficulty'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addCardToSpacedQueue(int cardIndex) {
    final retentionScore = _cardRetentionScores[cardIndex] ?? 0;
    
    // Calculate when to show this card again based on retention score
    int delay;
    if (retentionScore >= 3) {
      delay = 5; // Show after 5 more cards (well retained)
    } else if (retentionScore >= 1) {
      delay = 3; // Show after 3 more cards (moderately retained)
    } else if (retentionScore >= -1) {
      delay = 2; // Show after 2 more cards (needs more practice)
    } else {
      delay = 1; // Show after 1 more card (difficult)
    }
    
    // Add card to queue at calculated position
    int insertPosition = delay < _spacedRetentionQueue.length ? delay : _spacedRetentionQueue.length;
    _spacedRetentionQueue.insert(insertPosition, cardIndex);
  }

  void _nextSpacedRetentionCard() {
    if (_spacedRetentionQueue.isNotEmpty) {
      setState(() {
        _currentCardIndex = _spacedRetentionQueue.removeAt(0);
        _currentSideIndex = _firstSideIndex;
      });
    } else {
      // All cards reviewed, reinitialize queue
      _initializeSpacedRetention();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cards reviewed! Starting new round.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetSpacedRetention() {
    setState(() {
      // Reset all retention scores and review counts
      for (int i = 0; i < widget.deck.cards.length; i++) {
        _cardRetentionScores[i] = 0;
        _cardReviewCounts[i] = 0;
      }
      // Reinitialize the queue
      _initializeSpacedRetention();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spaced retention progress reset'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<int> _getSpacedRetentionQueue() {
    return _spacedRetentionQueue;
  }

  double _getSpacedRetentionProgress() {
    if (widget.deck.cards.isEmpty) return 0.0;
    
    int totalReviews = _cardReviewCounts.values.fold(0, (sum, count) => sum + count);
    int targetReviews = widget.deck.cards.length * 3; // Target 3 reviews per card
    return (totalReviews / targetReviews).clamp(0.0, 1.0);
  }

  Color _getSpacedRetentionColor() {
    double progress = _getSpacedRetentionProgress();
    if (progress < 0.33) return Colors.red;
    if (progress < 0.67) return Colors.orange;
    return Colors.green;
  }

  String _getSpacedRetentionStatus() {
    final currentCardIndex = _currentCardIndex;
    final retentionScore = _cardRetentionScores[currentCardIndex] ?? 0;
    final reviewCount = _cardReviewCounts[currentCardIndex] ?? 0;
    final queueLength = _spacedRetentionQueue.length;
    
    String retentionLevel;
    if (retentionScore >= 3) {
      retentionLevel = 'Well Retained';
    } else if (retentionScore >= 1) {
      retentionLevel = 'Moderately Retained';
    } else if (retentionScore >= -1) {
      retentionLevel = 'Needs Practice';
    } else {
      retentionLevel = 'Difficult';
    }
    
    return 'Card $currentCardIndex: $retentionLevel (Reviewed $reviewCount times) • Queue: $queueLength cards';
  }

  // Audio Methods
  Future<void> _speakCurrentCard() async {
    if (widget.deck.cards.isEmpty) return;
    
    final currentCard = widget.deck.cards[_cardOrder[_currentCardIndex]];
    final textToSpeak = currentCard.sides[_currentSideIndex];
    
    if (textToSpeak.isNotEmpty) {
      setState(() {
        _isSpeaking = true;
      });
      
      try {
        final useAutoDetect = _selectedLanguage == 'auto';
        await _ttsService.speak(textToSpeak, useHighQuality: true, useAutoDetect: useAutoDetect);
      } catch (e) {
        // Fallback handling
      }
      
      // Update speaking state after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    }
  }

  String _getLanguageDisplayName() {
    if (_selectedLanguage == 'auto') {
      return '🤖';
    }
    
    final languageMap = {
      'en-US': 'EN',
      'es-ES': 'ES',
      'fr-FR': 'FR',
      'de-DE': 'DE',
      'it-IT': 'IT',
      'pt-PT': 'PT',
      'ru-RU': 'RU',
      'ja-JP': 'JA',
      'ko-KR': 'KO',
      'zh-CN': 'ZH',
      'ar-SA': 'AR',
      'hi-IN': 'HI',
      'th-TH': 'TH',
      'vi-VN': 'VI',
      'nl-NL': 'NL',
      'sv-SE': 'SV',
      'da-DK': 'DA',
      'no-NO': 'NO',
      'fi-FI': 'FI',
      'pl-PL': 'PL',
      'tr-TR': 'TR',
      'el-GR': 'EL',
      'he-IL': 'HE',
      'cs-CZ': 'CS',
      'hu-HU': 'HU',
      'ro-RO': 'RO',
      'bg-BG': 'BG',
      'hr-HR': 'HR',
      'sk-SK': 'SK',
      'sl-SI': 'SL',
      'et-EE': 'ET',
      'lv-LV': 'LV',
      'lt-LT': 'LT',
      'uk-UA': 'UK',
      'be-BY': 'BE',
      'mk-MK': 'MK',
      'sr-RS': 'SR',
      'mt-MT': 'MT',
      'is-IS': 'IS',
      'ga-IE': 'GA',
      'cy-GB': 'CY',
      'eu-ES': 'EU',
      'ca-ES': 'CA',
      'gl-ES': 'GL',
      'ast-ES': 'AST',
    };
    
    return languageMap[_selectedLanguage] ?? 'EN';
  }

  void _showLanguageSelector() async {
    final languages = [
      {'code': 'auto', 'name': '🤖 Auto-detect (Switch automatically)'},
      {'code': 'en-US', 'name': 'English (US)'},
      {'code': 'es-ES', 'name': 'Spanish (Spain)'},
      {'code': 'fr-FR', 'name': 'French (France)'},
      {'code': 'de-DE', 'name': 'German (Germany)'},
      {'code': 'it-IT', 'name': 'Italian (Italy)'},
      {'code': 'pt-PT', 'name': 'Portuguese (Portugal)'},
      {'code': 'pt-BR', 'name': 'Portuguese (Brazil)'},
      {'code': 'ru-RU', 'name': 'Russian (Russia)'},
      {'code': 'ja-JP', 'name': 'Japanese (Japan)'},
      {'code': 'ko-KR', 'name': 'Korean (South Korea)'},
      {'code': 'zh-CN', 'name': 'Chinese (China)'},
      {'code': 'zh-TW', 'name': 'Chinese (Taiwan)'},
      {'code': 'ar-SA', 'name': 'Arabic (Saudi Arabia)'},
      {'code': 'hi-IN', 'name': 'Hindi (India)'},
      {'code': 'th-TH', 'name': 'Thai (Thailand)'},
      {'code': 'vi-VN', 'name': 'Vietnamese (Vietnam)'},
      {'code': 'nl-NL', 'name': 'Dutch (Netherlands)'},
      {'code': 'sv-SE', 'name': 'Swedish (Sweden)'},
      {'code': 'da-DK', 'name': 'Danish (Denmark)'},
      {'code': 'no-NO', 'name': 'Norwegian (Norway)'},
      {'code': 'fi-FI', 'name': 'Finnish (Finland)'},
      {'code': 'pl-PL', 'name': 'Polish (Poland)'},
      {'code': 'tr-TR', 'name': 'Turkish (Turkey)'},
      {'code': 'el-GR', 'name': 'Greek (Greece)'},
      {'code': 'he-IL', 'name': 'Hebrew (Israel)'},
      {'code': 'cs-CZ', 'name': 'Czech (Czech Republic)'},
      {'code': 'hu-HU', 'name': 'Hungarian (Hungary)'},
      {'code': 'ro-RO', 'name': 'Romanian (Romania)'},
      {'code': 'bg-BG', 'name': 'Bulgarian (Bulgaria)'},
      {'code': 'hr-HR', 'name': 'Croatian (Croatia)'},
      {'code': 'sk-SK', 'name': 'Slovak (Slovakia)'},
      {'code': 'sl-SI', 'name': 'Slovenian (Slovenia)'},
      {'code': 'et-EE', 'name': 'Estonian (Estonia)'},
      {'code': 'lv-LV', 'name': 'Latvian (Latvia)'},
      {'code': 'lt-LT', 'name': 'Lithuanian (Lithuania)'},
      {'code': 'uk-UA', 'name': 'Ukrainian (Ukraine)'},
      {'code': 'be-BY', 'name': 'Belarusian (Belarus)'},
      {'code': 'mk-MK', 'name': 'Macedonian (North Macedonia)'},
      {'code': 'sr-RS', 'name': 'Serbian (Serbia)'},
      {'code': 'mt-MT', 'name': 'Maltese (Malta)'},
      {'code': 'is-IS', 'name': 'Icelandic (Iceland)'},
      {'code': 'ga-IE', 'name': 'Irish (Ireland)'},
      {'code': 'cy-GB', 'name': 'Welsh (United Kingdom)'},
      {'code': 'eu-ES', 'name': 'Basque (Spain)'},
      {'code': 'ca-ES', 'name': 'Catalan (Spain)'},
      {'code': 'gl-ES', 'name': 'Galician (Spain)'},
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              return RadioListTile<String>(
                title: Text(language['name']!),
                value: language['code']!,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (result != null && result != _selectedLanguage) {
      setState(() {
        _selectedLanguage = result;
      });
      
      // Update TTS language through enhanced service
      if (result != 'auto') {
        await _ttsService.setLanguage(result);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${languages.firstWhere((lang) => lang['code'] == result)['name']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
