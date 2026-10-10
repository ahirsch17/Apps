# SpeakFlow

Practice speaking a language with a tutor character, in a hands-free voice call or by text. The Learn path and Review deck work offline with no API key.

Languages: Spanish (María), German (Anna), Italian (Giulia), Tagalog (Maya).

## Tabs

| Tab | Needs API key? | Description |
|-----|----------------|-------------|
| Call | Yes | Hands-free voice turns. Pause to send. **Say again** replays the tutor slower, **Blanked** gets you a starter. Recap at the end. |
| Text | Yes | Same tutor in chat. Corrections on your bubbles, English under replies, tap-to-use reply ideas, play any reply aloud. |
| Learn | No | Unit and lesson path with "Up next". Say it first, then reveal. Daily streak and XP. |
| Review | No | Spaced-repetition deck inside Learn, built from your corrections, recap phrases, and Learn misses. |
| Profile | No | Language, level, topic, slower voice, English translations, optional OpenAI key. |

## How learning loops back

1. In a call or chat, the tutor flags at most two mistakes per turn, each with a one-line tip.
2. Each correction is saved to your Review deck as "You said X, say Y".
3. The call recap pulls up to five reusable phrases (with English meanings) into the deck.
4. In Learn, anything you skip or miss lands in the deck too.
5. Review spaces cards out (10 min after a miss, then 1, 3, 7, 16, 35 days).

## Notes

- Speech recognition runs on-device when the phone supports it, so practice audio stays on the phone.
- Call mode needs Apple speech recognition for the language. Tagalog isn't supported by Apple yet, so Tagalog uses Text and Learn (with self-rating instead of mic grading).
- Mic and speech permissions are requested on your first call or drill, not at launch.
- The OpenAI key is stored in the Keychain. You pay OpenAI directly; a 10-minute call on GPT-4o mini costs pennies.

## Install

Open `SpeakFlow.xcodeproj`, set your signing team, run on an iPhone (iOS 17+).

## License

MIT
