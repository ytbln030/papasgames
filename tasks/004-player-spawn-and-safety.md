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

_Noch nicht ausgeführt._
