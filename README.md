# Temaster

SwiftUI app for iOS (iPhone), iPadOS. It uses MVVM with a feature-based architecture and is split into Swift packages (`TemasterData`, the data layer with Alamofire and local storage, and `TemasterUI`).

## Getting started

```bash
brew install xcodegen swiftlint
xcodegen generate
open Temaster.xcodeproj
```

The Xcode project is generated from `project.yml` and is not committed. Run `xcodegen generate` again after you pull changes that add files.

## Structure

```
Temaster/                 App target: App/, Core/, Features/, Resources/, FEATURES.md
Packages/TemasterData/     Data layer: repositories, DAOs, Alamofire client and local storage (DATA.md)
Packages/TemasterUI/       Tokens from Claude Design and UI components (DESIGN_SYSTEM.md)
scripts/codegen/             Generators used by the project skills
.claude/skills/              Project skills: new feature, new repository
```

See `AGENTS.md` for the conventions.
