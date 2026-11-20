# Temaster — Features configuration

This file is the source of truth for how scenes (features) are built in the `Temaster` app target
and how they connect to each other. Humans and coding agents must follow it, and the
`temaster-new-feature` skill keeps the **Feature registry** and the **App map** below up to date.
Do not remove the `codegen` markers: the generator writes between them.

## Stack

- UI: SwiftUI only. Views compose components from the `TemasterUI` package; they never style raw controls.
- Language: Swift 6 language mode, strict concurrency. View models are `@MainActor @Observable`.
- Architecture: MVVM, feature based. One folder per feature under `Temaster/Features/`.
- Data: features never talk to Alamofire or DAOs. They reach the `TemasterData` package only through a
  repository's public API (`<Name>RepositoryProtocol`) and its public request/response protocols.

## Anatomy of a feature

Every new feature gets its own folder with this exact structure (example: `Profile`):

```
Features/Profile/
├── ProfileCoordinator.swift        # Entry point: builds the view and resolves navigation routes
├── ProfileDependencies.swift       # Dependency injection container of the feature
├── View/ProfileView.swift          # SwiftUI view built only with TemasterUI components
├── ViewModel/ProfileViewModel.swift# @MainActor @Observable state holder, calls the use case
├── Model/ProfileViewData.swift     # Display-ready data, owned by the view model as a variable
└── UseCase/ProfileUseCase.swift    # Business logic; calls the repository public API
```

### Responsibilities

| Type | Responsibility | Rules |
|---|---|---|
| `<Feature>Coordinator` | Initialises the view through `<Feature>Dependencies` and declares the routes (`Route` enum) to the features that can be opened from it. | Conforms to `Coordinator`. Only coordinators create other coordinators. |
| `<Feature>Dependencies` | Builds the use case, the view model and injects the repository. | The only place where concrete types are created. Keeps each dependency as a `private let` and exposes it through a `resolve<Name>()` function (`resolveRepository()`, `resolveUseCase()`, `resolveViewModel()`). It never builds the ViewData. |
| `<Feature>View` | Renders state. Adds TemasterUI components and localises text with `.localized("key")`. | No business logic, no networking, no hard-coded colors or fonts. |
| `<Feature>ViewModel` | Owns the screen state (`idle`, `loading`, `loaded`, `failed`) and the `viewData` variable. Adds each use case result to its own field of `viewData`. | Depends on `<Feature>UseCaseProtocol`, never on a repository. `private(set) var viewData`; the state never carries the ViewData. |
| `<Feature>ViewData` | Display model held by the view model. One field (and, if needed, one nested type) per use case result. | Value type, `Equatable` and `Sendable`, with `var` fields. Never maps response protocols and never exposes TemasterData types to the view. |
| `<Feature>UseCase` | Calls the repository through its **public API** and returns **only the data of the response**, mapped out of the TemasterData types into a ViewData field type. | Depends on `<Name>RepositoryProtocol` from `TemasterData`. Never builds or returns the whole ViewData. |

### Initialisers: only the container

`<Feature>View`, `<Feature>ViewModel` and `<Feature>UseCase` receive **only** `dependencies: <Feature>Dependencies`
in their `init`, and resolve everything else inside it through the container's `resolve…()` functions.
They never take a use case, repository, view model or view data as an `init` parameter.

```swift
// View
init(dependencies: ProfileDependencies) {
    _viewModel = State(initialValue: dependencies.resolveViewModel())
}

// ViewModel
init(dependencies: ProfileDependencies) {
    self.useCase = dependencies.resolveUseCase()
}

// UseCase (a Sendable struct: it stores what it resolves, not the container)
@MainActor
init(dependencies: ProfileDependencies) {
    self.repository = dependencies.resolveRepository()
}
```

- Naming: every function of the container that hands out a dependency is `resolve<Name>()`. Never `make<Name>()`.
- To add a dependency: store it as a `private let` in `<Feature>Dependencies`, add `resolve<Name>()`, and resolve it
  in the `init(dependencies:)` that needs it.
- The coordinator starts the view with `<Feature>View(dependencies: dependencies)`, and the container builds the
  others with `<Feature>ViewModel(dependencies: self)` and `<Feature>UseCase(dependencies: self)`.
- The use case `init` is `@MainActor` because the container is.

### Data flow

