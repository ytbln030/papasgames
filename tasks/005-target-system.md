# Task 005 — Target System

## Ziel und erwartetes Verhalten

`TargetService` erzeugt das namensgebende Kreuz aus vier gleichfarbigen Kugeln, bestimmt dabei intern den (dem Spieler nicht angezeigten) Kreuzungspunkt, verwaltet dessen Lebenszeit und stellt die Validierung einer Bombenkachel bereit. Nach diesem Task kann — rein serverseitig per Command-Bar ausgelöst — ein korrekt geformtes, zeitlich begrenztes Kreuz auf dem Board erscheinen und wieder verschwinden.

## Voraussetzungen und Abhängigkeiten

- [Task 002](002-shared-foundations.md): `GameConfig` (`ColorPalette`, `ObjectHeight`, `ObjectDiameter`), `GameTypes` (`TargetData`), `GridMath` (`GridDistance`).
- [Task 003](003-board-system.md): `BoardService.IsValidTile`, `GridToWorld`.

## Betroffene Module

- `src/server/Services/TargetService.luau` (neu)

## Funktionale Anforderungen

1. `TargetService.CreateTarget(levelConfig: LevelConfigData, playerPosition: GridPosition): TargetData`:
   - Wählt einen Mittelpunkt (`center`) und vier unabhängig aus `[levelConfig.MinTargetDistance, levelConfig.MaxTargetDistance]` gewürfelte Distanzen für links/rechts/oben/unten (Spec §14, §16 — Abstände dürfen und sollen variieren).
   - Stellt sicher, dass `left.y == right.y == center.y` und `top.x == bottom.x == center.x` (Spec §16).
   - Stellt sicher, dass alle vier Objektpositionen und der Mittelpunkt mit `levelConfig.Margin` Randabstand innerhalb des Boards liegen (Spec §15): `center.x - left.distance >= 1 + Margin`, `center.x + right.distance <= BoardSize - Margin`, analog für Y.
   - Verwirft/wiederholt die Generierung, falls der Mittelpunkt näher als `GameConfig.MinSpawnDistanceFromTarget` (Chebyshev-Distanz via `GridMath.GridDistance`) an `playerPosition` liegt (Spec §46, [`decisions/006`](../decisions/006-spawn-before-target.md)).
   - Erzeugt 4 kugelförmige `Part`-Instanzen (`Shape = Ball`, Durchmesser `GameConfig.ObjectDiameter`) über den jeweiligen Kachelmittelpunkten in Höhe `GameConfig.ObjectHeight`, mit `CanCollide = false` (Spec §12), einer zufällig aus `GameConfig.ColorPalette` gewählten, für alle vier identischen Farbe (Spec §13), sowie sichtbarem Glow/Licht (z. B. `PointLight` + `SelectionBox`/`SurfaceLight` oder `Material = Neon`) für Fernsichtbarkeit.
   - Startet einen Lifetime-Timer (`levelConfig.TargetLifetime` Sekunden) und gibt die resultierende `TargetData` zurück.
2. `TargetService.GetActiveTarget(): TargetData?`
3. `TargetService.ValidateBombTile(pos: GridPosition): boolean` — `true` genau dann, wenn ein aktives Target existiert und `pos` seinem `center` entspricht (Spec §20).
4. `TargetService.DestroyActiveTarget(): ()` — entfernt die 4 Kugel-Instanzen und den aktiven Zustand, stoppt einen ggf. laufenden Timer.
5. Signal `TargetExpired()` — feuert, wenn der Lifetime-Timer abläuft, **ohne** dass zuvor `DestroyActiveTarget` aufgerufen wurde (d. h. kein Timeout-Event nach erfolgreicher/fehlgeschlagener Bombenauflösung, die den Timer bereits gestoppt hat — siehe Spec §17: Timer läuft nur in `TARGET_ACTIVE`).

## Technische Vorgaben und Schnittstellen

