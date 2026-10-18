# ROADMAP.md

Entwicklungsphasen, Reihenfolge und Abhängigkeiten für das Bomben-Kreuzungs-Spiel. Architektur-Hintergrund: [`ARCHITECTURE.md`](ARCHITECTURE.md). Vollständige Spezifikation: [`docs/SPEC.md`](docs/SPEC.md).

Ziel: So früh wie möglich ein minimal spielbares Spiel (Grundprinzip 7), danach schrittweise erweitern. `[P]` markiert Tasks, die parallel zu anderen `[P]`-Tasks derselben Phase bzw. zu bereits freigegebenen Tasks späterer Phasen bearbeitet werden können (keine gemeinsamen Dateien, keine gegenseitige Abhängigkeit).

## Abhängigkeitsgraph (DAG)

```
001 [P] ─┐
         ├─→ 004 [P] ─┐
002 [P] ─┼─→ 003 [P] ─┘            ├─→ 006 ─→ 007 ─→ 008 ─┐
         └───────────→ 005 ───────┘                        │
         └─────────────────────────────────────────→ 009 [P]
                                     006 ─┬─→ 010 [P] ┐
                                          ├─→ 011 [P] ┤
                                  007 ────┴─→ 012 [P] ┘
                                                        └─→ 013 (alle)
```

Keine zirkulären Abhängigkeiten. Zwei Konvergenzpunkte: **006** (Networking & State Machine) und **013** (Integration).

## Phase 0 — Fundament

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [001](tasks/001-world-and-starterplayer-baseline.md) | World & StarterPlayer Baseline | — | 002 |
| [002](tasks/002-shared-foundations.md) | Shared Foundations | — | 001 |

## Phase 1 — Welt & Spieler

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [003](tasks/003-board-system.md) | Board System | 002 (empfohlen nach 001) | 004 |
| [004](tasks/004-player-spawn-and-safety.md) | Player Spawn & Safety | 001, 002 | 003 |

## Phase 2 — Target & Netzwerk-Skelett

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [005](tasks/005-target-system.md) | Target System | 002, 003 | — |
| [006](tasks/006-networking-and-state-machine.md) | Networking & State Machine | 002, 003, 004, 005 | — (Konvergenzpunkt) |

## Phase 3 — Kernmechanik

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [007](tasks/007-bomb-and-explosion.md) | Bomb & Explosion | 003, 005, 006 | — |

## Phase 4 — Score & Level

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [008](tasks/008-scoring-and-level-progression.md) | Scoring & Level Progression | 006, 007 | — |

**Meilenstein: Minimal spielbares Spiel.** Nach Abschluss von 001–008 ist der komplette Kernloop (Start → Target → Bombe → Explosion → Score → nächstes Target → Game Over) serverseitig vollständig; es fehlen nur Eingabe/HUD/Menü/Feedback auf Client-Seite (Phase 5) für ein tatsächlich *spielbares* Erlebnis ohne Studio-Command-Bar.

## Phase 5 — Client-Erlebnis (weitgehend parallel)

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [009](tasks/009-input-controller.md) | Input Controller | 002 | 003–008, 010, 011, 012 |
| [010](tasks/010-game-hud.md) | Game HUD | 002, 006 | 009, 011, 012 |
| [011](tasks/011-main-menu-and-game-over.md) | Main Menu & Game Over | 002, 006 | 009, 010, 012 |
| [012](tasks/012-explosion-effects-and-feedback.md) | Explosion Effects & Feedback | 006, 007 | 009, 010, 011 |

## Phase 6 — Integration

| Task | Titel | Abhängig von | Parallel zu |
|---|---|---|---|
| [013](tasks/013-mvp-integration-and-playtest.md) | MVP Integration & Playtest | 001–012 | — |

**Meilenstein: MVP fertig** (Spec §47 vollständig manuell verifiziert).

---

## Backlog (bewusst nicht als volle Task-Dateien ausgearbeitet)

Diese Punkte sind in der Spec als "später" markiert (§32, §48, §53) oder explizit optional (§4). Sie werden erst in eigene `tasks/`-Dateien ausgearbeitet, wenn sie tatsächlich angegangen werden — vorheriges Ausarbeiten wäre "Features auf Vorrat" (Grundprinzip 3, WICHTIG-Hinweis).

- **014 — Combo-System** (Spec §29): Multiplikator ab 2/3/5 Treffern in Folge, Reset bei Fehlversuch. Betrifft `PlayerSessionData` (neues Feld `comboCount`) und `GameService`.
- **015 — Best-Score-Persistenz** (Spec §4, optional): `DataStoreService`-Anbindung für Startscreen-Bestleistung. Betrifft `MainMenuUI` und einen neuen `PersistenceService`.
- **016 — Level 4/5** (Spec §32): fehlende Kacheln (Löcher) in `BoardService`, Ablenk-/Fake-Kugeln in `TargetService`. Erfordert Erweiterung von `LevelConfigData`.
- **017 — Multiplayer-Grundgerüst** (Spec §2, §40–42): mehrere Spieler auf einem Board, gemeinsames oder individuelles Target (offene Frage, siehe `ARCHITECTURE.md` Abschnitt 10), Bomben-Sperre nach Fehlversuch.
- **018 — Hardcore-Modus** (Spec §52): Explosionstreffer führt zu Game Over statt Lebensverlust. Alternativer Konsequenz-Pfad in `GameService`.

## Spec-Abdeckung

Alle 53 Kapitel von `docs/SPEC.md` sind entweder einer Task (001–013) oder einem Backlog-Punkt (014–018) zugeordnet; kein Kapitel bleibt unberücksichtigt. Details zur Zuordnung einzelner Spec-Paragraphen stehen in den jeweiligen Task-Dateien und in `ARCHITECTURE.md`.
