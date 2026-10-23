# SyncRide (Flutter/Android)

Native Android client for SyncRide, replacing the React/Vite web app. The
Express/Socket.IO backend is unchanged — same REST endpoints and socket
events (`trip:join`, `location:update`, `sos:send`, etc.), just a new consumer.

Built for a free/personal-project budget — zero API keys, zero billing:
- Maps + live rider positions: `flutter_map` with OpenStreetMap tiles (no
  key, no billing, no restrictions to manage)
- Route polyline: OSRM's free public routing server (no key; rate-limited,
  so swap in a self-hosted OSRM instance if usage grows)
- Turn-by-turn voice guidance: handed off to the phone's installed Google
  Maps/Waze app via `url_launcher` — no in-app guidance, since the actual
  Navigation SDKs (Google's or anyone else's) all require paid accounts.
- Android Auto: out of scope for now. It would need a separate native Kotlin
  `CarAppService` module bolted on later, since Flutter can't render to an
  Auto head unit directly.

(We initially tried `google_maps_flutter` + Google's Directions API, but
getting a key working cleanly — enabling the right APIs, billing, and
Android app restrictions all lining up — turned into enough of a dead end
for a personal project that OSM/OSRM was the simpler, genuinely-free path.)

## Setup

1. `cp .env.example .env` and set `SYNCRIDE_API_BASE_URL` (your running
   backend; `10.0.2.2` is the Android emulator's alias for the host
   machine's `localhost`). `OSRM_BASE_URL` defaults to the public demo
   server and doesn't need to be touched for local testing.
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
