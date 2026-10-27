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

Iteration 1 of 4 is complete and released as
[v0.1](https://github.com/Markus-Bear/TrailTrack/releases/tag/v0.1).

| Iteration 1 feature | Status |
|---|---|
| Trail data import (County Laois, 28 trails) | Done |
| User registration and login | Done |
| Map display of imported trails | Done |
| Condition report submission | Done |
| Trail search by name and distance | Done |

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
| Database | PostgreSQL 16 or later with PostGIS 3 |
| Map tiles | OpenStreetMap via flutter_map |
| Trail data | Sport Ireland National Trails Register |

## Repository structure

```text
backend/                Spring Boot API
mobile/                 Flutter Android app
docs/design/            UML diagrams and UI wireframes
docs/specification/     Project specification
docs/diaries/           Weekly project diaries
docs/iteration-reports/ Reports at the end of each iteration
docs/releases/          Release notes
```

## Getting started

### Prerequisites

- Java 21
- PostgreSQL 16 or later with the PostGIS extension
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

### Login token key

Login tokens are signed with a secret key, also read from an environment
variable. It must be at least 32 characters. To generate a random one:

```bash
export JWT_SECRET="$(openssl rand -base64 48)"
```

Add both exports to your shell profile (for example `~/.zshrc`), so they are
set in every terminal. Changing `JWT_SECRET` logs everyone out.

### Administrator account

Registering only creates hiker accounts. To get an administrator, set these
before starting the backend:

```bash
export ADMIN_EMAIL='<email>'
export ADMIN_PASSWORD='<password>'
```

On startup the backend creates that account, or, if the email is already
registered, makes it an administrator without changing its password. The
password must be at least 8 characters. With neither variable set, no
administrator is created.

### Run the backend

```bash
cd backend
./gradlew bootRun
```

The API runs on `http://localhost:8080`. The database tables are created
automatically on first start.

### Import trail data

The import needs an administrator's login token. Log in as the administrator
(see [API](#api)), then:

```bash
curl -X POST http://localhost:8080/api/admin/trails/import \
  -H "Authorization: Bearer <token>"
```

The first run returns `{"created":28,"updated":0}`. Running it again updates
the existing trails instead of creating duplicates.

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

The backend tests need PostgreSQL running, and `DB_PASSWORD` and `JWT_SECRET`
set.

```bash
cd mobile
flutter test
```

### Build the code documentation

The backend is documented with Doxygen and the app with `dart doc`, since
Doxygen does not support Dart. Both are built as HTML with one command, run
from the repository root:

```bash
./docs/build-docs.sh
```

| Part | Output |
|---|---|
| Backend | `backend/build/docs/doxygen/html/index.html`, with class diagrams |
| App | `mobile/build/docs/api/index.html` |

This needs Doxygen and Graphviz (on macOS: `brew install doxygen graphviz`)
and the Flutter SDK. The generated HTML is not committed; it is attached to
each GitHub release instead.

### Package a release

After a version is tagged on `main`, this builds the files attached to its
GitHub release into `build/release`: the code at the tag as a zip, the code
documentation, and a debug APK of the app.

```bash
./docs/package-release.sh v0.1
```

The working tree must be clean and checked out at the tag.

## API

| Method | Path | Login   | Description |
|---|---|---------|---|
| POST | `/api/auth/register` | No      | Creates an account and returns a login token |
| POST | `/api/auth/login` | No      | Returns a login token for an email and password |
| GET | `/api/auth/me` | Yes     | Returns the logged-in user's account |
| GET | `/api/trails` | No      | Returns every trail as GeoJSON, simplified for map display |
| GET | `/api/trails/search?q=&lat=&lon=&radiusKm=` | No      | Finds trails by name and/or within a radius of a position (nearest first), with each trail's latest condition |
| GET | `/api/trails/{id}` | No      | Returns one trail's details, current conditions and reports from the last 7 days |
| POST | `/api/trails/{id}/reports` | Yes     | Reports a trail's condition; sending the same `clientRef` again returns the stored report |
| POST | `/api/admin/trails/import` | Admin   | Imports County Laois trails from the Sport Ireland register |

Endpoints that need a login expect the token from register or login in an
`Authorization: Bearer <token>` header. Tokens expire after 7 days.

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