```
View ──▶ ViewModel ──▶ UseCase ──▶ <Name>RepositoryProtocol (TemasterData public API)
                                        │
View ◀── ViewModel.viewData ◀── response data ◀── <Name>ResponseProtocol
            (adds it to a field)   (use case maps it)
```

### ViewData lives in the view model

The view model owns the screen data as a variable, and each use case only hands it the data of its response:

```swift
// ViewData: one field per use case result
struct ProfileViewData: Equatable, Sendable {
    struct User: Equatable, Sendable { let name: String }
    var user: User?
}

// UseCase: returns only the data of the response, mapped out of TemasterData
func execute() async throws -> ProfileViewData.User {
    let response = try await repository.fetch(ProfileRequest(), serviceName: serviceName)
    return ProfileViewData.User(name: response.name)
}

// ViewModel: keeps the ViewData and adds each result to its own field
private(set) var state: State = .idle          // idle, loading, loaded, failed
private(set) var viewData = ProfileViewData()

func load() async {
    state = .loading
    do {
        viewData.user = try await useCase.execute()
        state = .loaded
    } catch {
        state = .failed(error.localizedDescription)
    }
}
```

- A new result never erases the rest of the data: assign only the field of that use case.
- The view reads `viewModel.viewData` (or view model properties built on it), and switches on `state`
  only to show loading or error.
- A screen with several use cases has one field per use case, and may have one `…Loaded` state per result.

### Navigation

- Each coordinator declares `enum Route: Hashable` with one case per child feature, and maps each case
  to the child's coordinator in `destination(for:)`.
- A view opens a child feature with `NavigationLink(value: <Parent>Coordinator.Route.<child>) { ... }`.
- The root feature is started by `App/RootView.swift` inside the `NavigationStack`.
- `RootView` binds the `NavigationStack` to `HomeCoordinator.path` (a `NavigationPath`), so every route pushed with
  `NavigationLink(value:)`, from any feature, lands on that one path. A coordinator that navigates from its view model
  appends a route to it (Home after signing in), and «Sign out» resets it to go back to Home. Never push with
  `navigationDestination(item:)` or `isPresented:`: value links pushed on top of those screens are lost.
- A view that needs a glass icon button as a link uses `NavigationLink(value:) { Image(systemName:) }` with
  `.buttonStyle(DSIconButtonStyle(diameter:))`, never a `DSIconButton` inside a `NavigationLink`.

### External display (AirPlay)

The game has its own screen for an external display (a TV through AirPlay or a cable) instead of mirroring the
iPhone: the TV shows the round in 16:9 for the room, and the iPhone keeps the controls.

- `App/AppDelegate.swift` gives the `windowExternalDisplayNonInteractive` scene role its own delegate,
  `App/ExternalDisplaySceneDelegate.swift`, which hosts `App/ExternalDisplayRootView.swift`. Every other scene keeps
  SwiftUI's default configuration. That is enough before iOS 27.
- From iOS 27 the system only connects that scene for a registered `UISceneAccessory`. `GameView` registers one
  with `.externalDisplayAccessory()` (`App/ExternalDisplayAccessory.swift`), with the same configuration and
  delegate, so the display has its own screen only during a game and mirrors the iPhone everywhere else.
- UIKit creates that scene, so it cannot receive a feature's dependencies. It reads the shared
  `Features/Game/ExternalDisplay/GameExternalDisplaySession.swift` instead: `GameViewModel` presents itself there in
  `load()` and takes itself off in `stop()`, and the scene delegate reports when a display connects or disconnects.
  `GameDependencies` injects the session (`resolveExternalDisplaySession()`).
- `GameExternalDisplayView` is the one view that does not take `init(dependencies:)`: it mirrors the view model of
  the iPhone's `GameView` and owns none of its own. It has no controls, because the display is not interactive.
- `View/GameViewModel+DesignSystem.swift` maps the game's state to design-system types for both views, so the iPhone
  and the TV always show the same round.
- Test it in the Simulator with *I/O > External Displays*.

### Localisation

- Strings live in `Resources/Localizable.xcstrings`. Keys follow `<featureName>.<element>`, e.g. `profile.title`.
- Components that show text expose `.localized("key")` (see `Packages/TemasterUI/DESIGN_SYSTEM.md`).

### Bingo levels and categories

