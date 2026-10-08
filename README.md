# TrailTrack

Real-time trail conditions and community walks for Ireland.

TrailTrack is an Android app for hikers in Ireland, with two main features:

- **Condition reporting:** report and view current trail conditions such as
  mud, flooding, fallen trees, and closures, so hikers know what to expect
  before they set out.
- **Community walks:** organise and join group walks on a specific trail and
  date, bringing together walks that are currently arranged across club
  websites, social media, and group chats.

Trail routes come from the Sport Ireland National Trails Register, the
authoritative record of waymarked trails in Ireland. Reporting is free, and
offline support lets reports be submitted from areas with patchy signal.

Final Year Project, BSc (Hons) Software Development, South East
Technological University (SETU), Carlow.

## Status

Iteration 1 of 4 is in progress.

| Iteration 1 feature | Status |
|---|---|
| Trail data import (County Laois, 28 trails) | Done |
| User registration and login | Planned |
| Map display of imported trails | Done |
| Condition report submission | Planned |
| Trail search by name and distance | Planned |

The mobile app shows every trail on an OpenStreetMap base map, drawn in the
colour of its trail signs. Routes that start from the same trailhead are
grouped into a site, such as the three loops at Oughaval Woods, so each route
can be picked out and its difficulty and length shown.

**Roadmap:** Iteration 2 adds community walks and live condition overlays on
the map. Iteration 3 adds offline report queuing and moderation rules.
Iteration 4 is testing and polish.

## Tech stack

| Component | Technology |
|---|---|
| Mobile client | Flutter (Android) |
| Backend API | Spring Boot 4, Java 21, Gradle |
| Database | PostgreSQL 16 with PostGIS 3 |
| Map tiles | OpenStreetMap via flutter_map |
| Trail data | Sport Ireland National Trails Register |

## Repository structure

```text
backend/        Spring Boot API
mobile/         Flutter Android app
docs/design/    UML diagrams and UI wireframes
```

## Getting started

### Prerequisites

- Java 21
- PostgreSQL 16 with the PostGIS extension
- Flutter SDK, plus the Android SDK and an emulator or device

### Database setup

Create a database user and the `trailtrack` database, and enable PostGIS:

```bash
sudo -u postgres createuser --createdb --login <your-username>
sudo -u postgres createdb -O <your-username> trailtrack
sudo -u postgres psql -d trailtrack -c "CREATE EXTENSION postgis;"
psql -d trailtrack -c "ALTER USER <your-username> WITH PASSWORD '<password>';"
```

The database username is set in
`backend/src/main/resources/application.properties`
(`spring.datasource.username`). The password is read from an environment
variable, so it is never stored in the repository:

```bash
export DB_PASSWORD='<password>'
```

### Run the backend

```bash
cd backend
./gradlew bootRun
```

The API runs on `http://localhost:8080`. The `trails` table is created
automatically on first start.

### Import trail data

```bash
curl -X POST http://localhost:8080/api/admin/trails/import
```

The first run returns `{"created":28,"updated":0}`. Running it again updates
the existing trails instead of creating duplicates.

This endpoint is not yet secured, so only run the backend locally for now.
Access will be restricted to administrators when login is added.

### Run the mobile app

```bash
cd mobile
flutter run
```

With the backend running, the Android emulator reaches it at
`http://10.0.2.2:8080` by default. To use a different address, for example
on a physical phone:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-computer-ip>:8080
```

### Run the tests

```bash
cd backend
./gradlew test
```

The backend tests need PostgreSQL running and `DB_PASSWORD` set.

```bash
cd mobile
flutter test
```

## API

| Method | Path | Description |
|---|---|---|
| GET | `/api/trails` | Returns every trail as GeoJSON, simplified for map display |
| POST | `/api/admin/trails/import` | Imports County Laois trails from the Sport Ireland register |

## Design

Use case, domain model, sequence, and screen navigation diagrams, plus
low-fidelity wireframes, are in [docs/design](docs/design/README.md).

## Data sources and attribution

- Trail data: Sport Ireland National Trails Register, published on
  data.gov.ie under the Creative Commons Attribution 4.0 licence (CC BY 4.0).
- Map tiles: &copy; OpenStreetMap contributors, under the Open Database
  Licence (ODbL).

## Author

Mark Mukiiza, SETU Carlow.
