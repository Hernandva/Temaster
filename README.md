# Temaster

Temaster is a music guessing game for iPhone and iPad. You pick an Apple Music playlist, the app plays its songs one by
one, and players guess the title, artist, year, decade or country of each song. A game can also be shown on a TV
through AirPlay or an external display.

The app is written in SwiftUI (Swift 6 language mode) with MVVM and a feature-based architecture, and it is split
into Swift packages.

## Requirements

- Xcode with the iOS 18 SDK or later (the deployment target is iOS 18.0).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) and [SwiftLint](https://github.com/realm/SwiftLint).
- An Apple Developer account in the project's team. The app's App ID must have the **MusicKit** App Service enabled
  (Certificates, Identifiers & Profiles → Identifiers → App Services).
- An Apple Music subscription on the test device to play songs.

## Getting started

```bash
brew install xcodegen swiftlint
xcodegen generate
open Temaster.xcodeproj
```

The Xcode project is generated from `project.yml` and is not committed. Run `xcodegen generate` again after you pull
changes that add, move or remove files.

## Tests and lint

```bash
(cd Packages/TemasterData && swift test)   # data layer tests
(cd Packages/TemasterUI && swift test)     # design system tests
scripts/lint.sh                            # SwiftLint, the same check as the build
```

SwiftLint runs before every build and the build fails above 3 violations. New code adds none.

## Structure

```
Temaster/                  App target: App/, Core/, Features/, Resources/ and FEATURES.md
Packages/TemasterData/     Data layer: repositories, DAOs, Alamofire and MusicKit clients, local storage (DATA.md)
Packages/TemasterUI/       Design system: tokens from Claude Design and UI components (DESIGN_SYSTEM.md)
scripts/codegen/           Generators for features, repositories and design tokens
scripts/lint.sh            SwiftLint check used by the build
.claude/skills/            Project skills: temaster-new-feature, temaster-new-repo
```

## Features

| Feature | What it does |
|---|---|
| `Home` | Asks for Apple Music access and starts a music provider. |
| `GameStarter` | Prepares a game: the last playlist used, the settings and the start button. |
| `PlaylistSelector` | Finds a playlist in your library, in curated lists or by search, and shows its songs. |
| `Settings` | Game settings: bingo levels and categories. |
| `Game` | Plays the songs, reveals the answers and mirrors the game on an external display. |

`Temaster/FEATURES.md` holds the full feature registry and the app map.

## Contributing

- Read `AGENTS.md` first: it lists the architecture rules, and points to the configuration file of each area.
- Create features and repositories with the generators (or the project skills), never by hand:

  ```bash
  python3 scripts/codegen/new_feature.py --name X --parent Y [--repository Z]
  python3 scripts/codegen/new_repo.py --name X
  ```

- Git flow: `main` holds releases and `develop` is the integration branch. Build each feature on
  `feature/Temaster-<Feature>`, created from `develop`.
- The app supports English and Spanish. Add every user-facing text to `Temaster/Resources/Localizable.xcstrings`.
