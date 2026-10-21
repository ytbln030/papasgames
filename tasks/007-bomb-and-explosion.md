# Task 007 — Bomb & Explosion

## Ziel und erwartetes Verhalten

`BombService` implementiert die namensgebende Kernmechanik: Bombe auf der Spieler-Kachel platzieren, Gefahrenzone sichtbar machen, nach der Fuse explodieren und Treffer validieren. Nach diesem Task ist der komplette Spec-Kernloop (§18–§26) serverseitig funktionsfähig und per Command-Bar/Client-Intent auslösbar.

## Voraussetzungen und Abhängigkeiten

[Task 003](003-board-system.md), [Task 005](005-target-system.md), [Task 006](006-networking-and-state-machine.md) müssen abgeschlossen sein (insbesondere das `BombService`-Platzhaltermodul aus Task 006, falls vorhanden — wird hier vollständig ersetzt).

## Betroffene Module

- `src/server/Services/BombService.luau` (vollständige Implementierung, ersetzt ggf. Platzhalter aus Task 006)
- `src/server/Services/GameService.luau` (Erweiterung: Handler für `ClientAction{type="PlaceBomb"}`, State-Übergänge `TARGET_ACTIVE → BOMB_PLACED → EXPLODING → ROUND_RESULT`)
- `src/shared/Net/Net.luau` (Ergänzung der `GameEventType`-Werte `BombPlaced`, `RoundResult`, falls in Task 006 noch nicht vollständig ergänzt)

## Funktionale Anforderungen

### `BombService`
1. `BombService.TryPlaceBomb(player: Player): ()` — wird von `GameService` beim Empfang von `ClientAction{type="PlaceBomb"}` aufgerufen, **nur** wenn `session.state == "TARGET_ACTIVE"` und der Spieler für das aktuelle Target noch keine Bombe platziert hat (Spec §18, §50: genau 1 Bombe pro Target, weitere Versuche werden ignoriert).
2. Bestimmt die Spieler-Kachel via `BoardService.GetTileAtWorldPosition(player.Character...)` (Spec §19 — niemals Weltkoordinaten direkt vergleichen) und snapt die Bombe exakt auf deren Mittelpunkt.
3. Bewegt den Spieler nach Platzierung automatisch einen kleinen Schritt zurück (`GameConfig.BombRecoilStuds`, entgegen seiner Blickrichtung, Spec §19 letzter Absatz).
4. Erzeugt das Gefahrenzonen-Weltvisual (Ring/markierte Kacheln, Radius `GameConfig.SafeDistanceTiles * GameConfig.TileSize`) gemäß [`decisions/005-danger-zone-world-visual.md`](../decisions/005-danger-zone-world-visual.md).
5. Meldet dem aufrufenden `GameService` sofort den State-Übergang zu `BOMB_PLACED` (stoppt implizit den Target-Timer, Spec §17 letzter Satz — `TargetService`s Timer wird von `GameService` beim State-Wechsel gestoppt, nicht von `BombService` selbst).
6. Startet die Fuse (`levelConfig.BombFuse` Sekunden, Spec §21).
7. Nach Ablauf der Fuse: Explosion (Licht/Partikel/Sound/Signal für Camera-Shake, Spec §23), Entfernung von Gefahrenzonen-Visual und Bomben-Part, Validierung:
   - Bedingung 1: `TargetService.ValidateBombTile(bombTile)`.
   - Bedingung 2: Distanz zwischen Spieler und Bombenkachel-Mittelpunkt `>= GameConfig.SafeDistanceTiles * GameConfig.TileSize` (Weltdistanz, Spec §22 — hier bewusst Weltkoordinaten, da es eine physische Fluchtdistanz ist, keine Grid-Logik-Frage).
   - Ergebnis-Mapping (Spec §24): beide erfüllt → `"SUCCESS"`; Bedingung 1 falsch (unabhängig von Bedingung 2) → `"MISS"`; Bedingung 1 erfüllt, Bedingung 2 falsch → `"HIT_BY_EXPLOSION"`. Pro Target wird **höchstens ein** Ergebnis erzeugt — die beiden Bedingungen werden nicht addiert.
   - Zerstört bei `SUCCESS` zusätzlich die vier Zielkugeln (`TargetService.DestroyActiveTarget`); bei `HIT_BY_EXPLOSION` werden die Kugeln ebenfalls zerstört (Spec §24: "Kugeln werden zerstört"); bei `MISS` verschwinden die Zielkugeln nach kurzer `MISS`-Einblendung (Spec §26) — `BombService` ruft dafür `TargetService.DestroyActiveTarget` mit kurzer Verzögerung bzw. `GameService` steuert die Verzögerung, `BombService` liefert nur das Ergebnis.
   - Gibt das `BombOutcome` an `GameService` zurück (Callback/Event), **ohne** selbst `lives`/`score` zu verändern.

