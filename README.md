# Notes App - Notion-like with Voice Recognition

A powerful note-taking application built with Flutter that combines the functionality of Notion with seamless voice recognition capabilities.

## Features

### 📝 Rich Note-Taking
- **Clean Interface**: Notion-inspired design with intuitive navigation
- **Title & Content**: Separate title and content areas for better organization
- **Tags Support**: Add comma-separated tags to categorize your notes
- **Basic Formatting**: Bold, italic, bullet points, and numbered lists
- **Auto-save**: Automatic saving with confirmation prompts

### 🎤 Voice Recognition
- **Real-time Speech-to-Text**: Convert speech to text in real-time
- **Voice Input Button**: Dedicated floating action button for voice input
- **Visual Feedback**: Clear indicators when listening for voice input
- **Auto-stop**: Automatically stops listening after 30 seconds
- **Multiple Languages**: Support for various languages (English, Spanish, French, German)

### 🔍 Search & Organization
- **Global Search**: Search across all notes with instant results
- **Tag-based Organization**: Filter and organize notes using tags
- **Chronological Sorting**: Notes sorted by last modified date
- **Search Delegate**: Dedicated search interface for better discovery

### 💾 Data Management
- **Local Database**: SQLite database for reliable local storage
- **CRUD Operations**: Create, read, update, and delete notes
- **Data Persistence**: All notes saved locally on device
- **Backup Ready**: Database structure ready for cloud backup integration

### 🎨 User Experience
- **Material Design**: Modern Material Design 3 principles
- **Responsive Layout**: Optimized for various screen sizes
- **Smooth Animations**: Fluid transitions and interactions
- **Dark/Light Theme**: Automatic theme adaptation
- **Pull to Refresh**: Refresh notes list with pull gesture

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Physical device or emulator with microphone

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

### Usage

#### Creating Notes
1. Tap the '+' button to create a new note
2. Enter a title (optional)
3. Add tags for organization (optional)
4. Write content using the text editor
5. Use formatting buttons for rich text
6. Tap save or navigate back to auto-save

#### Voice Input
1. Tap the microphone button (floating or in app bar)
2. Grant microphone permission when prompted
3. Speak clearly into the device
4. Voice input will be converted to text automatically
5. Tap stop or wait for auto-stop

#### Searching Notes
1. Use the search bar on the home screen
2. Or tap the search icon for dedicated search
3. Search matches both titles and content
4. Results update in real-time

## Project Structure

```
lib/
├── main.dart                    # App entry point and theme
├── models/
│   └── note.dart               # Note data model
├── services/
│   ├── database_service.dart   # SQLite database operations
│   └── voice_recognition_service.dart # Speech-to-text functionality
└── screens/
    ├── home_screen.dart        # Main notes list and search
    └── note_editor_screen.dart # Note creation and editing
```
