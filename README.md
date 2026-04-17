# LinguaViaje 🥘✈️

> **Travel Spain fearlessly — order with confidence, eat with curiosity.**

LinguaViaje is an open‑source Flutter app that helps travelers decode menus and conversations across **Spanish, Basque (Euskara), and English**. Snap a photo of a menu, speak into your phone, or paste text — LinguaViaje translates it instantly and even pronounces it back in a native voice so you can order like a local.

Built with a clean, modular architecture and powered by the OpenAI API (GPT‑4o, Whisper, TTS), it's a great starting point if you want to learn Flutter, build a travel companion, or fork it into your own language project.

If this project helps you, please ⭐ **star the repo** — it really does make a difference!

---

## ✨ Features

- 📝 **Text Translation** — Paste or type any word, phrase, or full menu item and get an accurate translation with a short cultural/ingredient description.
- 🎙️ **Speech Translation** — Hold to record, auto‑detect the spoken language, and get an instant written + spoken translation.
- 📸 **Photo Menu Translation** — Snap a menu (single page or **multi‑page** for long tasting menus), OCR extracts every dish, and each one is translated side‑by‑side.
- 🧾 **Menu Order Builder** — Tap dishes from a scanned menu to build your order, then translate *and* play the order back out loud to the waiter.
- 🔊 **Native Text‑to‑Speech** — Hear Spanish and Basque pronunciations with natural TTS voices.
- 📚 **History** — All translations are saved locally and browsable offline.
- 🌮 **Discover** — Explore curated food vocabulary (tapas, pintxos, Basque specialties) to learn before you go.
- 🌓 **Light & Dark Themes** — Clean Material 3 UI with Google Fonts styling.
- 🔐 **Private by default** — Your API key is stored in the device's secure storage; translations stay on your phone.

---

## 📱 Screenshots

> Add screenshots or a short GIF here once you run the app — it makes the README pop on GitHub!

---

## 🧱 Tech Stack

