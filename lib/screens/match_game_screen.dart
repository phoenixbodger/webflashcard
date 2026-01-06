import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/flashcard_model.dart';
import '../services/sound_service.dart';

class MatchGameScreen extends StatefulWidget {
  final Deck deck;

  const MatchGameScreen({super.key, required this.deck});

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  late List<MatchCard> _cards;
  late List<MatchCard> _selectedCards;
  int _matchesFound = 0;
  int _attempts = 0;
  int _side1Index = 0;
  int _side2Index = 1;
  int _pairCount = 10;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeSettings() {
    // Default to first two sides if available
    _side1Index = 0;
    _side2Index = widget.deck.cards.isNotEmpty && widget.deck.cards.first.sides.length > 1 ? 1 : 0;
    
    // Set default pair count to minimum of 5 or deck length, but allow slider to go up to deck length
    _pairCount = widget.deck.cards.length >= 5 ? 5 : widget.deck.cards.length;
  }

  void _generateCards() {
    final random = Random();
    final selectedCardIndices = List<int>.generate(widget.deck.cards.length, (i) => i);
    selectedCardIndices.shuffle(random);
    
    // Take only the number of pairs we need
    final gameCardIndices = selectedCardIndices.take(_pairCount).toList();
    
    _cards = [];
    
    // Create pairs of cards (term and definition)
    for (int i = 0; i < gameCardIndices.length; i++) {
      final cardIndex = gameCardIndices[i];
      final card = widget.deck.cards[cardIndex];
      
      // Create term card
      _cards.add(MatchCard(
        id: 'term_$i',
        text: card.sides[_side1Index],
        pairId: i,
        isTerm: true,
      ));
      
      // Create definition card
      _cards.add(MatchCard(
        id: 'def_$i',
        text: card.sides[_side2Index],
        pairId: i,
        isTerm: false,
      ));
    }
    
    // Shuffle all cards
    _cards.shuffle(random);
    _selectedCards = [];
    _matchesFound = 0;
    _attempts = 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _onCardTap(MatchCard card) {
    if (_selectedCards.length >= 2) return;
    if (_selectedCards.contains(card)) return;
    if (card.isMatched) return;

    setState(() {
      card.isFlipped = true;
      _selectedCards.add(card);
    });

    if (_selectedCards.length == 2) {
      _attempts++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final card1 = _selectedCards[0];
    final card2 = _selectedCards[1];

    if (card1.pairId == card2.pairId && card1.isTerm != card2.isTerm) {
      // Match found!
      // Play correct sound
      SoundService().playCorrect();
      
      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;
        _matchesFound++;
        _selectedCards.clear();
      });

      // Check if game is complete
      if (_matchesFound == _pairCount) {
        // Play game over sound
        SoundService().playGameOver();
        
        _timer?.cancel();
        _showCompletionDialog();
      }
    } else {
      // No match - play error sound
      SoundService().playError();
      
      // Flip cards back after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          card1.isFlipped = false;
          card2.isFlipped = false;
          _selectedCards.clear();
        });
      });
    }
  }

  void _resetGame() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _generateCards();
    _startTimer();
  }

  void _showSettings() {
    int dialogPairCount = _pairCount; // Separate variable for dialog
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Create temporary variables for the dialog
          int tempSide1 = _side1Index;
          int tempSide2 = _side2Index;
          
          return AlertDialog(
            title: const Text('Game Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Side selection for matching
                if (widget.deck.cards.first.sides.length > 2) ...[
                  const Text(
                    'Choose sides to match:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: tempSide1,
                          items: List.generate(
                            widget.deck.cards.first.sides.length,
                            (index) => DropdownMenuItem(
                              value: index,
                              child: Text(_getSideHeader(index)),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              tempSide1 = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('↔'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<int>(
                          value: tempSide2,
                          items: List.generate(
                            widget.deck.cards.first.sides.length,
                            (index) => DropdownMenuItem(
                              value: index,
                              child: Text(_getSideHeader(index)),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              tempSide2 = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Number of pairs: $dialogPairCount'),
                Slider(
                  value: dialogPairCount.toDouble(),
                  min: 2,
                  max: widget.deck.cards.length.toDouble(),
                  divisions: widget.deck.cards.length > 2 ? widget.deck.cards.length - 1 : 1,
                  label: '$dialogPairCount',
                  onChanged: (value) {
                    setDialogState(() {
                      dialogPairCount = value.round();
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
                    _side1Index = tempSide1;
                    _side2Index = tempSide2;
                    _pairCount = dialogPairCount;
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
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You completed the match game!'),
            const SizedBox(height: 16),
            Text('Time: ${_formatTime(_secondsElapsed)}'),
            Text('Attempts: $_attempts'),
            if (_attempts > 0)
              Text('Accuracy: ${((_pairCount / _attempts) * 100).toStringAsFixed(1)}%'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Game - ${widget.deck.title}'),
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
            
            // Side selection for matching
            if (widget.deck.cards.first.sides.length > 2) ...[
              const Text(
                'Choose sides to match:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButton<int>(
                          value: _side1Index,
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
                              _side1Index = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('↔', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButton<int>(
                          value: _side2Index,
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
                              _side2Index = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            
            // Number of pairs
            const Text(
              'Number of pairs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '$_pairCount pairs',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _pairCount.toDouble(),
                      min: 2,
                      max: widget.deck.cards.length.toDouble(),
                      divisions: widget.deck.cards.length > 2 ? widget.deck.cards.length - 1 : 1,
                      label: '$_pairCount',
                      onChanged: (value) {
                        setState(() {
                          _pairCount = value.round();
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
                  'Start Game',
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Game - ${widget.deck.title}'),
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
                    const Text('Matches', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_matchesFound/$_pairCount', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                Column(
                  children: [
                    const Text('Attempts', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_attempts', style: Theme.of(context).textTheme.headlineSmall),
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
          // Game board
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.2,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return MatchCardWidget(
                    card: card,
                    onTap: () => _onCardTap(card),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    // Play game start sound
    SoundService().playGameStart();
    
    setState(() {
      _gameStarted = true;
    });
    _generateCards();
    _startTimer();
  }
}

class MatchCard {
  final String id;
  final String text;
  final int pairId;
  final bool isTerm;
  
  bool isFlipped = false;
  bool isMatched = false;

  MatchCard({
    required this.id,
    required this.text,
    required this.pairId,
    required this.isTerm,
  });
}

class MatchCardWidget extends StatelessWidget {
  final MatchCard card;
  final VoidCallback onTap;

  const MatchCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.isMatched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green
              : card.isFlipped
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatched
                ? Colors.green
                : card.isFlipped
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
            width: 2,
          ),
        ),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: card.isFlipped || card.isMatched
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    child: Text(
                      card.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: card.isMatched
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              : Icon(
                  Icons.help_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}
