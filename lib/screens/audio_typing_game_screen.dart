import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/flashcard_model.dart';
import '../services/enhanced_tts_service.dart';
import '../services/sound_service.dart';
import '../services/settings_service.dart';

class AudioTypingGameScreen extends StatefulWidget {
  final Deck deck;

  const AudioTypingGameScreen({super.key, required this.deck});

  @override
  State<AudioTypingGameScreen> createState() => _AudioTypingGameScreenState();
}

class _AudioTypingGameScreenState extends State<AudioTypingGameScreen> {
  int _currentCardIndex = 0;
  int _questionSideIndex = 0; // Which side is the question (audio)
  int _answerSideIndex = 1;   // Which side is the answer (typed)
  int _questionCount = 5;
  List<Flashcard> _gameCards = [];
  String _correctAnswer = '';
  bool _gameStarted = false;
  bool _showResult = false;
  bool _showHint = false;
  bool _usedHintForCurrentQuestion = false;
  TextEditingController _textController = TextEditingController();
  List<String> _hintChoices = [];
  
  // Audio functionality
  final EnhancedTTSService _ttsService = EnhancedTTSService();
  bool _isSpeaking = false;
  String _selectedLanguage = 'en-US';
  bool _hasPlayedAudio = false;

  // Scoring
  int _correctAnswers = 0;
  int _totalAttempts = 0;
  double _score = 0.0;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _initializeGameSettings();
  }

  @override
  void dispose() {
    _ttsService.stop();
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _initializeGameSettings() {
    if (widget.deck.cards.isNotEmpty) {
      // Default to first side as question, second as answer
      _questionSideIndex = 0;
      _answerSideIndex = 1;
      
      // If deck has only one side, use it for both
      if (widget.deck.cards.first.sides.length == 1) {
        _answerSideIndex = 0;
      }
    }
  }

  Future<void> _playQuestionAudio() async {
    if (_gameCards.isEmpty || _currentCardIndex >= _gameCards.length) return;
    
    final questionText = _gameCards[_currentCardIndex].sides[_questionSideIndex];
    if (questionText.isNotEmpty) {
      setState(() {
        _hasPlayedAudio = true;
        _isSpeaking = true;
      });
      
      try {
        await _ttsService.speak(questionText, useHighQuality: true);
      } catch (e) {
        // Fallback handling
      }
      
      // Check if speaking is done after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    }
  }

  void _startGame() {
    // Play game start sound
    SoundService().playGameStart();
    
    // Create unique cards (no duplicate questions)
    final Map<String, Flashcard> uniqueCards = {};
    for (final card in widget.deck.cards) {
      final question = card.sides[_questionSideIndex];
      if (!uniqueCards.containsKey(question)) {
        uniqueCards[question] = card;
      }
    }
    
    _gameCards = uniqueCards.values.toList();
    _gameCards.shuffle();
    
    // Limit question count to available unique cards
    final maxQuestions = _gameCards.length;
    if (_questionCount > maxQuestions) {
      _questionCount = maxQuestions;
    }
    _gameCards = _gameCards.take(_questionCount).toList();

    setState(() {
      _gameStarted = true;
      _currentCardIndex = 0;
      _correctAnswers = 0;
      _totalAttempts = 0;
      _score = 0.0;
      _secondsElapsed = 0;
      _showResult = false;
      _showHint = false;
      _usedHintForCurrentQuestion = false;
      _hasPlayedAudio = false;
      _textController.clear();
    });

    _generateQuestion();
    _startTimer();
    // Auto-play audio for first question
    Future.delayed(const Duration(milliseconds: 500), () {
      _playQuestionAudio();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _generateQuestion() {
    if (_currentCardIndex >= _gameCards.length) {
      _endGame();
      return;
    }

    final currentCard = _gameCards[_currentCardIndex];
    _correctAnswer = currentCard.sides[_answerSideIndex].toLowerCase().trim();

    setState(() {
      _showResult = false;
      _showHint = false;
      _usedHintForCurrentQuestion = false;
      _hasPlayedAudio = false;
      _textController.clear();
    });

    // Auto-play audio for new question
    Future.delayed(const Duration(milliseconds: 500), () {
      _playQuestionAudio();
    });
  }

  void _submitAnswer() {
    if (_showResult) return;

    final userAnswer = _textController.text.toLowerCase().trim();
    
    setState(() {
      _showResult = true;
      _totalAttempts++;

      if (userAnswer == _correctAnswer) {
        // Play correct sound
        SoundService().playCorrect();
        
        _correctAnswers++;
        if (_usedHintForCurrentQuestion) {
          _score += 0.5;
        } else {
          _score += 1.0;
        }
      } else {
        // Play error sound
        SoundService().playError();
      }
    });

    // Auto-advance to next question after delay
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _markAsCorrect() {
    setState(() {
      _showResult = true;
      _totalAttempts++;
      _correctAnswers++;
      if (_usedHintForCurrentQuestion) {
        _score += 0.5;
      } else {
        _score += 1.0;
      }
    });

    // Auto-advance to next question after delay
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentCardIndex++;
    });
    _generateQuestion();
  }

  void _showHintOptions() {
    setState(() {
      _showHint = true;
      _usedHintForCurrentQuestion = true;
    });
    _generateHintChoices();
  }

  void _generateHintChoices() {
    if (_gameCards.isEmpty || _currentCardIndex >= _gameCards.length) return;
    
    final Set<String> allAnswers = {};
    for (final card in widget.deck.cards) {
      allAnswers.add(card.sides[_answerSideIndex]);
    }

    final correctAnswerOriginal = _gameCards[_currentCardIndex].sides[_answerSideIndex];
    allAnswers.remove(correctAnswerOriginal);
    final List<String> wrongAnswers = allAnswers.toList();

    final random = Random();
    wrongAnswers.shuffle(random);
    final selectedWrongAnswers = wrongAnswers.take(3).toList();

    _hintChoices = [correctAnswerOriginal, ...selectedWrongAnswers];
    _hintChoices.shuffle(random);
  }

  void _selectHintAnswer(String answer) {
    setState(() {
      _textController.text = answer;
    });
  }

  void _endGame() {
    // Play game over sound
    SoundService().playGameOver();
    
    _timer?.cancel();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: ${_score.toStringAsFixed(1)} out of $_questionCount'),
            Text('Correct Answers: $_correctAnswers/$_questionCount'),
            Text('Accuracy: ${((_correctAnswers / _totalAttempts) * 100).toStringAsFixed(1)}%'),
            Text('Time: ${_formatTime(_secondsElapsed)}'),
            const SizedBox(height: 8),
            const Text(
              'Hint Usage: 0.5 points for answers with hints',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _gameStarted = false;
                _secondsElapsed = 0;
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getSideHeader(int index) {
    if (widget.deck.headers != null && index < widget.deck.headers!.length) {
      return widget.deck.headers![index];
    }
    return 'Side ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Audio Typing Game'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hearing,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Audio Typing Game',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Listen to the audio and type what you hear. Perfect for pronunciation practice!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (widget.deck.cards.isNotEmpty && widget.deck.cards.first.sides.length > 1)
                Column(
                  children: [
                    const Text(
                      'Question Side:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: _questionSideIndex,
                      items: List.generate(
                        widget.deck.cards.first.sides.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(_getSideHeader(index)),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _questionSideIndex = value!;
                          if (_questionSideIndex == _answerSideIndex) {
                            _answerSideIndex = (_answerSideIndex + 1) % widget.deck.cards.first.sides.length;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Answer Side:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: _answerSideIndex,
                      items: List.generate(
                        widget.deck.cards.first.sides.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(_getSideHeader(index)),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _answerSideIndex = value!;
                          if (_answerSideIndex == _questionSideIndex) {
                            _questionSideIndex = (_questionSideIndex + 1) % widget.deck.cards.first.sides.length;
                          }
                        });
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              Text(
                'Number of Questions: $_questionCount',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: _questionCount.toDouble(),
                min: 1,
                max: widget.deck.cards.length.toDouble(),
                divisions: widget.deck.cards.length > 1 ? widget.deck.cards.length - 1 : 1,
                label: '$_questionCount questions',
                onChanged: (value) {
                  setState(() {
                    _questionCount = value.round();
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Start Game', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    if (_gameCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Audio Typing Game'),
        ),
        body: const Center(
          child: Text('No cards available for this game'),
        ),
      );
    }

    if (_currentCardIndex >= _gameCards.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentCard = _gameCards[_currentCardIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Typing Game'),
        actions: [
          IconButton(
            onPressed: () {
              SettingsService.toggleSoundsEnabled();
              setState(() {}); // Rebuild to reflect changes
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(SettingsService.soundsEnabled ? 'Sounds enabled' : 'Sounds muted'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(SettingsService.soundsEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: SettingsService.soundsEnabled ? 'Mute Sounds' : 'Enable Sounds',
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 4),
                Text(_formatTime(_secondsElapsed)),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 20),
                const SizedBox(width: 4),
                Text(_score.toStringAsFixed(1)),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentCardIndex + 1) / _gameCards.length,
            ),
            
            // Question counter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Question ${_currentCardIndex + 1} of $_questionCount',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            
            // Audio question area
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Listen to the audio:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _isSpeaking ? null : _playQuestionAudio,
                          icon: Icon(
                            _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Play audio',
                        ),
                        const SizedBox(width: 16),
                        if (!_hasPlayedAudio)
                          Column(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 24,
                                color: Colors.orange,
                              ),
                              const Text(
                                'Auto-play',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSpeaking ? 'Speaking...' : 'Tap to play audio',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Answer input area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Type your answer',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _textController.clear();
                    },
                  ),
                ),
                onSubmitted: (_) => _submitAnswer(),
                autofocus: true,
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!_showResult)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitAnswer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text('Submit Answer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _showHintOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Show Hint'),
                        ),
                      ],
                    ),
                  
                  if (_showResult)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _textController.text.toLowerCase().trim() == _correctAnswer
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _textController.text.toLowerCase().trim() == _correctAnswer
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _textController.text.toLowerCase().trim() == _correctAnswer
                                      ? 'Correct!'
                                      : 'Incorrect',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct answer: ${currentCard.sides[_answerSideIndex]}',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          if (_textController.text.toLowerCase().trim() == _correctAnswer && _usedHintForCurrentQuestion)
                            const Text(
                              '(Hint used - 0.5 points)',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          if (_textController.text.toLowerCase().trim() != _correctAnswer)
                            const SizedBox(height: 12),
                          if (_textController.text.toLowerCase().trim() != _correctAnswer)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _markAsCorrect,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.all(12),
                                ),
                                child: const Text(
                                  'This is correct',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  if (_showHint)
                    Container(
                      height: 260,
                      margin: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose an answer:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _hintChoices.length,
                              itemBuilder: (context, index) {
                                final choice = _hintChoices[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    elevation: 2,
                                    child: InkWell(
                                      onTap: () {
                                        _selectHintAnswer(choice);
                                      },
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Center(
                                          child: Text(
                                            choice,
                                            style: const TextStyle(fontSize: 13),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
