import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/flashcard_model.dart';
import '../services/sound_service.dart';

class TypingGameScreen extends StatefulWidget {
  final Deck deck;

  const TypingGameScreen({super.key, required this.deck});

  @override
  State<TypingGameScreen> createState() => _TypingGameScreenState();
}

class _TypingGameScreenState extends State<TypingGameScreen> {
  late List<Flashcard> _gameCards;
  late List<Flashcard> _shuffledCards;
  int _currentCardIndex = 0;
  int _questionSideIndex = 0;
  int _answerSideIndex = 1;
  int _questionCount = 10;
  int _correctAnswers = 0;
  int _totalAttempts = 0;
  double _score = 0.0; // Track score with decimal points
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _gameStarted = false;
  bool _showResult = false;
  bool _showHint = false;
  bool _usedHintForCurrentQuestion = false; // Track hint usage for current question
  TextEditingController _textController = TextEditingController();
  String _correctAnswer = '';
  List<String> _hintChoices = [];

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _initializeSettings() {
    // Default to first two sides if available
    _questionSideIndex = 0;
    _answerSideIndex = widget.deck.cards.isNotEmpty && widget.deck.cards.first.sides.length > 1 ? 1 : 0;
    
    // Calculate maximum unique questions
    final Set<String> uniqueQuestions = {};
    for (final card in widget.deck.cards) {
      uniqueQuestions.add(card.sides[_questionSideIndex]);
    }
    
    // Set default question count based on unique questions
    final maxUniqueQuestions = uniqueQuestions.length;
    _questionCount = maxUniqueQuestions >= 10 ? 10 : maxUniqueQuestions;
  }