- Es existiert zu jedem Zeitpunkt höchstens **ein** aktives Target (einfache Variable, kein Array) — bewusst so belassen trotz künftiger Mehrfach-Target-Modi (siehe `ARCHITECTURE.md` Abschnitt 10, Backlog 017). Keine Überdimensionierung der Datenstruktur im MVP.
- Generierung muss terminieren: eine sinnvolle Obergrenze an Wiederholversuchen (z. B. 50) verhindert Endlosschleifen bei ungünstigen `playerPosition`/`levelConfig`-Kombinationen; nach Erschöpfung der Versuche wird die Mindestabstands-Bedingung zu `playerPosition` fallengelassen (Validität/Randbedingungen bleiben zwingend).
- `TargetService` ruft **nicht** `BombService` oder `GameService` auf (reine Bereitstellung von Daten/Events, Konsequenzen zieht `GameService`).

## Bekannte zukünftige Anforderungen

- Level 4/5 (Backlog 016): Ablenk-/Fake-Kugeln würden eine Erweiterung von `TargetData`/`CreateTarget` erfordern, nicht deren Ersetzung.
- Multiplayer mit mehreren gleichzeitigen Targets (Backlog 017, offene Frage in `ARCHITECTURE.md` Abschnitt 10) — aktuell bewusst nicht vorgebaut.

## Out of Scope

- Reaktion auf abgelaufenes Target (Lebensverlust, neues Target) — Task 006/008.
- Bombenplatzierung/-validierung gegen den Spieler-Standort — Task 007.
- Anzeige des Countdowns im HUD — Task 010.

## Akzeptanzkriterien

1. Erzeugte Kreuze liegen vollständig innerhalb des Boards inkl. `Margin`, nie exakt am äußersten Rand.
2. Linkes/rechtes Objekt teilen stets exakt die Y-Koordinate, oberes/unteres Objekt stets exakt die X-Koordinate; die vier Abstände sind nicht alle identisch über mehrere generierte Kreuze hinweg (stichprobenhaft über z. B. 10 Generierungen beobachtet).
3. Alle vier Kugeln eines Kreuzes haben exakt dieselbe Farbe; über mehrere Kreuze hinweg wechselt die Farbe zufällig.
4. `ValidateBombTile` liefert `true` nur für die exakte Mittelpunkt-Kachel, `false` für jede andere Kachel inkl. der vier Objekt-Kacheln selbst.
5. Nach Ablauf der `TargetLifetime` ohne Eingriff feuert `TargetExpired` genau einmal; nach manuellem `DestroyActiveTarget` feuert es nicht mehr nach.
6. Mit `playerPosition` direkt neben einer sonst gültigen Zielposition wird kein Mittelpunkt näher als `MinSpawnDistanceFromTarget` gewählt (außer nach Erschöpfung der Wiederholversuche, dann dokumentiert nachvollziehbar).

## Teststrategie (manuell in Roblox Studio)

1. `TargetService.CreateTarget(LevelConfig.GetConfig(1), {x=15, y=15})` zehnmal in der Command-Bar aufrufen (zwischen den Aufrufen `DestroyActiveTarget`), jeweils die vier resultierenden Kugelpositionen gegen die Randbedingungen prüfen.
2. Visuell im Play-Test: Kreuz erscheint mit deutlich erkennbarer Glow-Farbe, aus Entfernung erkennbar.
3. `ValidateBombTile` mit der bekannten Mittelpunkt-Koordinate und mit mehreren falschen Koordinaten aufrufen, Ergebnisse prüfen.
4. Lifetime auf einen kurzen Testwert (z. B. 3s) setzen, Ablauf abwarten, `TargetExpired`-Print beobachten.
5. `playerPosition` absichtlich sehr nah an einen sonst wahrscheinlichen Mittelpunkt setzen und über mehrere Generierungen prüfen, dass der Mindestabstand eingehalten wird.
6. Ergebnis dokumentieren.

## Definition of Done

- `TargetService.luau` implementiert mit allen oben genannten Funktionen/Signalen.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
