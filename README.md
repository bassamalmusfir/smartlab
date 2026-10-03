# SmartLAB

SmartLAB helps patients understand their lab results. Upload a photo or PDF of a blood or urine test report, and the app reads every value, compares it with the reference range printed on the report, and explains what the results mean in plain language.

The report is read by an AI model through a small Node.js backend, so the AI API key never ships inside the app. During development and testing we use **Claude Opus 5.5** (Anthropic); for the production release we plan to replace it with our own model (see [Roadmap](#roadmap)).

> SmartLAB gives educational explanations, not medical diagnoses. Every result screen tells the user to discuss their results with a doctor.

## Features

- **Email sign-up and login** with Firebase Authentication
- **Lab report upload**: attach one or more PDFs or images (PNG, JPEG) to a new test
- **AI analysis** of the report:
  - each value with its unit and reference range, flagged *low*, *normal* or *high*
  - an overall risk level (low, normal, moderate, high)
  - a plain-language explanation, key insights and recommendations
- **Results saved per user** in Cloud Firestore, protected by security rules so each user can only read their own tests

## How it works

```
Flutter app ──(PDF / images, multipart)──▶ Node.js server ──▶ Claude API
     │                                            │
     │◀──────────── analysis (JSON) ──────────────┘
     │
     └──▶ Cloud Firestore  users/{uid}/testEntries/{entryId}
```

1. The user attaches a report on the **New Test** screen.
2. The app sends the files to [`server/index.js`](server/index.js).
3. The server passes them to Claude as PDF document or image blocks, with **structured outputs**: a JSON schema forces the response into exactly the shape the app expects (values, risk level, explanation), so there is no fragile text parsing.
4. The app saves the test and its analysis to Firestore and opens the results screen.

## Tech stack

| Layer | Technology |
|---|---|
| App | Flutter (web and Android), Provider, go_router, Dio |
| Auth and data | Firebase Authentication, Cloud Firestore with security rules |
| Backend | Node.js, Express, Multer |
| AI | Claude Opus 5.5 via the official Anthropic SDK for testing, structured JSON outputs (to be replaced by our own model) |

## Project structure

```
lib/
  config/       theme and routes
  models/       TestEntry, TestValue, TestResultAnalysis
  providers/    auth and test state (Provider)
  services/     Firebase and analysis-server clients
  screens/      login, home, new test, results
server/         Node.js analysis server (Claude API)
test/           model unit tests
firestore.rules per-user access rules
```

## Running locally

**Requirements:** Flutter SDK, Node.js 18+, a Firebase project, and an [Anthropic API key](https://console.anthropic.com).

1. **Firebase:** enable Email/Password sign-in and Cloud Firestore in your Firebase project, then generate the app config:
   ```
   flutterfire configure
   firebase deploy --only firestore:rules
   ```
2. **Analysis server:**
   ```
   cd server
   npm install
   cp .env.example .env    # then put your ANTHROPIC_API_KEY in .env
   npm start               # http://localhost:3000
   ```
   The model is set by `CLAUDE_MODEL` in `.env`.
3. **App:**
   ```
   flutter pub get
   flutter run -d chrome --web-port=8765
   ```
4. **Tests:** `flutter test`

## Status

Working: sign-up and login, report upload, AI analysis, results screen, saving to Firestore.

## Roadmap

**Publishing to the app stores.** SmartLAB is being prepared for release on the Google Play Store and the Apple App Store.

**Our own AI model.** Anthropic's Claude is used during development to test and validate the analysis flow. For the production release we plan to replace it with our own model. The app is built for this switch: it never talks to the AI provider directly, only to the SmartLAB server, and the server returns a fixed JSON format. Changing the model means changing the server only; the mobile app stays the same.

Planned before release:
- History screen listing past tests
- Profile and dietary recommendation screens
- Keeping the original report files in Firebase Storage
- Verifying the Firebase login token on the server before it is deployed publicly
- Hosting the analysis server and connecting it to our own model
