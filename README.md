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
| Map display of imported trails | Planned |
| Condition report submission | Planned |
| Trail search by name and distance | Planned |

The mobile app is currently the Flutter starter template.

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
