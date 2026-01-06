import 'package:flutter/material.dart';
import 'match_game_screen.dart';
import 'multiple_choice_game_screen.dart';
import 'typing_game_screen.dart';
import 'audio_typing_game_screen.dart';
import '../models/flashcard_model.dart';
import '../services/import_service.dart';
import 'deck_viewer_screen.dart';

class DeckManagementScreen extends StatefulWidget {
  final Deck deck;
  final Function(Deck)? onDeckUpdated;

  const DeckManagementScreen({super.key, required this.deck, this.onDeckUpdated});

  @override
  State<DeckManagementScreen> createState() => _DeckManagementScreenState();
}

class _DeckManagementScreenState extends State<DeckManagementScreen> {
  bool _allExpanded = false;
  List<bool> _expandedStates = [];
  bool _isSelectionMode = false;
  List<bool> _selectedCards = [];
  final ImportService _importService = ImportService();
  late Deck _currentDeck; // Local copy to track updates

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck; // Initialize local copy
    // Initialize expansion states for all cards
    _expandedStates = List.generate(
      _currentDeck.cards.length,
      (index) => false,
    );
    // Initialize selection states
    _selectedCards = List.generate(
      _currentDeck.cards.length,
      (index) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_getSelectedCount()} selected' 
            : 'Back to Main Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
            tooltip: 'Menu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Deck stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.deck.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _editDeckName,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Name & Headers'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_currentDeck.cards.length} cards',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Category: ${_currentDeck.cards.isNotEmpty ? _currentDeck.cards.first.category : "None"}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startStudyMode(),
                        icon: const Icon(Icons.school),
                        label: const Text('Study Mode'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startGameMode(),
                        icon: const Icon(Icons.games),
                        label: const Text('Game Mode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Expand/Collapse buttons (always visible when cards exist)
                if (_currentDeck.cards.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _expandAll,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Expand All'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _collapseAll,
                          icon: const Icon(Icons.expand_less),
                          label: const Text('Collapse All'),
                        ),
                      ),
                    ],
                  ),
                // Selection mode buttons
                if (_isSelectionMode)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _selectAll,
                              icon: const Icon(Icons.select_all),
                              label: const Text('Select All'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _getSelectedCount() > 0 ? _bulkEdit : null,
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _getSelectedCount() > 0 ? _bulkDelete : null,
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _exitSelectionMode,
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel Selection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Select Cards button (only when not in selection mode)
                if (_currentDeck.cards.isNotEmpty && !_isSelectionMode)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enterSelectionMode,
                      icon: const Icon(Icons.checklist),
                      label: const Text('Select Cards'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Cards list
          Expanded(
            child: _currentDeck.cards.isEmpty
                ? const Center(
                    child: Text('No cards in this deck'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Add padding for FAB
                    itemCount: _currentDeck.cards.length,
                    itemBuilder: (context, index) {
                      final card = _currentDeck.cards[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: _selectedCards[index],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCards[index] = value ?? false;
                                        });
                                      },
                                    )
                                  : null,
                              title: Text(
                                card.sides.isNotEmpty ? card.sides[0] : 'Empty Card',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('Card ${index + 1} • ${card.sides.length} sides'),
                              trailing: _isSelectionMode
                                  ? null
                                  : Icon(
                                      _expandedStates[index] ? Icons.expand_less : Icons.expand_more,
                                    ),
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    _selectedCards[index] = !_selectedCards[index];
                                  });
                                } else {
                                  setState(() {
                                    _expandedStates[index] = !_expandedStates[index];
                                  });
                                }
                              },
                            ),
                            if (_expandedStates[index])
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int i = 0; i < card.sides.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                '${_getSideHeader(i)}:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(card.sides[i]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _editCard(index),
                                          child: const Text('Edit'),
                                        ),
                                        TextButton(
                                          onPressed: () => _deleteCard(index),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _expandAll() {
    setState(() {
      _allExpanded = true;
      _expandedStates = List.generate(
        _currentDeck.cards.length,
        (index) => true,
      );
    });
  }

  void _collapseAll() {
    setState(() {
      _allExpanded = false;
      _expandedStates = List.generate(
        _currentDeck.cards.length,
        (index) => false,
      );
    });
  }

  void _showMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename Deck'),
          ),
        ),
        const PopupMenuItem(
          value: 'edit_structure',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Edit Headers & Sides'),
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('Export as CSV'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Deck', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'rename':
            _renameDeck();
            break;
          case 'edit_structure':
            _editDeckStructure();
            break;
          case 'export':
            _exportDeck();
            break;
          case 'delete':
            _deleteDeck();
            break;
        }
      }
    });
  }

  void _startStudyMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckViewerScreen(deck: widget.deck),
      ),
    );
  }

  void _startGameMode() {
    _showGameMenu();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Add Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_card),
            title: const Text('Add Single Card'),
            subtitle: const Text('Create a new flashcard manually'),
            onTap: () {
              Navigator.pop(context);
              _addNewCard();
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import CSV'),
            subtitle: const Text('Add cards from a CSV file'),
            onTap: () {
              Navigator.pop(context);
              _importCSV(addMode: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Replace Deck with CSV'),
            subtitle: const Text('Replace all cards with CSV import'),
            onTap: () {
              Navigator.pop(context);
              _importCSV(addMode: false);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _importCSV({required bool addMode}) async {
    try {
      // Show dialog to ask about headers
      bool? firstRowHasHeaders = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import CSV'),
          content: const Text('Does the first row of your CSV contain headers?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (firstRowHasHeaders == null) return; // User cancelled

      Deck? importedDeck = await _importService.importDeckFromCSV(
        firstRowHasHeaders: firstRowHasHeaders,
      );
      
      if (importedDeck != null && importedDeck.cards.isNotEmpty) {
        setState(() {
          if (addMode) {
            // Add cards to existing deck
            for (final card in importedDeck.cards) {
              _currentDeck.cards.add(card);
              _expandedStates.add(false);
              _selectedCards.add(false);
            }
          } else {
            // Replace entire deck
            _currentDeck.cards = importedDeck.cards;
            _expandedStates = List.generate(
              importedDeck.cards.length,
              (index) => false,
            );
            _selectedCards = List.generate(
              importedDeck.cards.length,
              (index) => false,
            );
          }
        });

        // Notify parent of deck update
        widget.onDeckUpdated?.call(_currentDeck);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addMode 
                  ? 'Successfully added ${importedDeck.cards.length} cards'
                  : 'Successfully replaced deck with ${importedDeck.cards.length} cards',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid cards found in CSV'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewCard() async {
  // Determine number of sides for new card (use current deck structure)
  int sideCount = 2; // Default
  if (_currentDeck.cards.isNotEmpty) {
    sideCount = _currentDeck.cards.first.sides.length;
  }
  
  final newCards = <Map<String, String>>[];
  
  while (true) {
    // Create text controllers for each side
    final controllers = List.generate(
      sideCount,
      (index) => TextEditingController(),
    );
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newCards.isEmpty ? 'Add Card 1' : 'Add Card ${newCards.length + 1}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200 + (sideCount * 60), // Dynamic height based on side count
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < sideCount; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: _getSideHeader(i),
                      border: const OutlineInputBorder(),
                      hintText: 'Enter ${_getSideHeader(i).toLowerCase()}',
                    ),
                    maxLines: 2,
                    textInputAction: i < sideCount - 1 
                        ? TextInputAction.next 
                        : TextInputAction.done,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (newCards.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, 'review'),
              child: const Text('Review & Add All'),
            ),
          ElevatedButton(
            onPressed: () {
              // Check if at least one side has content
              final hasContent = controllers.any((controller) => 
                  controller.text.trim().isNotEmpty);
              if (hasContent) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter content for at least one side'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text(newCards.isEmpty ? 'Add & Continue' : 'Add Final Card'),
          ),
        ],
      ),
    );
    
    if (result == null || result == false) {
      // User cancelled or closed dialog
      break;
    } else if (result == 'review') {
      // Show review dialog with all cards
      await _showReviewDialog(newCards);
      break; // Exit after review
    } else if (result == true) {
      // Add current card to the list
      final newSides = controllers.map((controller) => controller.text.trim()).toList();
      newCards.add({
        'id': '${DateTime.now().millisecondsSinceEpoch}_${newCards.length}',
        'sides': newSides.join('|'), // Store sides as pipe-separated string
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card ${newCards.length} added to queue'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // Dispose all controllers
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

Future<void> _showReviewDialog(List<Map<String, String>> cards) async {
  if (cards.isEmpty) return;
  
  final reviewControllers = cards.map((card) => 
    (card['sides'] as String).split('|').map((side) => TextEditingController(text: side)).toList()
  ).toList();
  
  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Review ${cards.length} Card${cards.length == 1 ? '' : 's'}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int cardIndex = 0; cardIndex < cards.length; cardIndex++)
                Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Card ${cardIndex + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Remove this card from the list
                                cards.removeAt(cardIndex);
                                reviewControllers.removeAt(cardIndex);
                                // Update the dialog content
                                Navigator.pop(context);
                                _showReviewDialog(cards);
                              },
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Delete Card',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (int sideIndex = 0; sideIndex < reviewControllers[cardIndex].length; sideIndex++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              controller: reviewControllers[cardIndex][sideIndex],
                              decoration: InputDecoration(
                                labelText: _getSideHeader(sideIndex),
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Add All Cards'),
        ),
      ],
    ),
  );
  
  // Dispose all review controllers
  for (final cardControllers in reviewControllers) {
    for (final controller in cardControllers) {
      controller.dispose();
    }
  }
  
  if (result == true) {
    // Add all cards to the deck
    setState(() {
      for (int i = 0; i < cards.length; i++) {
        final cardData = cards[i];
        final newCard = Flashcard<String>(
          id: cardData['id'] as String,
          sides: (cardData['sides'] as String).split('|'),
          category: _currentDeck.cards.isNotEmpty 
              ? _currentDeck.cards.first.category 
              : 'General',
          headers: _currentDeck.headers,
        );
        _currentDeck.cards.add(newCard);
        _expandedStates.add(false);
        _selectedCards.add(false);
      }
    });
    
    // Notify parent of deck update
    widget.onDeckUpdated?.call(_currentDeck);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully added ${cards.length} card${cards.length == 1 ? '' : 's'}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

void _editCard(int index) async {
  final card = _currentDeck.cards[index];
  final controllers = <TextEditingController>[];
  
  // Create controllers for each side
  for (int i = 0; i < card.sides.length; i++) {
    controllers.add(TextEditingController(text: card.sides[i]));
  }
  
  // Show edit dialog
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Card'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < controllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: _getSideHeader(i),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textInputAction: i < controllers.length - 1 
                      ? TextInputAction.next 
                      : TextInputAction.done,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  
  if (result == true) {
    final newSides = controllers.map((controller) => controller.text).toList();
    final updatedCard = Flashcard<String>(
      id: card.id,
      sides: newSides,
      category: card.category,
      headers: card.headers,
    );
    
    // Update deck
    setState(() {
      _currentDeck.cards[index] = updatedCard;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card updated successfully')),
    );
  }
  
  // Dispose controllers
  for (final controller in controllers) {
    controller.dispose();
  }
}

  void _deleteCard(int index) async {
    final card = _currentDeck.cards[index];
    
    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this card?'),
            const SizedBox(height: 16),
            Text(
              'Card ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (card.sides.isNotEmpty)
              Text(
                card.sides[0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // Remove card from deck
      setState(() {
        _currentDeck.cards.removeAt(index);
        _expandedStates.removeAt(index);
        _selectedCards.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSideHeader(int sideIndex) {
    // Use current deck headers if available, otherwise use default headers
    if (_currentDeck.headers != null && sideIndex < _currentDeck.headers!.length) {
      return _currentDeck.headers![sideIndex];
    }
    
    // Fallback to default headers
    final headers = ['Side 1', 'Side 2', 'Side 3', 'Side 4', 'Side 5'];
    if (sideIndex < headers.length) {
      return headers[sideIndex];
    }
    return 'Side ${sideIndex + 1}';
  }

  void _editDeckName() async {
    final currentSideCount = _currentDeck.cards.isNotEmpty 
        ? _currentDeck.cards.first.sides.length 
        : 2;
    
    // Create controllers for deck name and headers
    final nameController = TextEditingController(text: _currentDeck.title);
    final headerControllers = <TextEditingController>[];
    for (int i = 0; i < currentSideCount; i++) {
      final headerText = _currentDeck.headers != null && i < _currentDeck.headers!.length
          ? _currentDeck.headers![i]
          : _getSideHeader(i);
      headerControllers.add(TextEditingController(text: headerText));
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deck Name & Headers'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deck Name:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Deck Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Side Headers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(currentSideCount, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: headerControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Header ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.trim().isNotEmpty) {
      // Update headers
      final newHeaders = headerControllers.map((controller) => controller.text.trim()).toList();
      
      // Update all cards with new headers
      final updatedCards = _currentDeck.cards.map((card) {
        return Flashcard<String>(
          id: card.id,
          sides: List<String>.from(card.sides),
          category: card.category,
          headers: newHeaders,
        );
      }).toList();
      
      // Create new deck instance with updated name and headers
      final updatedDeck = Deck<String>(
        title: nameController.text.trim(),
        cards: updatedCards,
        headers: newHeaders,
      );
      
      setState(() {
        // Update local deck reference
        _currentDeck = updatedDeck;
      });
      
      // Notify parent widget of update
      widget.onDeckUpdated?.call(updatedDeck);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck name and headers updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // Dispose controllers
    nameController.dispose();
    for (final controller in headerControllers) {
      controller.dispose();
    }
  }

  void _editDeckStructure() async {
    final currentSideCount = _currentDeck.cards.isNotEmpty 
        ? _currentDeck.cards.first.sides.length 
        : 2;
    
    // Create controllers for headers
    final headerControllers = <TextEditingController>[];
    for (int i = 0; i < currentSideCount; i++) {
      final headerText = _currentDeck.headers != null && i < _currentDeck.headers!.length
          ? _currentDeck.headers![i]
          : _getSideHeader(i);
      headerControllers.add(TextEditingController(text: headerText));
    }
    
    int sideCount = currentSideCount;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Deck Structure'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Number of Sides: $sideCount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: sideCount > 2 ? () {
                          setState(() {
                            sideCount--;
                            headerControllers.removeLast();
                          });
                        } : null,
                        child: const Text('Remove Side'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: sideCount < 6 ? () {
                          setState(() {
                            sideCount++;
                            headerControllers.add(TextEditingController(text: _getSideHeader(sideCount - 1)));
                          });
                        } : null,
                        child: const Text('Add Side'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Side Headers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(sideCount, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: headerControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Header ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      // Update deck structure
      final newHeaders = headerControllers.map((controller) => controller.text.trim()).toList();
      
      // Update all cards to match the new side count
      final updatedCards = _currentDeck.cards.map((card) {
        final newSides = <String>[];
        for (int i = 0; i < sideCount; i++) {
          if (i < card.sides.length) {
            newSides.add(card.sides[i]);
          } else {
            newSides.add(''); // Add empty side for new sides
          }
        }
        return Flashcard<String>(
          id: card.id,
          sides: newSides,
          category: card.category,
          headers: newHeaders,
        );
      }).toList();
      
      // Create new deck instance with updated structure
      final updatedDeck = Deck<String>(
        title: _currentDeck.title,
        cards: updatedCards,
        headers: newHeaders,
      );
      
      setState(() {
        // Update local deck reference
        _currentDeck = updatedDeck;
        // Reinitialize expansion states for new card count
        _expandedStates = List.generate(
          updatedDeck.cards.length,
          (index) => false,
        );
        // Reinitialize selection states
        _selectedCards = List.generate(
          updatedDeck.cards.length,
          (index) => false,
        );
      });
      
      // Notify parent widget of the update
      widget.onDeckUpdated?.call(updatedDeck);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deck structure updated: $sideCount sides'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // Dispose controllers
    for (final controller in headerControllers) {
      controller.dispose();
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      // Reset all selections when entering selection mode
      for (int i = 0; i < _selectedCards.length; i++) {
        _selectedCards[i] = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      // Reset all selections when exiting selection mode
      for (int i = 0; i < _selectedCards.length; i++) {
        _selectedCards[i] = false;
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (int i = 0; i < _selectedCards.length; i++) {
        _selectedCards[i] = true;
      }
    });
  }

  void _bulkEdit() async {
    final selectedIndices = <int>[];
    for (int i = 0; i < _selectedCards.length; i++) {
      if (_selectedCards[i]) {
        selectedIndices.add(i);
      }
    }

    if (selectedIndices.isEmpty) return;

    // Get first selected card to determine side count
    final firstCard = _currentDeck.cards[selectedIndices.first];
    final sideCount = firstCard.sides.length;

    // Create controllers for each side of each selected card
    final allControllers = selectedIndices.map((index) {
      final card = _currentDeck.cards[index];
      return card.sides.map((side) => TextEditingController(text: side)).toList();
    }).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${selectedIndices.length} Card${selectedIndices.length == 1 ? '' : 's'}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int cardIndex = 0; cardIndex < selectedIndices.length; cardIndex++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card ${selectedIndices[cardIndex] + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (int sideIndex = 0; sideIndex < sideCount; sideIndex++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextField(
                                controller: allControllers[cardIndex][sideIndex],
                                decoration: InputDecoration(
                                  labelText: _getSideHeader(sideIndex),
                                  border: const OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save All'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        for (int i = 0; i < selectedIndices.length; i++) {
          final cardIndex = selectedIndices[i];
          final newSides = allControllers[i].map((controller) => controller.text).toList();
          final updatedCard = Flashcard<String>(
            id: _currentDeck.cards[cardIndex].id,
            sides: newSides,
            category: _currentDeck.cards[cardIndex].category,
            headers: _currentDeck.cards[cardIndex].headers,
          );
          _currentDeck.cards[cardIndex] = updatedCard;
        }
      });

      widget.onDeckUpdated?.call(_currentDeck);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated ${selectedIndices.length} card${selectedIndices.length == 1 ? '' : 's'}'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Dispose all controllers
    for (final cardControllers in allControllers) {
      for (final controller in cardControllers) {
        controller.dispose();
      }
    }
  }

  void _bulkDelete() async {
    final selectedIndices = <int>[];
    for (int i = 0; i < _selectedCards.length; i++) {
      if (_selectedCards[i]) {
        selectedIndices.add(i);
      }
    }

    if (selectedIndices.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selectedIndices.length} Card${selectedIndices.length == 1 ? '' : 's'}'),
        content: Text('Are you sure you want to delete ${selectedIndices.length} card${selectedIndices.length == 1 ? '' : 's'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        // Remove cards in reverse order to maintain correct indices
        for (int i = selectedIndices.length - 1; i >= 0; i--) {
          final index = selectedIndices[i];
          _currentDeck.cards.removeAt(index);
          _expandedStates.removeAt(index);
          _selectedCards.removeAt(index);
        }
      });

      widget.onDeckUpdated?.call(_currentDeck);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted ${selectedIndices.length} card${selectedIndices.length == 1 ? '' : 's'}'),
          backgroundColor: Colors.red,
        ),
      );

      _exitSelectionMode();
    }
  }

  int _getSelectedCount() {
    return _selectedCards.where((selected) => selected).length;
  }

  void _renameDeck() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rename deck feature coming soon!')),
    );
  }

  void _exportDeck() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export deck feature coming soon!')),
    );
  }

  void _deleteDeck() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete deck feature coming soon!')),
    );
  }

  void _showGameMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Game Mode - ${widget.deck.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Match Game'),
              subtitle: const Text('Match terms to their definitions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchGameScreen(deck: widget.deck),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Multiple Choice'),
              subtitle: const Text('Answer multiple choice questions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultipleChoiceGameScreen(deck: widget.deck),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text('Typing Game'),
              subtitle: const Text('Type the answers to questions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TypingGameScreen(deck: widget.deck),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.hearing),
              title: const Text('Audio Typing Game'),
              subtitle: const Text('Listen to audio and type what you hear'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioTypingGameScreen(deck: widget.deck),
                  ),
                );
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
  }
}
