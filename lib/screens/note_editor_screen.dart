import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String? initialContent;

  const NoteEditorScreen({super.key, this.note, this.initialContent});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isNewNote = true;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _currentSpeech = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.note != null) {
      _isNewNote = false;
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    } else if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _currentSpeech = result.recognizedWords;
              // Append the speech to the current content
              if (_currentSpeech.isNotEmpty) {
                final currentText = _contentController.text;
                final cursorPosition = _contentController.selection.baseOffset;
                
                if (cursorPosition >= 0) {
                  // Insert at cursor position
                  final newText = currentText.substring(0, cursorPosition) + 
                                _currentSpeech + 
                                currentText.substring(cursorPosition);
                  _contentController.text = newText;
                  _contentController.selection = TextSelection.collapsed(
                    offset: cursorPosition + _currentSpeech.length
                  );
                } else {
                  // Append to end
                  _contentController.text = currentText + _currentSpeech;
                }
                
                _currentSpeech = '';
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your note')),
      );
      return;
    }

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    if (_isNewNote) {
      notesProvider.addNote(title, content);
    } else {
      notesProvider.updateNote(widget.note!.id, title, content);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewNote ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
            color: _isListening ? Colors.red : null,
            onPressed: _startListening,
            tooltip: _isListening ? 'Stop recording' : 'Start voice input',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note title (optional)',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Start writing your note...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
