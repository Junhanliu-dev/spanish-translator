# Privacy Policy

_Last updated: 2026-05-15_

LinguaViaje is an open-source, **bring-your-own-key** translator. It is built to leak as little of your data as possible. This page explains exactly what happens to the data the app touches.

## TL;DR

- **No accounts.** No sign-up, no email, no profile.
- **No analytics, no tracking, no ads.** The app does not embed any third-party SDK that profiles you.
- **No servers we operate.** There is no LinguaViaje backend. Translations go directly from your device to OpenAI using your own API key.
- **Your data lives on your device.** Translation history, settings and your API key are stored locally in the device's secure storage / SQLite, never uploaded by us.

## Data the app handles

| Data | Where it lives | Who else sees it |
|---|---|---|
| OpenAI API key | Device secure storage (Keychain / EncryptedSharedPreferences) | No one. Sent only to `api.openai.com` as your auth header. |
| Text you type, paste or transcribe | Device memory + local SQLite history | OpenAI, when you ask for a translation. |
| Menu photos you snap | Device memory only — sent to OpenAI for OCR + translation, **not** persisted by us | OpenAI, for the duration of the request. |
| Voice recordings | Device memory only — sent to OpenAI Whisper for transcription, then discarded | OpenAI, for the duration of the request. |
| Translation history | Local SQLite database on the device | No one — never leaves the device. |
| App settings (theme, target language) | `shared_preferences` on the device | No one. |

## Third parties

- **OpenAI** — handles the actual translation, transcription (Whisper) and text-to-speech. Your prompts, audio and images are governed by [OpenAI's API data usage policy](https://openai.com/policies/api-data-usage-policies). You are the API customer; we are not.

That is the entire third-party list. There is no Firebase, no Crashlytics, no Sentry, no Mixpanel, no AppsFlyer, no Facebook SDK, no Google Analytics.

## Permissions and why

- **Camera** — to photograph menus you want translated. Photos are not stored or sent anywhere except OpenAI for that single request.
- **Microphone** — to record short phrases for voice translation. Audio is not stored or sent anywhere except OpenAI for that single request.
- **Photo library** — optional, only used if you pick an existing menu photo instead of taking a new one.
- **Network** — to reach `api.openai.com`.

Decline any of these and the related feature simply will not work; the rest of the app keeps working.

## Children

LinguaViaje is not directed at children under 13 and does not knowingly collect data from them.

## Deleting your data

- **History** — clear it any time from Settings.
- **API key** — clear it any time from Settings; this also wipes it from secure storage.
- **Everything** — uninstall the app. All local data goes with it.

## Changes

This policy lives in version control. Material changes will be reflected here with a new "Last updated" date.

## Contact

Questions or concerns: open an issue at <https://github.com/Junhanliu-dev/spanish-translator/issues>.
