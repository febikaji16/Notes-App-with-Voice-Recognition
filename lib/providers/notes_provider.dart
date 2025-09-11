import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': jsonEncode(tags),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'tags': tags,
    };
  }

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
    );
  }
}

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local database
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'updatedAt DESC');

      _notes = List.generate(maps.length, (i) {
        return Note.fromMap(maps[i]);
      });

      // Also sync with Firestore if user is logged in
      // This would be handled in a more complete implementation
    } catch (e) {
      // Error loading notes
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _notes.insert(0, note);
    notifyListeners();

    try {
      final db = await database;
      await db.insert('notes', note.toMap());

      // Sync to Firestore
      await _firestore.collection('notes').doc(note.id).set(note.toFirestore());
    } catch (e) {
      // Error adding note
    }
  }

  Future<void> updateNote(String id, String title, String content) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      final updatedNote = Note(
        id: id,
        title: title,
        content: content,
        createdAt: _notes[index].createdAt,
        updatedAt: DateTime.now(),
      );

      _notes[index] = updatedNote;
      notifyListeners();

      try {
        final db = await database;
        await db.update(
          'notes',
          updatedNote.toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );

        // Sync to Firestore
        await _firestore.collection('notes').doc(id).update(updatedNote.toFirestore());
      } catch (e) {
        // Error updating note
      }
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();

    try {
      final db = await database;
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);

      // Delete from Firestore
      await _firestore.collection('notes').doc(id).delete();
    } catch (e) {
      // Error deleting note
    }
  }
}