### `GameService`-Erweiterung
1. Empfängt `ClientAction{type="PlaceBomb"}` und delegiert an `BombService.TryPlaceBomb`.
2. Reagiert auf das `BombOutcome` von `BombService`: setzt State `ROUND_RESULT`, broadcastet `GameEvent{type="RoundResult", outcome=...}`; Lebens-/Score-Konsequenzen werden in Task 008 vervollständigt — für diesen Task reicht ein korrekter State-Übergang plus korrektes `BombOutcome`-Mapping als nachweisbares Ergebnis.

## Technische Vorgaben und Schnittstellen

- `BombService` requiert `BoardService`, `TargetService`, `GameConfig`; **nicht** `GameService` (Inversion of Control wie bei `PlayerService`).
- Alle Zeit-/Fuse-Logik über `task.delay`/`task.spawn`, keine blockierenden `wait()`-Schleifen.
- Die Gefahrenzone ist ein reines Darstellungsobjekt ohne eigene Trefferlogik — die eigentliche Abstandsprüfung erfolgt rein rechnerisch (Punkt 4 oben), nicht über Kollision mit dem Visual.

## Bekannte zukünftige Anforderungen

- Hardcore-Modus (Backlog 018): `HIT_BY_EXPLOSION` würde dort zu `GAME_OVER` statt Lebensverlust führen — das Mapping bleibt in `BombService` unverändert, nur die Konsequenz in `GameService` ändert sich.
- Multiplayer-Bombensperre (Spec §41, Backlog 017): `TryPlaceBomb`s "eine Bombe pro Spieler pro Target"-Guard ist bereits pro-`Player`, eine zusätzliche Zeitsperre ließe sich dort ergänzen.

## Out of Scope

- Tatsächliche Score-Berechnung/Level-Aufstieg/Game-Over-Entscheidung (Task 008).
- HUD-Anzeige des Countdowns/Gefahrenzone auf dem Client (Task 010/012 — hier nur das serverseitige Weltobjekt).

## Akzeptanzkriterien

1. Bombe erscheint exakt auf der Kachel, auf der der Spieler zum Platzierungszeitpunkt stand (Grid-Snap, kein Versatz).
2. Zweite Platzierungsanfrage im selben Target wird ignoriert (keine zweite Bombe, kein Fehler).
3. Korrekte Kachel + ausreichender Abstand → `SUCCESS`, Zielkugeln werden zerstört.
4. Falsche Kachel → `MISS`, unabhängig vom Spielerabstand.
5. Korrekte Kachel + Spieler zu nah → `HIT_BY_EXPLOSION`, Zielkugeln werden ebenfalls zerstört, aber als anderes Ergebnis als `SUCCESS` erkennbar.
6. In keinem Fall wird mehr als ein Ergebnis pro Target erzeugt (kein doppelter State-Übergang).
7. Gefahrenzonen-Visual ist während der gesamten Fuse sichtbar und danach vollständig entfernt (kein Leak hängender Parts nach mehreren Runden).

## Teststrategie (manuell in Roblox Studio)

1. Play-Test: Auf die bekannte Zielkachel stellen (z. B. per Command-Bar-Teleport zur `TargetData.center`-Position), Bombe platzieren (`E`-Taste, falls Task 009 schon existiert, sonst direkter `BombService.TryPlaceBomb(player)`-Aufruf in der Command-Bar), stehen bleiben → `HIT_BY_EXPLOSION` erwarten.
2. Gleiches Setup, aber nach Platzierung mindestens `SafeDistance` weit weglaufen → `SUCCESS` erwarten.
3. Auf eine falsche Kachel stellen und platzieren → `MISS` erwarten, unabhängig von der Fluchtdistanz.
4. Direkt nach Platzierung erneut die Platzierungsaktion auslösen → keine zweite Bombe, kein Fehler im Output.
5. Mehrere Runden hintereinander spielen und `Workspace` auf verbliebene Bomben-/Gefahrenzonen-Parts aus vorherigen Runden prüfen (sollten vollständig entfernt sein).
6. Ergebnis dokumentieren.

## Definition of Done

- `BombService.luau` vollständig implementiert, `GameService` entsprechend erweitert.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

**Status: abgeschlossen.**

### Umsetzung

