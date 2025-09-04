import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/voice_recognition_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final VoiceRecognitionService _voiceService = VoiceRecognitionService.instance;
  
  bool _isListening = false;
  bool _hasChanges = false;
  List<String> _tags = [];
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeEditor();
    _initializeVoiceRecognition();
  }

  void _initializeEditor() {
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _tags = List.from(widget.note!.tags);
      _tagsController.text = _tags.join(', ');
    }

    _titleController.addListener(() => setState(() => _hasChanges = true));
    _contentController.addListener(() => setState(() => _hasChanges = true));
    _tagsController.addListener(() {
      _tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      setState(() => _hasChanges = true);
    });
  }

  Future<void> _initializeVoiceRecognition() async {
    try {
      final isAvailable = await _voiceService.initialize();
      print('Voice recognition available: $isAvailable');
    } catch (e) {
      print('Error initializing voice recognition: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _saveNote() async {
    try {
      final content = _contentController.text.trim();
      final title = _titleController.text.trim();
      
      if (title.isEmpty && content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot save empty note')),
        );
        return;
      }

      final now = DateTime.now();
      
      if (widget.note != null) {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
          updatedAt: now,
          tags: _tags,
        );
        await DatabaseService.instance.updateNote(updatedNote);
      } else {
        // Create new note
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
          createdAt: now,
          updatedAt: now,
          tags: _tags,
        );
        await DatabaseService.instance.insertNote(newNote);
      }

      setState(() => _hasChanges = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  Future<void> _toggleVoiceRecognition() async {
    print('Toggle voice recognition called. Currently listening: $_isListening');
    
    // Try to initialize if not available
    if (!_voiceService.isAvailable) {
      print('Voice service not available, trying to initialize...');
      final initialized = await _voiceService.initialize();
      if (!initialized) {
        print('Voice service initialization failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice recognition not available. Please check microphone permissions.'),
            ),
          );
        }
        return;
      }
      print('Voice service initialized successfully');
    }

    if (_isListening) {
      print('Stopping voice recognition...');
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      print('Starting voice recognition...');
      setState(() => _isListening = true);
      
      await _voiceService.startListening(
        onResult: (text) {
          print('Voice recognition result: "$text"'); // Debug print
          if (text.isNotEmpty) {
            // Insert the recognized text at the current cursor position
            final currentText = _contentController.text;
            final selection = _contentController.selection;
            print('Current text: "$currentText"'); // Debug print
            print('Selection: ${selection.start}-${selection.end}'); // Debug print
            
            final newText = currentText.replaceRange(
              selection.start,
              selection.end,
              text + ' ', // Add space after voice input
            );
            
            print('New text: "$newText"'); // Debug print
            
            _contentController.value = _contentController.value.copyWith(
              text: newText,
              selection: TextSelection.collapsed(
                offset: selection.start + text.length + 1,
              ),
            );
          }
        },
      );
      
      // Auto-stop after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (_isListening) {
          print('Auto-stopping voice recognition after 30 seconds');
          _voiceService.stopListening();
          setState(() => _isListening = false);
        }
      });
    }
  }

  void _insertBoldText() {
    final selection = _contentController.selection;
    final selectedText = _contentController.text.substring(
      selection.start,
      selection.end,
    );
    final newText = selectedText.isEmpty ? '**bold text**' : '**$selectedText**';
    _replaceSelection(newText);
  }

  void _insertItalicText() {
    final selection = _contentController.selection;
    final selectedText = _contentController.text.substring(
      selection.start,
      selection.end,
    );
    final newText = selectedText.isEmpty ? '*italic text*' : '*$selectedText*';
    _replaceSelection(newText);
  }

  void _insertBulletPoint() {
    _replaceSelection('• ');
  }

  void _insertNumberedList() {
    _replaceSelection('1. ');
  }

  void _replaceSelection(String newText) {
    final currentText = _contentController.text;
    final selection = _contentController.selection;
    final updatedText = currentText.replaceRange(
      selection.start,
      selection.end,
      newText,
    );
    
    _contentController.value = _contentController.value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: selection.start + newText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note != null ? 'Edit Note' : 'New Note'),
          actions: [
            // Always show microphone icon - it will handle initialization when tapped
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : null,
              ),
              onPressed: _toggleVoiceRecognition,
              tooltip: _isListening ? 'Stop recording' : 'Start voice input',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: Column(
          children: [
            // Title input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: null,
              ),
            ),
            
            // Tags input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  hintText: 'Tags (comma separated)...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.label_outline),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            const Divider(),
            
            // Simple formatting toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold, size: 20),
                    onPressed: _insertBoldText,
                    tooltip: 'Bold',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic, size: 20),
                    onPressed: _insertItalicText,
                    tooltip: 'Italic',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted, size: 20),
                    onPressed: _insertBulletPoint,
                    tooltip: 'Bullet point',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered, size: 20),
                    onPressed: _insertNumberedList,
                    tooltip: 'Numbered list',
                  ),
                ],
              ),
            ),
            
            // Voice recognition status
            if (_isListening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red[50],
                child: Row(
                  children: [
                    Icon(Icons.mic, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Listening... Speak now',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _toggleVoiceRecognition,
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              ),
            
            // Content editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Start writing your note...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleVoiceRecognition,
          backgroundColor: _isListening ? Colors.red : null,
          child: Icon(
            _isListening ? Icons.stop : Icons.mic,
          ),
        ),
      ),
    );
  }
}
