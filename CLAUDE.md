# Niam — Project Rules

## Architecture
- SwiftUI + SwiftData (iOS 17+)
- MVVM: Models / ViewModels (@Observable) / Views
- Repository pattern for data access (future cloud migration)
- xcodegen for project generation (`xcodegen generate` after structure changes)

## Build
```
xcodegen generate
xcodebuild -project Niam.xcodeproj -scheme Niam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Project structure
```
Niam/
  App/          — Entry point, ContentView
  Models/       — SwiftData models
  ViewModels/   — @Observable view models
  Views/        — SwiftUI views by feature (Browse, Kitchen, Tracker, Me, Onboarding, Recipes, Fridge)
  Services/     — API clients, business logic
  Repositories/ — Data access abstraction
  Utilities/    — Helpers
  Resources/    — Assets
```

## Conventions
- Secrets in `Niam/Secrets.swift` (gitignored), template in `Secrets.example.swift`
- Commit messages reference Linear issues: `Closes NM-XX`
- No emoji in code comments or file content unless user requests
- Chinese + English shelf life dictionary in ShelfLifeService

## Key files
- `project.yml` — xcodegen config
- `docs/PRODUCT_BRIEF.md` — Product goals and constraints
- `docs/PM_SNAPSHOT.md` — Last PM review state

## Agents
- `@product-manager` — Project status, prioritization, product decisions, scope control
- `@qa-engineer` — Build verification, regression testing, code quality, data model safety

Use agents for their specific purposes. Do not duplicate agent logic in development conversations.
