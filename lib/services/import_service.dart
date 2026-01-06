import 'dart:async';
import 'dart:html' as html;
import '../models/flashcard_model.dart';

class ImportService {
  Future<Deck<String>?> importDeckFromCSV({bool firstRowHasHeaders = false}) async {
    final completer = Completer<Deck<String>?>();
    
    // Create file input
    final fileInput = html.document.createElement('input') as html.InputElement;
    fileInput.type = 'file';
    fileInput.accept = '.csv';
    
    fileInput.onChange.listen((e) {
      final files = fileInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        
        reader.onLoad.listen((event) {
          final csvString = reader.result as String;
          final deck = _createDeckFromCSV(csvString, file.name, firstRowHasHeaders);
          completer.complete(deck);
        });
        
        reader.readAsText(file);
      } else {
        completer.complete(null);
      }
    });
    
    fileInput.click();
    return await completer.future;
  }
  
  Deck<String> _createDeckFromCSV(String csvString, String fileName, bool firstRowHasHeaders) {
    final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final cards = <Flashcard<String>>[];
    List<String> headers = [];
    
    if (lines.isEmpty) {
      return Deck<String>(title: fileName, cards: cards);
    }
    
    // Extract headers if first row contains headers
    if (firstRowHasHeaders && lines.isNotEmpty) {
      headers = _parseCSVLine(lines.first);
      lines.removeAt(0); // Remove header row from data
    }
    
    // Create cards from remaining rows
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final values = _parseCSVLine(line);
        cards.add(Flashcard<String>(
          id: '$i',
          sides: values,
          category: 'Imported',
          headers: headers.isNotEmpty ? headers : null,
        ));
      }
    }
    
    return Deck<String>(
      title: fileName.replaceAll('.csv', ''),
      cards: cards,
      headers: headers.isNotEmpty ? headers : null,
    );
  }
  
  List<String> _parseCSVLine(String line) {
    final values = <String>[];
    String currentValue = '';
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote within quotes
          currentValue += '"';
          i++; // Skip the next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Comma separator outside quotes
        values.add(currentValue.trim());
        currentValue = '';
      } else {
        // Regular character
        currentValue += char;
      }
    }
    
    // Add the last value
    values.add(currentValue.trim());
    
    return values;
  }
}