  void _startGame() {
    // Play game start sound
    SoundService().playGameStart();
    
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
      _textController.clear();
    });
    
    _generateGameCards();
    _startTimer();
    _generateQuestion();
  }

  void _generateGameCards() {
    final random = Random();
    
    // Group cards by question text to avoid ambiguity
    final Map<String, List<Flashcard>> questionGroups = {};
    for (final card in widget.deck.cards) {
      final questionText = card.sides[_questionSideIndex];
      if (!questionGroups.containsKey(questionText)) {
        questionGroups[questionText] = [];
      }
      questionGroups[questionText]!.add(card);
    }
    
    // Take only one card per question text to ensure unique questions
    final List<Flashcard> uniqueCards = [];
    for (final questionText in questionGroups.keys) {
      // Take the first card from each question group
      uniqueCards.add(questionGroups[questionText]!.first);
    }
    
    // Shuffle and take the requested number of cards
    uniqueCards.shuffle(random);
    _shuffledCards = uniqueCards;
    _gameCards = _shuffledCards.take(_questionCount).toList();
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
      // Play game over sound
      SoundService().playGameOver();
      
      _timer?.cancel();
      _showCompletionDialog();
      return;
    }

    final currentCard = _gameCards[_currentCardIndex];
    _correctAnswer = currentCard.sides[_answerSideIndex].toLowerCase().trim();

    // Generate hint choices (multiple choice options)
    _generateHintChoices();

    setState(() {
      _showResult = false;
      _showHint = false;
      _usedHintForCurrentQuestion = false; // Reset hint tracking for new question
      _textController.clear();
    });
  }

  void _generateHintChoices() {
    if (_gameCards.isEmpty || _currentCardIndex >= _gameCards.length) return;
    
    // Get all possible answers (unique)
    final Set<String> allAnswers = {};
    for (final card in widget.deck.cards) {
      allAnswers.add(card.sides[_answerSideIndex]);
    }

    // Remove correct answer from set temporarily (case-sensitive)
    final correctAnswerOriginal = _gameCards[_currentCardIndex].sides[_answerSideIndex];
    allAnswers.remove(correctAnswerOriginal);
    final List<String> wrongAnswers = allAnswers.toList();

    // Take 3 random wrong answers
    final random = Random();
    wrongAnswers.shuffle(random);
    final selectedWrongAnswers = wrongAnswers.take(3).toList();

    // Create choices list with correct answer (original case)
    _hintChoices = [correctAnswerOriginal, ...selectedWrongAnswers];
    _hintChoices.shuffle(random);
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
        // Add 1.0 point for correct answer without hint, 0.5 point with hint
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
    Future.delayed(const Duration(milliseconds: 2000), () {
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
      // Add 1.0 point for correct answer without hint, 0.5 point with hint
      if (_usedHintForCurrentQuestion) {
        _score += 0.5;
      } else {
        _score += 1.0;
      }
    });

    // Don't add auto-advance here since _submitAnswer already handles it
    // This prevents double auto-advance that was skipping questions
  }

  void _showHintOptions() {
    setState(() {
      _showHint = true;
      _usedHintForCurrentQuestion = true; // Mark that hint was used for this question
    });
  }

  void _selectHintAnswer(String answer) {
    setState(() {
      _textController.text = answer;
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentCardIndex++;
    });
    _generateQuestion();
  }

  void _resetGame() {
    _timer?.cancel();
    _startGame();
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int dialogQuestionSide = _questionSideIndex;
          int dialogAnswerSide = _answerSideIndex;
          int dialogQuestionCount = _questionCount;
          
          // Calculate unique questions for current side selection
          final Set<String> uniqueQuestions = {};
          for (final card in widget.deck.cards) {
            uniqueQuestions.add(card.sides[dialogQuestionSide]);
          }
          final maxUniqueQuestions = uniqueQuestions.length;
          
          return AlertDialog(
            title: const Text('Game Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose sides for question and answers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Question Side:', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<int>(
                            value: dialogQuestionSide,
                            isExpanded: true,
                            items: List.generate(
                              widget.deck.cards.first.sides.length,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text(_getSideHeader(index)),
                              ),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                dialogQuestionSide = value!;
                                // Recalculate unique questions when side changes
                                final Set<String> newUniqueQuestions = {};
                                for (final card in widget.deck.cards) {
                                  newUniqueQuestions.add(card.sides[dialogQuestionSide]);
                                }
                                final newMax = newUniqueQuestions.length;
                                if (dialogQuestionCount > newMax) {
                                  dialogQuestionCount = newMax >= 10 ? 10 : newMax;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Answer Side:', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<int>(
                            value: dialogAnswerSide,
                            isExpanded: true,
                            items: List.generate(
                              widget.deck.cards.first.sides.length,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text(_getSideHeader(index)),
                              ),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                dialogAnswerSide = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Number of questions: $dialogQuestionCount'),
                Text('Available unique questions: $maxUniqueQuestions', 
                     style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Slider(
                  value: dialogQuestionCount.toDouble(),
                  min: 5,
                  max: maxUniqueQuestions.toDouble(),
                  divisions: maxUniqueQuestions > 5 ? maxUniqueQuestions - 5 : 1,
                  label: '$dialogQuestionCount',
                  onChanged: (value) {
                    setDialogState(() {
                      dialogQuestionCount = value.round();
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _questionSideIndex = dialogQuestionSide;
                    _answerSideIndex = dialogAnswerSide;
                    _questionCount = dialogQuestionCount;
                  });
                  Navigator.pop(context);
                  _resetGame();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Typing Challenge Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You completed the typing challenge!'),
            const SizedBox(height: 16),
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
              Navigator.pop(context);
              Navigator.pop(context); // Go back to deck management
            },
            child: const Text('Back to Deck'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
      return _buildSettingsMenu();
    }
    
    return _buildGameScreen();
  }

  Widget _buildSettingsMenu() {
    // Calculate unique questions for current settings
    final Set<String> uniqueQuestions = {};
    for (final card in widget.deck.cards) {
      uniqueQuestions.add(card.sides[_questionSideIndex]);
    }
    final maxUniqueQuestions = uniqueQuestions.length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Typing Game - ${widget.deck.title}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Side selection
            const Text(
              'Choose sides for question and answers:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Question Side:', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<int>(
                            value: _questionSideIndex,
                            isExpanded: true,
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
                                // Recalculate max questions when side changes
                                final Set<String> newUniqueQuestions = {};
                                for (final card in widget.deck.cards) {
                                  newUniqueQuestions.add(card.sides[_questionSideIndex]);
                                }
                                final newMax = newUniqueQuestions.length;
                                if (_questionCount > newMax) {
                                  _questionCount = newMax >= 10 ? 10 : newMax;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Answer Side:', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<int>(
                            value: _answerSideIndex,
                            isExpanded: true,
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
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Number of questions
            const Text(
              'Number of questions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '$_questionCount questions',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Available unique questions: $maxUniqueQuestions', 
                         style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 5,
                      max: maxUniqueQuestions.toDouble(),
                      divisions: maxUniqueQuestions > 5 ? maxUniqueQuestions - 5 : 1,
                      label: '$_questionCount',
                      onChanged: (value) {
                        setState(() {
                          _questionCount = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  'Start Typing Challenge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    if (_currentCardIndex >= _gameCards.length || _gameCards.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentCard = _gameCards[_currentCardIndex];
    final question = currentCard.sides[_questionSideIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Typing Game - ${widget.deck.title}'),
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Game Settings',
          ),
          IconButton(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Game stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Question', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_currentCardIndex + 1}/$_questionCount', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                Column(
                  children: [
                    const Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_score.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                Column(
                  children: [
                    const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_formatTime(_secondsElapsed), style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ],
            ),
          ),
          
          // Question
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Type the answer:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Answer input and hints
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Result feedback
                  if (_showResult) ...[
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
                          Text(
                            _textController.text.toLowerCase().trim() == _correctAnswer
                                ? '✓ Correct!'
                                : '✗ Incorrect',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_textController.text.toLowerCase().trim() == _correctAnswer && _usedHintForCurrentQuestion)
                            const Text(
                              '(Hint used - 0.5 points)',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          if (_textController.text.toLowerCase().trim() != _correctAnswer)
                            Text(
                              'Correct answer: ${_gameCards[_currentCardIndex].sides[_answerSideIndex]}',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
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
                    const SizedBox(height: 16),
                  ],
                  
                  // Text input
                  TextField(
                    controller: _textController,
                    enabled: !_showResult,
                    decoration: InputDecoration(
                      hintText: 'Type your answer here...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 18),
                    onSubmitted: (_) => _submitAnswer(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showResult ? null : _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!_showResult && !_showHint)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showHintOptions,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text(
                              'Show Hint',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Hint choices
                  if (_showHint && !_showResult) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Choose an answer:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _hintChoices.length,
                        itemBuilder: (context, index) {
                          final choice = _hintChoices[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () {
                                _selectHintAnswer(choice);
                              },
                              child: Card(
                                child: InkWell(
                                  onTap: () {
                                    _selectHintAnswer(choice);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      choice,
                                      style: const TextStyle(fontSize: 16),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