The Settings repository (`TemasterData`) owns which Bingo levels exist and, for each one, its five categories:
`SettingsRepositoryProtocol.bingoLevels()` returns them in order, with the keys of their names. Features read them in
a use case (`BingoLevelsUseCase` in Settings, `GameSettingsUseCase` in GameStarter), localise the names there and
keep them in their ViewData. `TemasterUI` only draws: `DSBingoCategory` is the color, and components receive the
names already localised.

Every level has the same five categories with the same colors; a level only changes their names. To add one:

1. `SettingsBingoLevel` (TemasterData): add the case. Its raw value is stored, so it never changes later.
2. `BingoLevelsCatalog` (TemasterData, `Repositories/Settings/Local/`): add `BingoLevelDAO(level: .<level>)` where
   it should show up.
3. `Localizable.xcstrings`: add `bingo.level.<level>` and the five `bingo.category.<color>.<level>`.

Settings shows its segment and its categories, and the game uses them, with no other change.

### Play mode and generations

Settings also stores who plays (`SettingsPlayMode`, default `individual`): `individual` keeps the game as it always
was, and `generations` splits the players into three generations that always all play, like the Bingo categories.
`SettingsRepositoryProtocol.generations()` returns them with the keys of their names (`generation.<generation>`);
`GenerationsUseCase` localises them and `DSGeneration` gives each its color and icon. A third option, `custom`, shows
the user's own generations: for now an empty list and an «Add new» button that does nothing yet
(`SettingsViewModel.didTapAddCustomGeneration()`); GameStarter and the game treat it like `individual`. Every generation plays with its own
playlist. GameStarter reads the play mode every time it appears (`GenerationPlaylistsUseCase`): with `generations`
it shows one playlist card per generation, each opening the selector with
`Route.playlistSelector(generation)`, and Play appears once every generation has a playlist; otherwise it shows the
single selected playlist card. Like the shared playlist, each generation's card shows the playlist it last played with
(`LastGenerationPlaylistsUseCase`) until another is chosen, and Play saves the generations' playlists apart from the
shared one (`SaveGenerationPlaylistsUseCase`, `LastPlaylistRepository.saveGenerationPlaylists`). Play hands the game every playlist (`Route.game([GamePlaylist], settings)`): one
for everyone, or one per generation in their order. Game keeps one shuffled queue per playlist and plays them in
turns: Continue passes the turn to the next generation that has songs left (Next keeps it), the header shows whose
turn it is, and the game ends when every queue is empty.

Before the turns, each generation's playlist is mixed by release year (`GenerationMixUseCase`, applied by
`FetchGameSongsUseCase`): its songs are split into the three generations' years (`firstYear`/`lastYear` from the
Settings repository: up to 1984, 1985-2004, from 2005), and the generation plays 70 % of its own, 20 % of the nearest
(vinyl → cassette, cassette → streaming, streaming → cassette) and 10 % of the farthest, as many as the playlist allows.
Songs without a year are left out; a group with no songs gives its share to the others; a playlist where no song has a
year plays whole. The shared playlist is never mixed.

### Creating a feature

Use the `temaster-new-feature` skill, or run:

```
python3 scripts/codegen/new_feature.py --name <FeatureName> --parent <ExistingFeature> [--repository <RepositoryName>]
```

It creates the branch `feature/Temaster-<FeatureName>` from `develop`, the folder and classes above,
adds the route to the parent coordinator and updates this file.

## Feature registry

<!-- codegen:feature-registry:start -->
| Feature | Opened from | Repository |
|---|---|---|
| `Home` | — (root) | `Authorization`, `Login` |
| `GameStarter` | Home | `LastPlaylistRepository`, `SettingsRepository` |
| `Settings` | GameStarter | `SettingsRepository` |
| `PlaylistSelector` | GameStarter | `PlaylistsRepository`, `SongRepository` |
| `Game` | GameStarter | `Song`, `Player`, `Artist` |
<!-- codegen:feature-registry:end -->

## App map

Which feature opens which. `A --> B` means feature A can open feature B.

<!-- codegen:app-map:start -->
```mermaid
graph TD
    Home
    Home --> GameStarter
    GameStarter --> Settings
    GameStarter --> PlaylistSelector
    GameStarter --> Game
```
<!-- codegen:app-map:end -->
