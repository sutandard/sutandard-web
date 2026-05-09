# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

수원대학교 시간표 관리 시스템 (Suwon University Timetable Management System). Flutter app targeting web and Android, backed by a Django API at `https://api.sutandard.kr`.

## Commands

```bash
# Install dependencies
flutter pub get

# Run on Chrome (development)
flutter run -d chrome

# Run with local API
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8000

# Build for web
flutter build web --release --base-href "/"

# Build Android release
flutter build appbundle --release

# Lint
flutter analyze
```

No test suite exists yet.

## Architecture

**Clean architecture** with three layers under `lib/`:

- **`core/`** — Constants (API endpoints, app config), network layer (Dio client, auth interceptor, token storage), theme (Material 3, SUITE font), utilities (responsive breakpoints, snackbar, platform-conditional file download)
- **`data/`** — Models with manual `fromJson()` factories (no code generation), repository pattern (abstract + impl) for auth, courses, timetables, reviews, community, home
- **`presentation/`** — Feature folders (auth, home, timetable, courses, classroom, professor, review, community, common), each with views, viewmodels, and widgets subdirectories

**State management:** Riverpod with `NotifierProvider` for viewmodels, `Provider` for singletons (ApiClient, TokenStorage).

**Routing (`lib/routes.dart`):** go_router v14 (path-based). Uses `_RouterNotifier(ChangeNotifier)` with `refreshListenable` to re-evaluate redirects on auth changes without recreating the router — this pattern is critical and must not be changed to avoid login redirect loops.

**Responsive layout:** Custom `Responsive` utility (mobile < 600px, tablet 600-1024px, desktop >= 1024px). Standard layout: `Center(ConstrainedBox(maxWidth:1400))` with `Responsive.value()` for horizontal padding.

## Key Conventions

- Korean comments and some Korean variable naming throughout
- Manual JSON serialization (no freezed/json_serializable)
- API base URL configurable via `--dart-define=API_URL=...`, defaults to `https://api.sutandard.kr`
- Platform-conditional web file download via conditional exports (`download_utils.dart` → `download_web.dart` / `download_stub.dart`)
- Logo widget: `SutandardLogo(variant: textOnly)` uses `Logo.svg`; `full` variant uses `Sutandard.svg`
- Timetable auto-create uses `latest.label` (e.g. "2025년 1학기"), not `shortLabel`
- API endpoints use `/api/v1/` prefix (versioned)
- `/timetable` route is unprotected (guest access with mock timetable); `/wizard` and `/community` require auth
- Community feature uses `ContentWidget` (not `Widget`) to avoid Flutter naming collision; `WidgetTypeEnum`: `course`, `timetable`, `course_recommendation`

## Deployment

- **Web:** Cloudflare Pages via GitHub Actions on push to `main`. SPA routing handled by `web/_redirects`.
- **Android:** GitHub Actions on `v*` tags, builds AAB for Play Store.
- **Flutter version:** 3.35.1 stable (pinned in CI workflows).
