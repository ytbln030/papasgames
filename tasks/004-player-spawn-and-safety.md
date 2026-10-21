# Task 004 — Player Spawn & Safety

## Ziel und erwartetes Verhalten

`PlayerService` platziert Spieler bei Charakter-Erzeugung auf einer zufälligen gültigen Kachel und reagiert auf Kontakt mit der `DeathZone` (Sturz vom Spielfeld, Spec §8), indem es das Ereignis nach oben meldet, ohne selbst Leben/Score zu verwalten (siehe [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 7).

## Voraussetzungen und Abhängigkeiten

- [Task 001](001-world-and-starterplayer-baseline.md): `DeathZone`-Part muss existieren.
- [Task 002](002-shared-foundations.md): `GameConfig`, `GameTypes`.
- [Task 003](003-board-system.md): `BoardService.GetRandomTile`, `GridToWorld`.

Kann parallel zu [Task 003](003-board-system.md) begonnen werden (Code-Entwurf), die finale manuelle Prüfung benötigt aber beide Tasks fertig.

## Betroffene Module

- `src/server/Services/PlayerService.luau` (neu)

## Funktionale Anforderungen

1. `PlayerService.SpawnPlayer(player: Player): ()`: Wartet auf `player.CharacterAdded` (falls noch nicht vorhanden), wählt per `BoardService.GetRandomTile()` eine gültige Kachel und setzt den Charakter mittig darauf (`GridToWorld` + Charakterhöhe).
2. `PlayerService.RespawnPlayer(player: Player): ()`: Gleiche Logik wie `SpawnPlayer`, aufrufbar ohne erneutes `CharacterAdded` (z. B. nach Sturz) — teleportiert den bestehenden Charakter.
3. Reaktion auf `Workspace.DeathZone.Touched`: Wenn das berührende Teil zu einem Spieler-Charakter gehört, feuert `PlayerService` ein eigenes Signal `PlayerFell(player: Player)` und ruft anschließend selbst `RespawnPlayer(player)` auf. `PlayerService` ändert dabei **keine** `PlayerSessionData` (Leben/Score) — das ist Aufgabe von `GameService` (Task 006/008), das sich auf `PlayerFell` abonniert.
4. Debounce: Ein Spieler darf durch denselben Sturz nicht mehrfach `PlayerFell` auslösen (z. B. kurze Sperre nach Respawn, bis der Charakter die `DeathZone` wieder verlassen hat).

## Technische Vorgaben und Schnittstellen

- Signal-Implementierung: einfaches, selbstgebautes Signal-Pattern (`BindableEvent` oder eine minimale Lua-Tabelle mit `Connect`/`Fire`) — kein externes Signal-Paket, konsistent mit [`decisions/004-no-external-framework.md`](../decisions/004-no-external-framework.md).
- `PlayerService` darf `BoardService` requiren, aber nicht umgekehrt (einseitige Abhängigkeit).
- Keine direkte Abhängigkeit auf `GameService` (Inversion: `GameService` abonniert `PlayerService.PlayerFell`, nicht umgekehrt).

## Bekannte zukünftige Anforderungen

- Multiplayer (Backlog 017): `SpawnPlayer`/`RespawnPlayer` sind bereits pro-`Player` parametrisiert, keine Signaturänderung nötig für mehrere Spieler gleichzeitig.

## Out of Scope

- Lebensverlust-Logik, Score, Game-Over-Entscheidung (Task 006/008).
- Erste Target-Generierung nach Spawn (Task 005/006, siehe [`decisions/006-spawn-before-target.md`](../decisions/006-spawn-before-target.md)).
- Sprung-/Kamera-Konfiguration (bereits in Task 001 per `default.project.json` erledigt).

## Akzeptanzkriterien

1. Jeder neu erzeugte Charakter steht nach `SpawnPlayer` mittig auf einer gültigen Board-Kachel, niemals außerhalb des Boards.
2. Fallen unter `GameConfig.DeathY` löst genau einmal `PlayerFell` aus und respawnt den Spieler sicher auf dem Board.
3. Wiederholtes Herunterlaufen vom Rand (absichtlicher Sturz, Spec §8) funktioniert beliebig oft ohne Fehler oder doppelte Events pro Sturz.
4. `PlayerService` verändert nachweislich keine Score-/Lebens-Daten (es gibt zu diesem Zeitpunkt noch keine solche Datenstruktur in diesem Modul).

## Teststrategie (manuell in Roblox Studio)

1. Play-Test starten, prüfen, dass der Charakter sofort mittig auf einer Kachel steht (nicht in der Luft, nicht am Rand hängend).
2. Mehrfach vom Rand herunterlaufen, jedes Mal `PlayerFell`-Print beobachten (genau einmal pro Sturz) und sicheren Respawn bestätigen.
3. Kurz hintereinander zweimal fallen (zweiter Sturz direkt nach Respawn) und prüfen, dass kein doppeltes/verzögertes Event für denselben Sturz auftritt.
4. Mit mehreren Testspielern (falls in Studio simulierbar) parallel spawnen lassen und prüfen, dass sie nicht auf derselben Kachel landen (soweit `GetRandomTile` das zulässt — kein Hard-Requirement, nur Beobachtung).
5. Ergebnis dokumentieren.

## Definition of Done

- `PlayerService.luau` implementiert mit `SpawnPlayer`, `RespawnPlayer`, `PlayerFell`-Signal.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

**Status: Abgeschlossen.** Alle Akzeptanzkriterien manuell über die Roblox-Studio-MCP-Tools (verbundene Instanz „Papas game", `rojo serve` + Live-Sync) tatsächlich verifiziert, siehe Prüfprotokoll unten. Ein während der Prüfung gefundener echter Mehrfachauslöse-Bug wurde behoben (siehe unten).

### Durchgeführte Änderungen

- [`src/server/Services/PlayerService.luau`](../src/server/Services/PlayerService.luau) (neu): `SpawnPlayer`, `RespawnPlayer`, `PlayerFell`-Signal (selbstgebaute Connect-Tabelle, `Fire` bewusst modul-intern gekapselt) sowie `Init()` implementiert.
  - `placeCharacterOnRandomTile` nutzt `BoardService.GetRandomTile()` + `GridToWorld` und berechnet den Boden-Offset (`Humanoid.HipHeight + HumanoidRootPart.Size.Y / 2`), damit der Charakter mit den Füßen auf der Kachel-Oberfläche steht, nicht mit dem RootPart-Zentrum. `SpawnPlayer`/`RespawnPlayer` sind beide dünne Wrapper darüber (Funktionale Anforderungen 1+2).
  - `Init()` bindet `Workspace.DeathZone.Touched`/`TouchEnded` einmalig (idempotent via Guard-Flag, analog zum Idempotenz-Pattern von `BoardService.CreateBoard` aus Task 003) und räumt `fallLocked` bei `Players.PlayerRemoving` auf. Da es in der Architektur noch keinen Composition Root gibt (`init.server.luau` ist weiterhin der Platzhalter aus Task 001, wird erst in Task 006 ersetzt), wurde `Init()` für die manuelle Prüfung direkt per `execute_luau` aufgerufen — exakt wie `BoardService.CreateBoard` in Task 003 gehandhabt.
  - **Wichtige Korrektur gegenüber der ursprünglichen Implementierung:** Die Reaktion auf `DeathZone.Touched`/`TouchEnded` reagiert bewusst **nur** auf das `HumanoidRootPart` des Charakters, nicht auf jedes der ca. 14 R15-Körperteile. Begründung siehe Abschnitt "Gefundener Bug" unten.

### Gefundener Bug und Korrektur (außerhalb der ursprünglichen Spezifikation, aber notwendig für Akzeptanzkriterium 2/3)

Die erste Implementierung band `onDeathZoneTouched`/`onDeathZoneTouchEnded` auf **jedes** berührende `BasePart` (ungefiltert, wie der Tasktext es nahelegt: „Wenn das berührende Teil zu einem Spieler-Charakter gehört"). Bei der Play-Test-Prüfung zeigte sich reproduzierbar (siehe Prüfung 2 unten), dass `PlayerFell` dabei **nicht zuverlässig genau einmal pro Sturz** feuerte, sondern teils 2× oder sogar mehrfach verzögert erneut, obwohl der Charakter bereits sicher auf einer gültigen Kachel stand. Ursache (per Diagnose-Listener auf `DeathZone.Touched`/`TouchEnded` mit Zeitstempeln nachgewiesen): Ein R15-Charakter berührt die `DeathZone` beim Sturz mit ca. 14 einzelnen `BasePart`s, deren `Touched`/`TouchEnded`-Events zeitlich überlappen (manche Teile melden „verlassen", während andere Teile desselben Sturzes noch gar nicht als „berührend" registriert wurden). Ein Debounce, der beim *ersten* `TouchEnded` freigibt, ist dadurch eine Race Condition und kann `PlayerFell` mehrfach für denselben Sturz auslösen — auch ein Zähler über alle Körperteile löste das Problem nicht zuverlässig (Teile können über mehrere Physik-Schritte hinweg verzögert nachregistrieren). Die Korrektur beschränkt die Reaktion auf das `HumanoidRootPart` als einzige, kanonische Positionsreferenz des Charakters — danach feuerte `PlayerFell` in allen Testläufen (siehe unten) zuverlässig exakt einmal pro Sturz, auch bei unmittelbar aufeinanderfolgenden Stürzen und bei doppeltem `Init()`-Aufruf (Idempotenz-Test). Dies ist eine notwendige Abweichung von der wörtlichen Formulierung „wenn das berührende Teil zu einem Spieler-Charakter gehört" (die Spec schließt eine Einschränkung auf ein bestimmtes Teil nicht aus), aber keine Abweichung von `ARCHITECTURE.md` oder einer `decisions/`-Datei, daher wurde keine neue Decision-Datei angelegt.

### Durchgeführte Prüfungen

Play-Session gestartet, pro Server-VM (Server-Datamodel neu bei jedem Play-Start, siehe bereits in Task 003 dokumentiertes Verhalten) `BoardService.CreateBoard(LevelConfig.GetConfig(1))` und `PlayerService.Init()` per `execute_luau` aufgerufen, zusätzlich ein Diagnose-Listener an `PlayerService.PlayerFell` gehängt, der einen Zähler hochzählt und mit Zeitstempel printet.

1. **AC1 (Spawn mittig auf gültiger Kachel):** `PlayerService.SpawnPlayer(player)` aufgerufen. `HumanoidRootPart.Position` lag exakt zentriert über einer gültigen Kachel (`BoardService.WorldToGrid` lieferte z. B. `(16,30)`, `(14,2)`, `(25,23)` — jeweils `IsValidTile = true`, horizontaler Versatz zum Kachel-Mittelpunkt `dx = dz = 0.000`), `Y = 3.5` entspricht exakt `tileTop.Y (0.5) + groundOffset (HipHeight 2.0 + HumanoidRootPart.Size.Y/2 1.0 = 3.0)`. In mehreren Server-VM-Durchläufen wiederholt reproduziert.
2. **AC2/AC3 (genau 1× `PlayerFell` pro Sturz, beliebig oft wiederholbar) — inkl. gefundenem Bug und Fix:**
   - Erstimplementierung (reagiert auf alle Körperteile): Charakter per `character:PivotTo(CFrame.new(x, -49, z))` in die `DeathZone` teleportiert (simuliert Sturz unter `DeathY`). Ergebnis zunächst **nicht bestanden**: einzelne Durchläufe zeigten `PlayerFell`-Zähler-Delta von 2 statt 1 pro Sturz, in einem Fall sogar verzögert +2 weitere Male Sekundenbruchteile nach einem bereits stabilen Respawn auf einer gültigen Kachel (per 50ms-Sampling der Position und des Zählers über 0,5 s nach dem Sturz nachgewiesen). Mit zusätzlichem Diagnose-Listener direkt auf `DeathZone.Touched`/`TouchEnded` (Part-Name + Zeitstempel) wurde die Ursache (überlappende Touch-Events vieler Körperteile) identifiziert.
   - Nach der Korrektur (nur `HumanoidRootPart`): 50ms-Sampling über 0,5 s nach einem einzelnen Sturz zeigt `fellCount` konstant bei 1, kein weiterer Anstieg. Anschließend 5 aufeinanderfolgende Stürze (je 1 s Abstand, zufällige Positionen) ausgeführt: **jeder einzelne Sturz lieferte exakt Delta = 1** und landete auf einer laut `BoardService.IsValidTile` gültigen Kachel.
3. **AC3 (zwei Stürze kurz hintereinander, zweiter direkt nach Respawn):** Sturz 1, nach nur 0,4 s (deutlich kürzer als eine realistische Spieler-Reaktionszeit) sofort Sturz 2 ausgelöst. Beide lösten je genau einmal `PlayerFell` aus (Delta 1 + Delta 1) und respawnten beide Male korrekt auf einer gültigen Kachel — kein doppeltes/verzögertes Event, keine Blockade des zweiten Sturzes.
4. **Idempotenz von `Init()`:** `PlayerService.Init()` zusätzlich zweimal erneut aufgerufen (simuliert versehentlichen Doppelaufruf, relevant für den künftigen Composition Root in Task 006), anschließend erneuter Sturz-Test: weiterhin exakt Delta = 1, keine doppelten Listener-Registrierungen.
5. **AC4 (keine Score-/Lebens-Mutation):** Durch Code-Inspektion bestätigt — `PlayerService.luau` enthält keinerlei Referenz auf `PlayerSessionData`, `lives` oder `score`; das Modul kennt nur `Player`-Instanzen und `GridPosition`/`Vector3`. `GameService` existiert zu diesem Zeitpunkt im Projekt noch nicht (folgt erst in Task 006/008).
6. **Konsole:** `get_console_output` nach allen Testläufen geprüft — insgesamt genau 9 `PlayerFell`-Prints für 9 tatsächlich ausgelöste Stürze (1 Einzeltest + 5er-Schleife + 2 Schnellfolge-Stürze + 1 Idempotenz-Test = 9, exakte Übereinstimmung), keine zusätzlichen/fehlenden Events. Keine Fehler oder Warnungen im Zusammenhang mit `PlayerService`; vorhandene Meldungen (UIBlox-`FoundationProvider`-Warnung, `rbxassetid://203785492`-Content-Load-Fehler) sind bereits aus Task 003 bekanntes, unabhängiges Engine-/CoreGui-Rauschen.
7. **Punkt 4 der Teststrategie (mehrere Testspieler, keine Kollision auf derselben Kachel):** Nicht durchgeführt — in dieser Studio-Session war nur ein einzelner Testspieler verfügbar (kein Hard-Requirement laut Task-Text, nur Beobachtung). `BoardService.GetRandomTile()` wurde dafür bereits in Task 003 separat über 200 Aufrufe auf korrekte, exklusionskonforme Zufallsverteilung geprüft; `SpawnPlayer`/`RespawnPlayer` rufen diese Funktion unverändert pro Aufruf auf, eine Kollisionsvermeidung zwischen mehreren Spielern ist wie im Architekturdokument beschrieben kein Hard-Requirement.
8. Der während der Prüfung per Play-Test erzeugte `Workspace.Board` sowie alle `_G.Task004_*`-Debug-Referenzen und Diagnose-Listener existierten nur innerhalb der jeweiligen Play-Session und sind nach `start_stop_play(false)` nicht mehr Teil des Edit-Mode-Zustands (reine Laufzeit-Erzeugung, kein Teil des Repositories, analog zum Umgang in Task 001/003).

### Neue Architekturentscheidungen

Keine neue Datei unter `decisions/`. Die Einschränkung der `DeathZone`-Reaktion auf `HumanoidRootPart` (statt auf jedes Körperteil) ist eine Implementierungsdetail-Entscheidung innerhalb der von `ARCHITECTURE.md` Abschnitt 7 vorgegebenen Schnittstelle (`PlayerFell(player: Player)` bleibt unverändert; nur die interne Trigger-Bedingung wurde präzisiert) und widerspricht keiner bestehenden Decision.

### Auswirkungen auf spätere Tasks

- Task 005/006 (`TargetService`/`GameService`): `PlayerService.SpawnPlayer`/`RespawnPlayer` und `PlayerFell` können wie in `ARCHITECTURE.md` Abschnitt 7 spezifiziert verwendet werden; `GameService` muss sich lediglich auf `PlayerService.PlayerFell:Connect(...)` abonnieren, wie in Decision 008 vorgesehen.
- Task 006 (Composition Root): `init.server.luau` muss `PlayerService.Init()` nach `BoardService.CreateBoard(...)` aufrufen (Bootstrap-Reihenfolge `BoardService → PlayerService → ...`), sonst reagiert `PlayerService` nicht auf `DeathZone`-Kontakt — analog zum in Task 003 dokumentierten Hinweis, dass `BoardService.CreateBoard` einmalig beim `RequestPlay`-Handling aufgerufen werden muss.
- Die aus Task 001 bekannte, nicht Rojo-verwaltete `Workspace.SpawnLocation`-Altlast (reiner Studio-Sitzungszustand) wurde für diese Prüfung bewusst nicht entfernt (außerhalb des Task-Scopes, siehe Task 001 Ergebnis); sie beeinflusste die Tests nicht, da `SpawnPlayer`/`RespawnPlayer` den Charakter unabhängig von seiner Ausgangsposition aktiv auf eine Board-Kachel teleportieren.