- `BombService.luau` vollständig implementiert: Kachel-Snap via `BoardService.GetTileAtWorldPosition`, Rückstoß (`GameConfig.BombRecoilStuds`, entgegen Blickrichtung, Fallback-Richtung bei senkrechtem Blick), Bomben-/Gefahrenzonen-Weltvisual (Folder `Bomb` mit `BombPart` + `DangerZone`-Part, Radius `SafeDistanceTiles * TileSize`), Fuse über `task.delay(levelConfig.BombFuse, ...)`, Explosion via `Instance.new("Explosion")` (Licht/Partikel/Sound ohne eigene Asset-Ids, `BlastPressure = 0`/`DestroyJointRadiusPercent = 0` um Physik-Seiteneffekte zu vermeiden), Validierung (Bedingung 1/2) und Ergebnis-Mapping exakt wie spezifiziert. Höchstens eine Bombe pro Spieler pro Target über `bombPlacedForTarget[player] = activeTarget.id`.
- **Architektur-Abweichung mit Begründung:** `TryPlaceBomb` liefert das Explosionsergebnis **nicht** als Rückgabewert (wie noch in `ARCHITECTURE.md` vor diesem Task dokumentiert), sondern synchron nur den Platzierungserfolg (`boolean`) plus zwei neue Signale `BombService.BombExploded`/`BombService.BombResolved` für das asynchrone Ergebnis — das ist mit „keine blockierenden `wait()`-Schleifen" nicht anders lösbar. Siehe [`decisions/009-bomb-outcome-via-signal.md`](../decisions/009-bomb-outcome-via-signal.md); `ARCHITECTURE.md` Abschnitt 7 wurde entsprechend aktualisiert (BombService- und GameService-Eintrag). `TryPlaceBomb` nimmt zusätzlich `levelConfig: LevelConfigData` als Parameter (für `levelConfig.BombFuse`), analog zu `TargetService.CreateTarget`.
- `GameService.luau` erweitert: `onPlaceBomb` delegiert bei `state == "TARGET_ACTIVE"` an `BombService.TryPlaceBomb`, setzt bei Erfolg `BOMB_PLACED` und broadcastet `BombPlaced`. Neue Handler `onBombExploded` (→ `EXPLODING`) und `onBombResolved` (→ `ROUND_RESULT`, broadcastet `RoundResult{outcome=...}`) sind an die neuen `BombService`-Signale angebunden. Volle State-Kette `TARGET_ACTIVE → BOMB_PLACED → EXPLODING → ROUND_RESULT` steht.
- `Net.luau`: `BombPlaced`/`RoundResult` waren bereits aus Task 006 vorhanden, keine Änderung nötig.
- `GameClientController.luau` bewusst **nicht** geändert (nicht in Betroffene Module gelistet; Client-Reaktion auf `BombPlaced`/`RoundResult` ist Task 009/010/012).

### Durchgeführte Prüfungen (Roblox Studio MCP, Play-Test)

Alle Prüfungen über echten Netzwerkfluss (`ClientAction`-Remote von Client, Beobachtung über `GameEvent`-Remote und `Workspace`-Instanzen), da direkte `require()`-Aufrufe über die Command-Bar in einem isolierten Modul-Cache laufen und nicht den Zustand der echten, laufenden Services widerspiegeln (Erkenntnis während der Prüfung, kein Code-Bug).

1. **HIT_BY_EXPLOSION**: Spieler exakt auf `TargetData.center` teleportiert, `PlaceBomb` gefeuert, stehen geblieben → Events `BOMB_PLACED → EXPLODING → ROUND_RESULT`, `RoundResult{outcome="HIT_BY_EXPLOSION"}`. `Target`- und `Bomb`-Folder danach restlos entfernt. ✅
2. **SUCCESS**: Gleiches Setup, nach Platzierung 50 Studs weggeteleportet (weit über `SafeDistance` = 12 Studs) innerhalb der 2s-Fuse → `RoundResult{outcome="SUCCESS"}`. ✅
3. **MISS**: Spieler auf die Kachel der „Left"-Zielkugel (≠ Center) gestellt → `RoundResult{outcome="MISS"}`, unabhängig davon, dass der Spieler nicht weggelaufen ist (Bedingung 1 schlägt zuerst zu, Spec §24 „nicht addiert"). Zusätzlich gezielt die `MISS`-Einblendung geprüft: Zielkugeln existieren noch unmittelbar nach Fuse-Ende (2,3s), sind aber nach der kurzen Verzögerung (3,5s) entfernt. ✅
4. **Doppelte Platzierung**: Dreimal `PlaceBomb` in schneller Folge gefeuert (davon zwei nahezu gleichzeitig) → genau 1× `BombPlaced`, genau 1× `RoundResult`, keine Fehler im Output. ✅
5. **Mehrere Runden / keine Leaks**: Fünf Runden (`RequestPlay` mehrfach) hintereinander gespielt (Timeout-, Hit-, Success-, Miss- und Doppel-Platzierungs-Fall) → `Workspace` enthält am Ende genau einen `Board`-Folder (kein Duplikat dank bestehendem `BoardService`-Guard) und keinen verbliebenen `Target`- oder `Bomb`-Folder. Keine Fehler/Warnings im Konsolen-Output außer unabhängigem UIBlox-CoreScript-Rauschen. ✅

### Neue Architekturentscheidungen

- [`decisions/009-bomb-outcome-via-signal.md`](../decisions/009-bomb-outcome-via-signal.md) — `TryPlaceBomb`-Signatur und asynchrone Ergebnislieferung per Signal statt Rückgabewert (siehe oben).
