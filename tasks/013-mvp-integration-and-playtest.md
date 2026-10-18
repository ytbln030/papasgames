# Task 013 — MVP Integration & Playtest

## Ziel und erwartetes Verhalten

Dies ist der abschließende Integrationstask der MVP-Roadmap (Spec §47). Kein neues Modul wird angelegt; stattdessen wird der komplette End-to-End-Spielloop in Roblox Studio durchgespielt, die Bootstrap-Reihenfolge (`init.server.luau`/`init.client.luau`) finalisiert und gefundene Integrationslücken zwischen den Tasks 001–012 behoben.

## Voraussetzungen und Abhängigkeiten

Alle Tasks 001–012 müssen abgeschlossen sein.

## Betroffene Module

- `src/server/init.server.luau`, `src/client/init.client.luau` (finale Bootstrap-Reihenfolge, siehe [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 3)
- Punktuelle Bugfixes in beliebigen bestehenden Modulen aus Tasks 001–012, **ohne** deren festgelegte Schnittstellen zu ändern (Schnittstellenänderungen erfordern eine neue `decisions/`-Datei).

## Funktionale Anforderungen

1. Verifiziere und fixiere die Service-Init-Reihenfolge serverseitig: `BoardService → PlayerService → TargetService → BombService → GameService`.
2. Verifiziere und fixiere die Controller-Start-Reihenfolge client-seitig: `GameClientController → InputController → EffectsController` (Hud/Menu werden lazy von `GameClientController` erzeugt).
3. Spiele den vollständigen MVP-Loop aus Spec §47 mindestens dreimal vollständig durch:
   `Startscreen → PLAY → Board/Spawn/erstes Target → Bombe platzieren → Flucht → Explosion → SUCCESS/MISS/HIT_BY_EXPLOSION → Score/Level-Konsequenz → nächstes Target → … → Game Over → Startscreen → PLAY (neue Session)`.
4. Behebe dabei auftretende Integrationsfehler (z. B. `nil`-Zugriffe durch Aufruf-Reihenfolge, fehlende `WaitForChild`, Race Conditions zwischen Client-Beitritt und `Net.EnsureRemotes()`).

## Technische Vorgaben und Schnittstellen

Keine neuen Schnittstellen. Jede Änderung an einer bestehenden Funktionssignatur aus `ARCHITECTURE.md` Abschnitt 7 muss als neue Entscheidung in `decisions/` dokumentiert und in `ARCHITECTURE.md` nachgezogen werden.

## Bekannte zukünftige Anforderungen

Keine (Integrations-Task, keine Fachlogik).

## Out of Scope

- Jegliche in Tasks 001–012 als "Out of Scope" markierten Punkte (Backlog 014–018).
- Neue Features — dieser Task behebt ausschließlich Integrationslücken zwischen bereits spezifizierten Tasks.

## Akzeptanzkriterien

1. Der vollständige MVP-Loop aus Spec §47 läuft dreimal hintereinander ohne manuellen Eingriff außer den vom Spiel vorgesehenen Aktionen (Bewegen, `E`/Bomb-Button, `PLAY`).
2. Kein Server- oder Client-Fehler im Output-Fenster während der drei Durchläufe.
3. Jede der vier Fehlerquellen (Timeout, MISS, HIT_BY_EXPLOSION, Sturz) tritt mindestens einmal über die drei Durchläufe auf und wird korrekt behandelt.
4. Game Over → Restart funktioniert mindestens zweimal hintereinander ohne Neustart der Studio-Session.

## Teststrategie (manuell in Roblox Studio)

1. Frischen Play-Test starten (Studio-Neustart, um Reste vorheriger Sessions auszuschließen).
2. Drei vollständige Durchläufe des MVP-Loops wie oben beschrieben spielen, dabei bewusst mindestens einmal jede der vier Fehlerquellen provozieren.
3. Output-Fenster (Server und Client) durchgehend auf Fehler/Warnungen prüfen.
4. Gefundene Integrationsfehler beheben, betroffene Durchläufe wiederholen, bis alle Akzeptanzkriterien ohne Eingriff erfüllt sind.
5. Ergebnis inkl. Liste der gefundenen und behobenen Integrationsfehler dokumentieren.

## Definition of Done

- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.
- Gefundene Integrationsfehler sind behoben und die Fixes sind in den jeweiligen Modul-Dateien (nicht in dieser Task-Datei) enthalten.
- **Meilenstein erreicht:** MVP aus Spec §47 vollständig fertig und spielbar (siehe `ROADMAP.md`).

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