| Layer | Tools |
|---|---|
| Framework | Flutter 3.11+ / Dart |
| Navigation | `go_router` |
| Networking | `dio` |
| AI / Translation | OpenAI GPT‑4o (translation), Whisper (speech‑to‑text), TTS‑1 (text‑to‑speech) |
| Audio | `record`, `audioplayers` |
| Camera | `image_picker`, `image` |
| Storage | `sqflite` (history), `shared_preferences` (settings), `flutter_secure_storage` (API key) |
| UI | Material 3, `google_fonts`, `flutter_animate` |
| Testing | `flutter_test`, `mocktail` — 120+ unit tests |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.11 or newer**
- An [OpenAI API key](https://platform.openai.com/api-keys)
- An iOS Simulator, Android Emulator, or a physical device

### 1. Clone & install

```bash
git clone https://github.com/Junhanliu-dev/spanish-translator.git
cd spanish-translator
flutter pub get
```

### 2. Run the app

You have two options for providing your OpenAI key:

**Option A — Enter it in the app (easiest):**

```bash
flutter run
```

On first launch the onboarding screen will ask for your OpenAI key and store it securely on‑device.

**Option B — Inject at build time (best for CI / dev):**

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

> ⚠️ **Do not** commit a `.env` file with your key. LinguaViaje uses `--dart-define` and secure on‑device storage so your key is never bundled into the app binary.

### 3. Build a release

```bash
# Android
flutter build apk --release --dart-define=OPENAI_API_KEY=sk-...

# iOS
flutter build ios --release --dart-define=OPENAI_API_KEY=sk-...
```

---

## 🧪 Running Tests

```bash
flutter test
```

The project ships with 120+ unit tests across view‑models, repositories, and API clients using `mocktail`.

To lint:

```bash
dart analyze
```

---

## 🗂️ Project Structure

LinguaViaje follows a **feature‑first + layered** architecture. Each feature owns its view‑model and presentation layer; cross‑cutting concerns live in `core/` and `shared/`.

```
lib/
├── main.dart                    # App entry: boots services, seeds key, builds router
├── app.dart                     # Root widget: MaterialApp.router + theming
│
├── core/                        # Framework-agnostic infrastructure
│   ├── api/                     # OpenAIClient + endpoint/model constants
│   ├── connectivity/            # Online/offline detection
│   ├── error/                   # Typed errors and mappers
│   ├── router/                  # go_router configuration
│   ├── storage/                 # SQLite history, secure storage, settings
│   ├── theme/                   # Material 3 light/dark themes
│   └── service_locator.dart     # Lightweight DI container
│
├── features/                    # One folder per user-facing capability
│   ├── onboarding/              # First-run API key setup
│   ├── home/                    # Home dashboard
│   ├── text/                    # Text translation
│   ├── speech/                  # Voice translation (Whisper + GPT-4o)
│   ├── photo/                   # Menu OCR + multi-page scan + order builder
│   ├── history/                 # Translation history browser
│   ├── discover/                # Food vocabulary explorer
│   └── settings/                # Theme, language prefs, API key mgmt
│
└── shared/                      # Cross-feature building blocks
    ├── models/                  # Translation, MenuItem, AppLanguage, etc.
    ├── notifiers/               # ChangeNotifiers (theme, language prefs)
    ├── widgets/                 # Reusable UI components
    └── utils/                   # Helpers & formatters

test/                            # Mirrors lib/ — 120+ unit tests
docs/                            # Pipeline artifacts (PRD, architecture, etc.)
android/ · ios/                  # Native project shells
```

### Architectural highlights

- **MVVM with `ChangeNotifier`** — each feature has a view‑model that owns async state and exposes it to widgets via `ListenableBuilder`.
- **Service Locator (`core/service_locator.dart`)** — a minimal static container so features can grab shared services without a heavyweight DI framework.
- **Typed errors** — network, API, and permission failures are mapped to domain errors for clean UI handling.
- **Offline‑first history** — SQLite persists every translation; the app works fully offline for browsing past results.

---

## 🛠️ Developing

Some patterns that are worth knowing if you're planning to fork:

- **Add a new feature** → create `lib/features/<your_feature>/` with a `*_view_model.dart` + `presentation/` folder, then add a route in `lib/core/router/app_router.dart`.
- **Add a new language** → extend `lib/shared/models/app_language.dart` and `target_language.dart`, then teach the OpenAI prompts in `OpenAIClient` to speak it.
- **Swap the translation provider** → replace `lib/core/api/openai_client.dart`. The rest of the app depends on the interface, not the provider.
- **Change the theme** → edit `lib/core/theme/app_theme.dart` — Material 3 color schemes + Google Fonts.
- **Debug on device** → Whisper and the camera both need real microphone/camera permissions; an emulator works but a real device gives the best experience.

Recommended workflow:

```bash
flutter pub get
dart analyze              # lint
flutter test              # unit tests
flutter run --dart-define=OPENAI_API_KEY=sk-...
```

---

## 🤝 Contributing

Contributions are very welcome! Whether it's a bug fix, a new language, better UX, or fresh screenshots — please open an issue or a PR.

1. Fork the repo
2. Create a branch: `git checkout -b feat/my-awesome-feature`
3. Make sure `dart analyze` is clean and `flutter test` passes
4. Open a pull request describing the change and why it's useful

Ideas that would be awesome to land:

- Catalan, Galician, and French translations
- Offline translation fallback for common dishes
- Shareable "order cards" you can show a waiter
- Widget / home‑screen quick translate

---

## 📄 License

LinguaViaje is released under the **MIT License** — free to use, fork, modify, and ship. See [`LICENSE`](./LICENSE) for the full text.

---

## 🙏 Acknowledgments

- [OpenAI](https://platform.openai.com) — GPT‑4o, Whisper, and TTS
- [Flutter](https://flutter.dev) — the framework that makes this cross‑platform
- Every traveler who's ever pointed at a menu and hoped for the best 🍷

---

**Enjoying LinguaViaje?**
Give it a ⭐ on GitHub, share it with a friend heading to Spain, and [open an issue](https://github.com/Junhanliu-dev/spanish-translator/issues) if you hit any rough edges. ¡Buen provecho! / On egin!
