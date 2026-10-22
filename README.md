# SyncRide (Flutter/Android)

Native Android client for SyncRide, replacing the React/Vite web app. The
Express/Socket.IO backend is unchanged — same REST endpoints and socket
events (`trip:join`, `location:update`, `sos:send`, etc.), just a new consumer.

Built for a free/personal-project budget:
- Maps + live rider positions: `google_maps_flutter`
- Route polyline: Directions API (covered by Google's monthly free credit at
  personal-project volume)
- Turn-by-turn voice guidance: handed off to the phone's installed Google
  Maps/Waze app via `url_launcher` — Google's Navigation SDK isn't available
  in Flutter and isn't free, so there's no in-app guidance.
- Android Auto: out of scope for now. It would need a separate native Kotlin
  `CarAppService` module bolted on later, since Flutter can't render to an
  Auto head unit directly.

## Setup

1. `cp .env.example .env` and fill in `MAPS_API_KEY` (a Google Cloud project
   with Maps SDK for Android + Directions API enabled) and
   `SYNCRIDE_API_BASE_URL` (your running backend; `10.0.2.2` is the Android
   emulator's alias for the host machine's `localhost`).
2. `flutter pub get`
3. `flutter run`

## Structure

```
lib/
├── core/config.dart          # reads .env
├── realtime/
│   ├── socket_manager.dart   # Socket.IO client, matches backend contract
│   └── trip_repository.dart  # REST: create/join trip
├── location/location_service.dart  # foreground service + GPS stream
├── maps/
│   ├── directions_service.dart     # Directions API + polyline decode
│   └── navigation_launcher.dart    # hands off to Google Maps/Waze
├── sos/sos_manager.dart
└── ui/
    ├── home_screen.dart      # create/join trip
    └── trip_map_screen.dart  # live map, SOS, route, nav handoff
```

`flutter analyze` is clean and `flutter build apk --debug` succeeds as of
this scaffold. Location/SOS/map flows are wired but untested against a real
backend — point `SYNCRIDE_API_BASE_URL` at a running instance of
`apps/api` to validate.
