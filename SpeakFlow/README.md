# SpeakFlow

A native iOS speaking tutor. **Learn is free and offline.** AI Chat is optional — add your own OpenAI key in Profile when you want it.

**Languages:** Spanish (densest bank), German, Italian, Tagalog

## How the app is organized

| Tab | Needs API key? | What you do |
|-----|----------------|-------------|
| **Learn** | No | Word bank + phrase drills. Listen, then say it. |
| **Chat** | Yes (optional) | Live tutor. Hold to talk. Starters + Stuck help + corrections. |
| **Profile** | — | Language, level, topic, and optional API key. |

First launch walks you through this. Until you add a key, Chat shows a friendly “add key in Profile” card — Learn still works.

## Install on your iPhone

1. Open `SpeakFlow.xcodeproj` in Xcode 15+.
2. **Signing & Capabilities** → your Apple ID Team. Bundle ID: `com.alexishirsch.SpeakFlow`.
3. Plug in iPhone → Run (⌘R).
4. Allow Microphone + Speech Recognition.
5. First install: **Settings → General → VPN & Device Management** → trust the developer.

iOS 17+. Free Apple ID works (7-day cert refresh).

## Optional AI Chat

In **Profile → AI Chat (optional)** paste an [OpenAI API key](https://platform.openai.com/api-keys). Typical cost: **~$0.001 per exchange** with GPT-4o mini. No SpeakFlow subscription.

## Practice flow (Chat)

1. Tap the session bar → language, level, topic → Start.
2. Tutor asks + offers starter stems.
3. Tap a stem, or **Stuck** for a full answer to shadow.
4. **Hold the mic**, **release** to send.
5. Read corrections → next question.

## Privacy

- Learn: speech stays on-device (Apple Speech + TTS).
- Chat: transcript goes to OpenAI over HTTPS. Key stays in Keychain.
- No analytics SDKs.

## License

MIT
