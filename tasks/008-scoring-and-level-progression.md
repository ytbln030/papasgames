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

Implementiert in `GameService.luau` (gemeinsamer `handleFailure`-Pfad für alle vier Fehlerquellen, `applySuccessScore`, `spawnNextTarget`). Alle fünf Teststrategie-Schritte wurden tatsächlich in Roblox Studio durchgespielt (Play Solo, über die Roblox-Studio-MCP-Tools: `RequestPlay`/`PlaceBomb` per echtem `RemoteEvent` vom Client aus gefeuert, Positionierung server-autoritativ über `execute_luau`, Ergebnisse über die neu ergänzten Server-Prints sowie die gefeuerten `GameEvent`-Payloads verifiziert).

**1. Punkteberechnung (mehrere SUCCESS-Runden):**
Beobachtete Server-Prints, jeweils gegen `100 + floor(Restzeit * 10)` nachgerechnet:
- `Restzeit=17.98s -> +279` (100+179 ✓), `Restzeit=17.45s -> +274` (100+174 ✓), `Restzeit=18.93s -> +289` (100+189 ✓, zweimal), `Restzeit=16.48s -> +264` (100+164 ✓). Formel reproduziert sich in jedem Fall exakt; die Spec-Beispielrechnung (12s → 220) folgt derselben Formel.

**2. Level-Aufstieg:**
Drei SUCCESS-Runden in Folge: `levelScore` 553 → 842 → 1131. Bei Erreichen von 1131 ≥ `ScoreRequired`(Level 1)=1000: Server-Print `Level-Aufstieg -> Level 2 (nächstes Target TargetLifetime=18s)`; `score` blieb bei 1131 (unverändert durch den Aufstieg, §30), `levelScore` wurde auf 0 zurückgesetzt. Das nächste Target verwendete tatsächlich `TargetLifetime=18` (Level-2-Konfiguration).

**3. Lebensverlust für alle vier Fehlerquellen (je genau 1 Leben):**
Server-Prints für jede Quelle einzeln beobachtet: `Fehlversuch (TIMEOUT), lives: 3 -> 2`, `Fehlversuch (MISS), lives: 3 -> 2`, `Fehlversuch (HIT_BY_EXPLOSION), lives: 3 -> 2`, `Fehlversuch (FALL), lives: 3 -> 2` (FALL via Teleport des Charakters auf die `DeathZone`-Position ausgelöst, reales `PlayerFell`-Touched-Event). Nie mehr als 1 Leben pro Vorfall.

**4. Game Over bei 0 Leben:**
Mehrfach reproduziert (u. a. `Fehlversuch (MISS), lives: 1 -> 0` → `GAME_OVER, score=0`; auch für TIMEOUT, HIT_BY_EXPLOSION und FALL als auslösende letzte Fehlerquelle beobachtet). Nach `GAME_OVER` wurde über denselben RemoteEvent-Kanal ein `PlaceBomb`-Intent gefeuert und erzeugte nachweislich **kein** Event (keine Zustandsänderung, kein neues Target) - `onPlaceBomb`s State-Guard greift korrekt. Ein neues Target entstand erst wieder nach explizitem `RequestPlay`.

**5. Sofortiges neues Target nach Fehlversuch / verzögert nach Erfolg:**
Nach TIMEOUT/MISS/HIT_BY_EXPLOSION erschien jeweils unmittelbar (`NEXT_TARGET` → `TargetSpawned` → `TARGET_ACTIVE`, ohne Verzögerung) ein neues Target. Nach SUCCESS erschien das neue Target nach der konfigurierten kurzen Verzögerung (0,75s). Nach FALL (nicht-tödlich) wurden **keine** Events ausgelöst (`eventsDuringFall = []`) und dasselbe Target blieb nachweislich aktiv - anschließend erfolgreich mit `SUCCESS` auf genau diesem (unveränderten) Target abgeschlossen, exakt wie [`decisions/008-fall-does-not-reset-target.md`](../decisions/008-fall-does-not-reset-target.md) vorschreibt.

**Während der Tests gefundener und behobener Zusatzfehler (außerhalb des ursprünglichen Scopes von Task 008):**
`BombService`s verzögertes MISS-Despawn (`MISS_DISPLAY_DELAY`) zerstörte bei schnell aufeinanderfolgenden Runden das bereits von `GameService` neu erzeugte Target statt des gemissten, da `TargetService.DestroyActiveTarget()` keine Zielreferenz kennt. Das war mit der alten Platzhalter-Logik unsichtbar und wurde erst durch Task 008s korrektes "sofort neues Target"-Verhalten reproduzierbar (bei jedem MISS). Dokumentiert und minimal-invasiv behoben in [`decisions/010-miss-destroy-targets-by-id.md`](../decisions/010-miss-destroy-targets-by-id.md) (Id-Vergleich vor dem verzögerten Destroy in `BombService.resolveBomb`); Fix in Studio verifiziert (neues Target überlebt die 1s-Verzögerung und erreicht seinen eigenen natürlichen Timeout/seine eigene Auflösung).

Alle Akzeptanzkriterien erfüllt. **Meilenstein erreicht:** kompletter serverseitiger MVP-Kernloop (Start → Target → Bombe → Explosion → Score → nächstes Target → Game Over) ist funktionsfähig und wurde live in Studio durchgespielt.
