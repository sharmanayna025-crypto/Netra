# Netra

On-device privacy and credential health for iOS, with a built-in Safari extension.
**One app, one project:** the Safari extension (`NetraExtension`) is embedded in the Netra app,
so users install a single app and turn the extension on in Safari settings.

## Project layout

```
Netra.xcodeproj
Netra/                    App target (SwiftUI + SwiftData)
  Core/Models             SwiftData models, TrackerCatalog, shared value types
  Core/Services           Keychain, password analyzer, security/privacy/alert engines,
                          ScanRepository (live data from the extension), app lock
  DesignSystem            NetraTheme (colour/spacing/type) + reusable components
  Features/               Home, Privacy, Security, Identity, Alerts, Activity, Settings
NetraExtension/           Safari Web Extension target
  Resources/              manifest, background.js (classify + score), content.js, popup
  SafariWebExtensionHandler.swift
Shared/                   Compiled into BOTH targets
  trackers.json           THE tracker database + scoring rules (single source of truth)
  SharedConfig / ScanModels / ScanStore   App Group storage
Tests/js/                 Node tests for the extension's engine
Tools/gen_trackers.py     Regenerates trackers.json (edit data here, or edit the JSON directly)
```

## Data flow

```
page ──content.js──▶ hostnames ──background.js──▶ classify (trackers.json) + score
                                       │
                    popup renders ◀────┤
                                       ▼ native message
                     SafariWebExtensionHandler ──▶ ScanStore (App Group scans.json)
                                                        │  Darwin notification
                                                        ▼
                                          Netra app: ScanRepository → views
```
The score is computed in exactly one place (`background.js`). The app stores and aggregates
those scores; it never re-scores, so the popup and the app cannot disagree.

## Before you build (one-time, ~2 minutes)

1. Open `Netra.xcodeproj`. Select the **Netra** and **NetraExtension** targets → *Signing & Capabilities*
   and confirm your team. Both need the **App Groups** capability with `group.com.nvs.Netra`
   (the entitlements files already list it; Xcode registers the new extension ID automatically).
2. The extension's bundle ID is `com.nvs.Netra.SafariExtension` (it must be prefixed by the app's ID).
3. Delete the old **NetraSafari** app from your device/simulator so only one Netra remains.
4. Run the **Netra** scheme. In iOS: *Settings → Apps → Safari → Extensions → Netra* → allow on all websites
   (iOS 17: *Settings → Safari → Extensions*). The in-app **Safari setup** screen explains this.
5. Add a 1024×1024 app icon to `Assets.xcassets/AppIcon` (none was in the project).

If Xcode reports a problem with the hand-edited project file, create a new *Safari Extension* target
via *File → New → Target*, then drag `NetraExtension/` and `Shared/` into it — all source files are ready.

## What Phase 1 changed

| # | Goal | What was done |
|---|------|---------------|
| 1 | One app | Extension target embedded in Netra; shared code/resources via `Shared/` |
| 2 | App Group flow | File-based `ScanStore` with `NSFileCoordinator` + Darwin notification; history per site with timestamps (was: last page overwrote a single key and the app never refreshed) |
| 3 | No fake data | `IdentityStore` (hard-coded "0 breaches") removed; Identity shows honest **Coming soon**; Home score excludes identity |
| 4 | Shared tracker DB / first-party | `trackers.json` (42 companies, 72 domains, plain-language explanations) used by extension and app. First-party detection uses registrable domains (fixes `cdn.example.com` and `facebook.com` being flagged) and company ownership (Google on youtube.com) |
| 5 | Consistent scoring | One scorer; one set of weights/bands in the JSON; unknown domains counted but never scored; coverage disclaimer shown |
| 6 | UI/UX | New design system (adaptive light/dark palette, rounded type, cards, score rings, pills, empty states), iPad-friendly width, Dynamic Type, accessibility labels, redesigned popup |
| 7 | Bugs/architecture | See below |

### Bugs fixed / code removed
- Keychain: delete-then-add could lose a password → in-place update; items now `WhenUnlockedThisDeviceOnly`.
- Add flow inserted the model before the Keychain write succeeded → Keychain first, with rollback.
- Reuse check was O(n²) Keychain reads → one read per credential, grouped by SHA-256.
- `PasswordAnalyzer` was dead code → now drives a live strength meter, stored strength scores, and a generator.
- Test structs that printed plaintext passwords removed from the app target.
- Activity log was in-memory → persisted with SwiftData and merged with browsing history.
- Alert severities were all "warning" → real critical/warning/tip levels; fabricated alert score removed.
- Add/Edit screens merged into one form; delete logic centralised in `CredentialService`.
- Detail screen could show a stale password after editing and could read a deleted model → fixed.
- Extension: placeholder App Store description replaced; unneeded `tabs` permission removed; popup uses
  `textContent` (no `innerHTML`); performance-buffer limit handled with `PerformanceObserver`;
  noisy logging removed (hostnames are never logged).
- Added: Face ID/passcode app lock, authenticated reveal/copy with auto-expiring clipboard,
  history retention + clear, pause-saving toggle in the popup, private-tab skip.

### Compatibility notes
- Deployment target lowered from iOS 26.5 to **17.0** for both targets.
- Existing credentials and Keychain items keep working; `CredentialModel` gained fields with defaults
  (lightweight migration). Credentials saved before this version fall back to length-based strength until re-saved.

## Verification status — please read
- **Verified here:** the extension engine (9 Node tests: first-party detection, scoring, bands, edge cases),
  JSON/plist validity, JS syntax, Xcode project structure (balanced, unique and fully-resolved object IDs).
- **Not verified here:** the Swift code and the Xcode build. This environment has no Swift toolchain or Xcode,
  so nothing was compiled or run on a device. Expect to fix a few compiler messages on first build.
  Run `node Tests/js/background.test.js` any time you change the extension.

## Known limitations (candidates for Phase 2)
- Detection uses Resource Timing in the top frame; requests made inside cross-origin iframes, CNAME-cloaked
  trackers and first-party proxies are not seen. The tracker list is curated (72 domains), not exhaustive.
- First-party matching uses a built-in list of common two-part suffixes, not the full Public Suffix List.
- iOS gives apps no API to check whether the extension is enabled; the setup screen infers it from received scans.
- Netra reports and explains; it does not block trackers.
