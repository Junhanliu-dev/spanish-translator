# LinguaViaje

A food translation app for travelers in Spain and Basque Country. Translate menu items between Spanish, Basque, and English using text, speech, or camera — and hear pronunciations with text-to-speech.

## Features

- **Text Translation** — Type a word or phrase to translate
- **Speech Translation** — Speak and get instant translations
- **Photo Translation** — Snap a photo of a menu for OCR-based translation
- **Text-to-Speech** — Listen to pronunciations in Spanish and Basque
- **History** — Browse past translations offline
- **Discover** — Explore common food vocabulary

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)
- An [OpenAI API key](https://platform.openai.com/api-keys)

## Getting Started

```bash
# Clone the repo
git clone https://github.com/Junhanliu-dev/spanish-translator.git
cd spanish-translator

# Install dependencies
flutter pub get

# Create a .env file with your OpenAI key
echo "OPENAI_API_KEY=your-key-here" > .env

# Run the app
flutter run
```

The app will prompt you to enter your API key on first launch if `.env` is not set.

## Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
├── core/          # Router, API client, storage, theme
├── features/      # Feature modules
│   ├── discover/  # Food vocabulary explorer
│   ├── history/   # Translation history
│   ├── home/      # Home screen
│   ├── onboarding/# API key setup
│   ├── photo/     # Camera/OCR translation
│   ├── settings/  # App settings
│   ├── speech/    # Voice translation
│   └── text/      # Text translation
├── shared/        # Shared widgets and utilities
├── app.dart       # App widget
└── main.dart      # Entry point
```
