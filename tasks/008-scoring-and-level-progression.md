# Task 008 — Scoring & Level Progression

## Ziel und erwartetes Verhalten

`GameService` wird um die vollständige, geprüfte Konsequenz-Logik ergänzt: Punkte- und Zeitbonus-Berechnung, Level-Aufstieg, Lebensverlust für alle vier Fehlerquellen (Timeout, falsche Bombe, Explosionstreffer, Sturz) und Game-Over-Übergang. Nach diesem Task ist der komplette serverseitige MVP-Kernloop aus `docs/SPEC.md` §47 fertig — nur Client-Eingabe/-Darstellung fehlt noch (Phase 5).

## Voraussetzungen und Abhängigkeiten

[Task 006](006-networking-and-state-machine.md) und [Task 007](007-bomb-and-explosion.md) müssen abgeschlossen sein (ersetzt deren Platzhalter-Konsequenzlogik vollständig).

## Betroffene Module

- `src/server/Services/GameService.luau` (Erweiterung, keine neuen Dateien)

## Funktionale Anforderungen

1. **Erfolg (`SUCCESS`):** `score += GameConfig.Scoring.BasePoints + math.floor(restzeitInSekunden * GameConfig.Scoring.TimeBonusPerSecond)`; `levelScore` um denselben Betrag erhöhen. `restzeitInSekunden` = verbleibende Zeit des Target-Timers zum Platzierungszeitpunkt (nicht zum Explosionszeitpunkt — die Fuse-Zeit zählt nicht als "Restzeit", Spec §28 bezieht sich auf die Geschwindigkeit der *Erkennung*, nicht der Flucht).
2. **Lebensverlust (genau 1 Leben, nie kumuliert, Spec §24 letzter Satz):** bei `MISS`, bei `HIT_BY_EXPLOSION`, bei abgelaufenem Target (`TargetExpired` ohne platzierte Bombe), bei Sturz (`PlayerFell`, siehe [`decisions/008-fall-does-not-reset-target.md`](../decisions/008-fall-does-not-reset-target.md) — Leben wird abgezogen, Target bleibt aber unverändert aktiv).
3. **Level-Aufstieg:** Sobald `levelScore >= LevelConfig.GetConfig(level).ScoreRequired`, wird `level += 1` und `levelScore = 0` gesetzt (Gesamt-`score` bleibt unverändert, Spec §30); alle **neuen** Targets verwenden ab dann `LevelConfig.GetConfig(level)` (Timer/Distanzen ändern sich, `BoardSize` bleibt gemäß [`decisions/007`](../decisions/007-board-size-fixed-per-session.md) unverändert).
4. **Game Over:** Sobald `lives <= 0` nach einem Lebensverlust, State → `GAME_OVER` statt eines neuen Targets; `GameEvent{type="GameOver", score=...}` wird broadcastet. Kein neues Target wird mehr erzeugt, bis ein neuer `RequestPlay`-Intent eintrifft.
5. **Nach jedem Fehlversuch (kein Game Over):** unmittelbar neues Target (Spec §17, §26) — State-Übergang `ROUND_RESULT → NEXT_TARGET → TARGET_ACTIVE`, Timer des neuen Targets läuft sofort.
6. **Nach Erfolg:** Nach ca. 0.5–1 Sekunde Verzögerung (Spec §25) ebenfalls automatisch neues Target.
7. `GameEvent{type="ScoreUpdated", score, levelScore, level}` wird nach jeder Score-/Level-Änderung broadcastet.

## Technische Vorgaben und Schnittstellen

- Diese Logik lebt vollständig in `GameService` — `BombService`/`TargetService`/`PlayerService` bleiben unverändert (sie liefern nur Ereignisse/Outcomes, keine Lebens-/Score-Mutation, siehe `ARCHITECTURE.md` Abschnitt 7).
- Ein einziger interner Pfad "Fehlversuch verarbeiten" (z. B. `GameService:HandleFailure(player, reason)`) wird von allen vier Fehlerquellen aufgerufen, um Code-Duplikation und inkonsistente Lebens-Abzüge zu vermeiden.

## Bekannte zukünftige Anforderungen

- Combo-System (Backlog 014): würde in `HandleFailure`/Erfolgspfad einen Reset bzw. Multiplikator ergänzen, ohne die bestehende Struktur umzubauen.
- Hardcore-Modus (Backlog 018): alternativer Zweig in `HandleFailure` für `HIT_BY_EXPLOSION` (Game Over statt Lebensverlust).

## Out of Scope

- Darstellung von Score/Level/Timer im HUD (Task 010).
- Persistenz der Bestleistung (Backlog 015).

## Akzeptanzkriterien

1. Beispielrechnung aus Spec §28 reproduzierbar: Erfolg bei 12s Restzeit ergibt `100 + 120 = 220` Punkte.
2. Nach Erreichen von `ScoreRequired` für Level 1 (1000) steigt das Level auf 2, `levelScore` wird auf 0 zurückgesetzt, `score` bleibt bei ≥1000 erhalten, das nächste Target verwendet `TargetLifetime = 18`.
3. Jede der vier Fehlerquellen (Timeout, MISS, HIT_BY_EXPLOSION, Sturz) zieht genau 1 Leben ab, niemals mehr als 1 pro Vorfall.
4. Bei `lives == 0` wechselt der State zu `GAME_OVER`, es wird kein weiteres Target erzeugt.
5. Nach jedem Fehlversuch (außer Game Over) erscheint unmittelbar ein neues Target; nach Erfolg nach kurzer Verzögerung.

## Teststrategie (manuell in Roblox Studio)

1. Mehrere `SUCCESS`-Runden mit bekannter Restzeit durchspielen und die Punkteberechnung gegen die Formel manuell nachrechnen.
2. Level-1-`ScoreRequired` temporär auf einen niedrigen Testwert setzen, Level-Aufstieg provozieren, `TargetLifetime`-Änderung des nächsten Targets beobachten (Server-Print).
3. Für jede der vier Fehlerquellen einzeln einen Vorfall provozieren und `lives`-Wert vor/nach vergleichen (Server-Print).
4. Mit `lives = 1` einen weiteren Fehlversuch provozieren und Game-Over-Übergang beobachten; prüfen, dass danach kein neues Target mehr entsteht, bis `RequestPlay` erneut gefeuert wird.
5. Ergebnis dokumentieren.

## Definition of Done

- `GameService.luau` enthält die vollständige, oben beschriebene Logik.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.
- **Meilenstein erreicht:** kompletter serverseitiger MVP-Kernloop funktionsfähig (siehe `ROADMAP.md`).

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
