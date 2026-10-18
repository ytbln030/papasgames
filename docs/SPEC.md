# Roblox Spiel – Game Design & technische Spezifikation v0.2

## 1. Spielidee

Der Spieler befindet sich auf einem frei schwebenden Spielfeld aus quadratischen Kacheln.

Auf dem Spielfeld erscheinen gleichzeitig vier gleichfarbige Objekte. Die vier Objekte bilden geometrisch ein Kreuz:

```text
            ●
            |
            |
● --------- X --------- ●
            |
            |
            ●
```

Der Spieler muss erkennen, an welcher Kachel sich der Kreuzungspunkt `X` befindet.

An dieser Position muss eine Bombe platziert werden.

Nach dem Platzieren startet ein Countdown von 2 Sekunden. Der Spieler muss sich anschließend mindestens zwei Kacheln vom Explosionspunkt entfernen.

Befindet sich die Bombe auf dem korrekten Kreuzungspunkt, werden alle vier Objekte durch die Explosion zerstört.

Anschließend erscheint ein neues Kreuz.

Für jedes Target stehen 20 Sekunden und höchstens eine Bombe zur Verfügung. Ein abgelaufenes Target, eine falsch platzierte Bombe, ein Explosionstreffer oder ein Sturz vom Spielfeld kostet ein Leben. Der Spieler startet mit drei Leben. Bei null Leben endet die Session.

Das Spiel wird aus der Ich-Perspektive gespielt.

---

# 2. Spieltyp

Plattform:

**Roblox**

Erste Version:

**Single Player**

Spätere Erweiterung:

**Multiplayer**

Der Code und insbesondere die Spiellogik sollen bereits in der ersten Version so aufgebaut werden, dass später mehrere Spieler gleichzeitig auf demselben Spielfeld spielen können.

---

# 3. Haupt-Spielablauf

Der grundlegende Ablauf einer Spielsession ist:

```text
Spiel starten
      ↓
Startscreen
      ↓
PLAY
      ↓
Level laden
      ↓
Spielfeld erzeugen
      ↓
Spieler platzieren
      ↓
4 Objekte erzeugen
      ↓
20-Sekunden-Timer startet
      ↓
Spieler sucht Kreuzungspunkt
      ↓
Bombe platzieren
      ↓
2-Sekunden-Fuse
      ↓
Spieler entfernt sich
      ↓
Explosion
      ↓
Position und Abstand prüfen
      ↓
Bombe korrekt und
Spieler in Sicherheit?
   ↙             ↘
 JA              NEIN
 ↓                ↓
Objekte          Fehlversuch
zerstören        Leben −1
 ↓                ↓
Punkte      Leben = 0?
 ↓             ↙     ↘
neues Kreuz   JA      NEIN
               ↓       ↓
          GAME OVER  neues Kreuz
```

Läuft der 20-Sekunden-Timer vor der Bombenplatzierung ab, zählt dies ebenfalls als Fehlversuch. Sobald eine Bombe platziert wurde, stoppt der Target-Timer; während der zweisekündigen Fuse wird nur noch die Explosion ausgewertet.

---

# 4. Startscreen

Beim Start des Spiels befindet sich der Spieler zunächst noch nicht aktiv auf dem Spielfeld.

Es erscheint ein einfacher Startscreen.

Elemente:

- Spieltitel
- Play-Button
- optional aktuelle Bestleistung
- optional aktuelles bzw. höchstes erreichtes Level

Beim Klick auf:

**PLAY**

wird eine neue Spielsession gestartet.

Erst dann wird das Spielfeld aktiviert beziehungsweise erzeugt und der Spieler darauf platziert.

Bei Game Over werden die erreichte Punktzahl und optional die Bestleistung angezeigt. Anschließend kehrt der Spieler zum Startscreen zurück. Ein erneuter Klick auf **PLAY** startet eine vollständig neue Session mit Level 1, null Punkten und drei Leben.

---

# 5. Spielfeld

## Standardgröße

Das Spielfeld besteht standardmäßig aus:

**30 × 30 Kacheln**

also insgesamt:

**900 Kacheln**

Die Größe soll konfigurierbar sein.

Beispiel:

```lua
BoardSize = 30
```

Spätere Level könnten beispielsweise verwenden:

```text
Level 1   20 × 20
Level 2   25 × 25
Level 3   30 × 30
Level 4   35 × 35
```

---

# 6. Kacheln

Jede Kachel ist:

- quadratisch
- flach
- begehbar
- fest verankert
- mit Collision ausgestattet

Die Seitenlänge sollte etwas größer als ein normaler Schritt des Roblox-Charakters sein.

Als erster Testwert bietet sich beispielsweise an:

```text
TileSize = 6 Studs
```

Die endgültige Größe sollte später anhand des tatsächlichen Spielgefühls angepasst werden.

Die Kacheln besitzen keinen funktionalen Abstand voneinander.

Optisch soll aber ein sehr dünner Rand beziehungsweise Gap sichtbar sein.

Beispiel:

```text
TileSize = 6 Studs
Gap = 0.08–0.15 Studs
```

Dadurch entsteht optisch ein deutlich erkennbares Raster.

---

# 7. Aussehen der Kacheln

Grundfarbe:

**Grau / Silber**

Die einzelnen Kacheln dürfen leicht unterschiedliche Grautöne besitzen.

Beispiel:

```text
Kachel A   RGB 125 / 125 / 125
Kachel B   RGB 132 / 132 / 132
Kachel C   RGB 120 / 123 / 126
```

Die Variation sollte sehr subtil bleiben.

Ziel ist eine technisch-futuristische beziehungsweise minimalistische Optik.

Die Farbe darf nicht zu stark variieren, weil die farbigen Zielobjekte klar erkennbar bleiben müssen.

---

# 8. Kein Boden

Unter dem Spielfeld befindet sich:

**keine Baseplate**

Das Spielfeld schwebt frei im Raum.

Wenn der Spieler das Spielfeld verlässt oder eine nicht vorhandene Kachel betritt, fällt er nach unten.

Unterhalb des Spielfelds sollte zusätzlich eine unsichtbare Death-Grenze definiert werden.

Beispiel:

```text
DeathY = -50
```

Sobald sich der Spieler darunter befindet:

```text
1 Leben verlieren
Respawn auf einer sicheren Kachel
```

Dadurch muss man nicht darauf warten, dass der Roblox-Charakter extrem weit fällt.

Das absichtliche Herunterlaufen vom Rand ist erlaubt, wird aber genauso behandelt. Erreicht der Spieler dabei null Leben, folgt Game Over.

---

# 9. Spieler

Der Spieler verwendet zunächst einen normalen Roblox-Charakter.

Steuerung:

- normale Roblox-Bewegung
- WASD auf PC
- Standard-Touchsteuerung auf mobilen Geräten
- später Controller-Support

Springen ist in der ersten Version deaktiviert. Das Verlassen des Spielfelds ist weiterhin möglich, indem der Spieler über den Rand läuft.

Die Kamera befindet sich in:

**First Person / Ich-Perspektive**

Der Spieler sieht die Welt damit direkt aus der Perspektive seines Charakters.

---

# 10. Spielerposition beim Start

Nach dem Klick auf PLAY wird eine zufällige Kachel ausgewählt.

Dort wird der Spieler platziert.

Die Spawnposition befindet sich:

- mittig auf einer Kachel
- nicht außerhalb des Spielfelds
- nicht auf einer Kachel mit einem Zielobjekt
- möglichst nicht direkt auf dem später gesuchten Kreuzungspunkt

Optional sollte zusätzlich ein Mindestabstand zum Ziel definiert werden.

Beispiel:

```text
mindestens 4 Kacheln Entfernung
```

Dadurch kann der Spieler nicht zufällig direkt auf dem richtigen Kreuzungspunkt starten.

---

# 11. Zielobjekte

In der ersten Version werden Kugeln verwendet.

Eine Kugel:

- schwebt über einer Kachel
- befindet sich exakt über deren Mittelpunkt
- besitzt ungefähr den halben Durchmesser einer Kachel

Bei:

```text
TileSize = 6
```

könnte die Kugel beispielsweise ungefähr:

```text
3 Studs
```

Durchmesser besitzen.

---

# 12. Höhe der Kugeln

Die Kugeln schweben ungefähr:

**eine halbe Spielerhöhe**

über der jeweiligen Kachel.

Die exakte Höhe sollte konfigurierbar sein.

Zum Beispiel:

```lua
ObjectHeight = 3.5
```

Die Kugeln sollen nicht mit dem Spieler kollidieren.

---

# 13. Farbe der Kugeln

Alle vier Kugeln eines Kreuzes besitzen dieselbe Farbe.

Bei jedem neuen Kreuz wird zufällig eine neue Farbe gewählt.

Beispiele:

- Rot
- Blau
- Grün
- Gelb
- Orange
- Pink
- Türkis
- Lila

Sehr dunkle Grau- oder Silbertöne sollten vermieden werden, damit ein ausreichender Kontrast zum Spielfeld vorhanden bleibt.

Die Kugeln erhalten einen klaren Glow beziehungsweise ein dezentes Licht. Sie müssen sich auch aus größerer Entfernung deutlich vom Spielfeld abheben.

---

# 14. Erzeugung eines Kreuzes

Zunächst wird eine gültige Mittelpunkt-Kachel bestimmt.

Beispiel:

```text
CenterX = 15
CenterY = 12
```

Danach werden vier Objektpositionen erzeugt.

Beispielsweise:

```text
LeftDistance = 6
RightDistance = 4
TopDistance = 3
BottomDistance = 7
```

Positionen:

```text
Links:
CenterX - LeftDistance
CenterY

Rechts:
CenterX + RightDistance
CenterY

Oben:
CenterX
CenterY - TopDistance

Unten:
CenterX
CenterY + BottomDistance
```

Damit entsteht:

```text
             ●
             |
             |
             |
● ----------X---------- ●
             |
             |
             ●
```

Der Spieler sieht nur die vier Kugeln.

Der Punkt `X` wird nicht angezeigt.

Für den MVP werden die vier Abstände unabhängig aus einem kleinen konfigurierbaren Bereich gewählt, beispielsweise drei bis sieben Kacheln. Eine komplexe levelabhängige Generierung ist zunächst nicht erforderlich. Spätere Level können den Wertebereich und damit die Schwierigkeit leicht erhöhen.

---

# 15. Sicherheitsabstand zum Spielfeldrand

Der Algorithmus darf keinen Mittelpunkt auswählen, bei dem eine der vier Kugeln außerhalb des Spielfeldes liegen würde.

Bei einem 30×30-Feld muss daher vor der Platzierung geprüft werden:

```text
CenterX - LeftDistance >= 1
CenterX + RightDistance <= 30

CenterY - TopDistance >= 1
CenterY + BottomDistance <= 30
```

Optional sollte zusätzlich mindestens eine freie Randkachel existieren.

Beispiel:

```text
Margin = 1
```

Damit stehen die Kugeln niemals direkt an der äußersten Kante.

---

# 16. Unterschiedliche Abstände

Bitte die horizontalen und vertikalen Abstände nicht immer identisch machen.

Beispiel:

```text
links:  6 Kacheln
rechts: 4 Kacheln

oben:   3 Kacheln
unten:  7 Kacheln
```

Die vier Objekte liegen trotzdem auf zwei sich schneidenden Geraden.

Der Spieler kann dadurch nicht einfach den optischen Mittelpunkt zwischen allen vier Kugeln schätzen.

Das macht die Aufgabe deutlich interessanter.

Wichtig ist lediglich:

Die linke und rechte Kugel müssen dieselbe Y-Koordinate besitzen.

Die obere und untere Kugel müssen dieselbe X-Koordinate besitzen.

---

# 17. Lebenszeit eines Kreuzes

Nach dem Erzeugen der vier Kugeln startet ein Countdown.

Standard:

**20 Sekunden**

Anzeige beispielsweise:

```text
TARGET  18.4
```

oder:

```text
TIME 18
```

Der Countdown wird permanent aktualisiert.

Nach Ablauf der Zeit verschwindet das aktuelle Kreuz.

Ein abgelaufenes Kreuz zählt als Fehlversuch:

```text
altes Kreuz entfernen
1 Leben verlieren
Combo zurücksetzen
neues Kreuz erzeugen
```

Erreicht der Spieler dadurch null Leben, wird statt eines neuen Targets der Zustand `GAME_OVER` aktiviert.

Der Target-Timer läuft nur im Zustand `TARGET_ACTIVE`. Sobald eine Bombe platziert wurde, wird er gestoppt, damit während der Fuse kein zusätzlicher Timeout entstehen kann.

---

# 18. Bombe

Der Spieler kann im Zustand `TARGET_ACTIVE` genau eine Bombe für das aktuelle Target platzieren. Weitere Platzierungsversuche werden bis zum nächsten Target ignoriert.

Auf PC beispielsweise über:

```text
E
```

Auf Mobile erscheint ein:

**BOMB**

Button.

Später könnte ein Controller-Button ergänzt werden.

---

# 19. Bombenplatzierung

Ich würde die Bombe nicht exakt an der Weltposition platzieren, an der der Spieler gerade steht.

Stattdessen sollte ermittelt werden:

**Auf welcher Kachel steht der Spieler?**

Die Bombe wird anschließend automatisch exakt auf den Mittelpunkt dieser Kachel gesetzt.

Beispiel:

```text
Spieler steht auf Tile [14,17]

→ Bombe erscheint exakt auf Tile [14,17]
```

Das ist besonders wichtig für First-Person-Steuerung.

Andernfalls könnte der Spieler den richtigen Kreuzungspunkt erkannt haben, aber wegen 20 oder 30 Zentimetern Positionsabweichung trotzdem verlieren.

Nach Platzierung der Bombe bewegt sich der Spieler automatisch einen kleinen Schritt zurück. Dadurch bleibt die Bombe sichtbar und die Fluchtrichtung wird unmittelbar verständlich.
---

# 20. Richtige Bombenposition

Für jedes Kreuz existiert intern eine:

```text
TargetTile
```

Beispiel:

```text
TargetTile = [14,17]
```

Wenn:

```text
BombTile == TargetTile
```

ist die Lösung korrekt.

Dadurch ist keine komplizierte Weltkoordinaten-Berechnung notwendig.

---

# 21. Bomben-Countdown

Nach dem Platzieren startet:

**2 Sekunden**

Fuse-Time.

Beispiel:

```text
2.0
1.5
1.0
0.5
BOOM
```

Zusätzlich können akustische Signale verwendet werden.

Beispielsweise:

```text
BEEP
BEEP
BEEP
BOOM
```

---

# 22. Flucht vor der Bombe

Nach dem Platzieren muss der Spieler sich vom Explosionspunkt entfernen.

Mindestentfernung:

**Radius von zwei Kachellängen**

Bei:

```text
TileSize = 6 Studs
```

entspricht das ungefähr:

```text
12 Studs
```

Die direkte Distanz zwischen Spieler und Mittelpunkt der Bombenkachel wird zum Zeitpunkt der Explosion geprüft.

Beispiel:

```lua
SafeDistance = TileSize * 2
```

Befindet sich der Spieler näher als `SafeDistance` an der Bombe, gilt er als von der Explosion getroffen und verliert ein Leben. Der Gefahrenradius soll während der Fuse durch einen Ring oder hervorgehobene Kacheln sichtbar gemacht werden, damit die Regel für den Spieler eindeutig erkennbar ist.

Das gibt der 2-Sekunden-Fluchtphase einen tatsächlichen spielerischen Sinn.

---

# 23. Explosion

Nach zwei Sekunden explodiert die Bombe.

Die Explosion besitzt:

- Lichtblitz
- Partikel
- Sound
- kurze Kameraerschütterung

Optional können die vier Kugeln zunächst kurz aufleuchten und anschließend gleichzeitig zerplatzen.

---

# 24. Validierung

Beim Explodieren werden zwei Bedingungen geprüft.

### Bedingung 1

Die Bombe befindet sich auf:

```text
TargetTile
```

### Bedingung 2

Der Spieler befindet sich außerhalb des Gefahrenbereichs.

Sind beide Bedingungen erfüllt:

```text
SUCCESS
```

Die vier Kugeln werden zerstört.

Die übrigen Ergebnisse sind:

```text
Falsche Bombenkachel:
MISS, 1 Leben verlieren, neues Target

Richtige Bombenkachel, aber Spieler zu nah:
Kugeln werden zerstört, 1 Leben verlieren,
keine Punkte, neues Target
```

Pro Target kann höchstens ein Leben verloren werden. Sind gleichzeitig die Bombenkachel falsch und der Spieler zu nah, werden die Ursachen nicht addiert.

---

# 25. Erfolgsfeedback

Bei Erfolg sollte der Spieler sofort eine deutliche Rückmeldung erhalten.

Beispiel:

```text
PERFECT!
```

oder:

```text
TARGET DESTROYED
```

Zusätzlich:

- Explosionsanimation
- Sound
- Punkte
- kurze visuelle Bestätigung

Nach ungefähr 0,5–1 Sekunde wird das nächste Kreuz erzeugt.

---

# 26. Fehlplatzierte Bombe

Falls die Bombe nicht auf der korrekten Kachel liegt:

```text
MISS
```

Die Zielkugeln verschwinden nach einer kurzen `MISS`-Einblendung. Der Spieler verliert ein Leben und unmittelbar danach wird ein neues Kreuz erzeugt.

Der Spieler startet jede Session mit:

```text
3 Leben
```

---

# 27. HUD

Am oberen Bildschirmrand befindet sich dauerhaft eine schmale Informationsleiste.

Beispiel:

```text
LEVEL 3        TARGETS 7        TIME 14.2
```

Alternativ:

```text
LVL 3     ★ 7     ●●●● 14.2
```

Mögliche Informationen:

| Information | Bedeutung |
|---|---|
| Level | aktuelles Level |
| Targets | erfolgreich zerstörte Kreuze |
| Timer | verbleibende Lebenszeit des aktuellen Kreuzes |
| Lives | verbleibende Leben |
| Score | Gesamtpunktzahl |
| Level-Fortschritt | Punkte bis zum nächsten Level |

Die Leiste sollte möglichst wenig Bildschirmhöhe verbrauchen, weil First Person gespielt wird.

---

# 28. Punkte

Als Basis könnte gelten:

```text
Korrektes Kreuz = 100 Punkte
```

Zusätzliche Punkte können anhand der Geschwindigkeit vergeben werden.

Beispiel:

```text
Restzeit × 10
```

Bei noch 12 Sekunden:

```text
100 + 120 = 220 Punkte
```

Damit lohnt es sich, den Kreuzungspunkt schnell zu erkennen.

---

# 29. Combo-System

Optional kann später ein Combo-System eingeführt werden.

Beispiel:

```text
1 Treffer  x1
2 Treffer  x1.2
3 Treffer  x1.4
5 Treffer  x2
```

Ein Fehler setzt die Combo zurück.

Dadurch entsteht zusätzlich ein Highscore-Anreiz.

---

# 30. Levelsystem

Das Spiel beginnt immer mit:

**Level 1**

Ein Level wird abgeschlossen, sobald die für dieses Level konfigurierte Punktzahl erreicht wurde. Der Zeitbonus trägt damit direkt zum Level-Fortschritt bei.

Beispiel:

```text
Level 1
1000 Punkte

Level 2
1500 Punkte

Level 3
2000 Punkte
```

Die Werte sind erste Balancing-Beispiele. `LevelScore` wird beim Levelwechsel auf null gesetzt; der Gesamt-Score der Session bleibt erhalten. Der Schwierigkeitsgrad steigt schrittweise.

---

# 31. Mögliche Levelparameter

Die Schwierigkeit sollte über Konfigurationswerte gesteuert werden.

Beispiel:

```lua
LevelConfig = {
    Level = 1,
    BoardSize = 30,
    TargetLifetime = 20,
    BombFuse = 2,
    ScoreRequired = 1000,
    MinTargetDistance = 3,
    MaxTargetDistance = 5
}
```

Später können weitere Parameter hinzukommen.

---

# 32. Schwierigkeitssteigerung

Nicht unbedingt sofort einbauen, aber das Spiel bietet dafür sehr viele Möglichkeiten.

### Level 1

```text
20 Sekunden
große Kugeln
Abstände von 3–5 Kacheln
leichte Asymmetrie
keine Hindernisse
```

### Level 2

```text
18 Sekunden
Abstände von 3–6 Kacheln
```

### Level 3

```text
16 Sekunden
Abstände von 3–7 Kacheln
stärkere Asymmetrie
```

### Level 4

Erweiterung nach dem MVP:

```text
15 Sekunden
einzelne fehlende Kacheln
```

### Level 5

Erweiterung nach dem MVP:

```text
mehrere farbige Objekte
einige davon sind Ablenkung
```

### Später

```text
bewegliche Kugeln
mehrere Kreuze gleichzeitig
temporär verschwindende Kacheln
Nebel
Dunkelheit
Laser
Moving Tiles
```

---

# 33. Wichtig für das Gameplay

Der Spieler sollte niemals überlegen müssen:

> Habe ich die Bombe vielleicht nur einige Zentimeter falsch platziert?

Die eigentliche Herausforderung sollte sein:

> Welche Kachel ist der Kreuzungspunkt?

Deshalb sollte die Bombenposition immer auf das Kachelraster eingerastet werden.

---

# 34. Game-State-System

Die Spiellogik sollte intern mit klaren Zuständen arbeiten.

Beispielsweise:

```text
MENU
STARTING
TARGET_ACTIVE
BOMB_PLACED
EXPLODING
ROUND_RESULT
NEXT_TARGET
GAME_OVER
```

Dadurch wird später auch Multiplayer wesentlich einfacher.

---

# 35. Technische Roblox-Struktur

Empfohlene grobe Architektur:

```text
ReplicatedStorage
│
├── Shared
│   ├── GameConfig
│   ├── LevelConfig
│   └── GameTypes
│
├── Remotes
│   ├── PlaceBomb
│   ├── GameStateUpdate
│   └── TargetUpdate
│
ServerScriptService
│
├── Services
│   ├── GameService
│   ├── BoardService
│   ├── TargetService
│   ├── BombService
│   └── PlayerService
│
StarterPlayer
│
└── StarterPlayerScripts
    ├── InputController
    ├── CameraController
    └── EffectsController
│
StarterGui
│
├── MainMenu
└── GameHUD
```

---

# 36. BoardService

Aufgaben:

```text
Spielfeld erzeugen
Kacheln verwalten
Grid-Koordinaten ↔ Weltkoordinaten umrechnen
zufällige Kachel auswählen
Kachel unter Spieler bestimmen
```

Eine Kachel besitzt intern beispielsweise:

```text
GridX
GridY
WorldPosition
```

---

# 37. TargetService

Aufgaben:

```text
Kreuzungspunkt bestimmen
vier Objektpositionen berechnen
Randbedingungen prüfen
Kugeln erzeugen
Timer verwalten
Kugeln entfernen
```

Interne Struktur beispielsweise:

```text
Target
{
    center = {x = 15, y = 12},

    left = {x = 9, y = 12},
    right = {x = 19, y = 12},

    top = {x = 15, y = 7},
    bottom = {x = 15, y = 18},

    lifetime = 20,
    color = ...
}
```

---

# 38. BombService

Aufgaben:

```text
Bombenplatzierung empfangen
Spielerposition prüfen
Kachel bestimmen
Bombe erzeugen
2-Sekunden-Timer starten
Explosion durchführen
Treffer validieren
Entfernung zum Spieler prüfen
```

---

# 39. Server-Authoritative Design

Auch im Single Player sollte der Server entscheiden:

```text
Wo befindet sich das Target?
Ist die Bombe korrekt?
Ist der Spieler weit genug entfernt?
Wie viele Punkte erhält der Spieler?
```

Der Client sollte nur melden:

```text
Ich möchte eine Bombe platzieren.
```

Nicht:

```text
Ich habe das Target getroffen.
```

Das ist für den späteren Multiplayer wichtig und reduziert außerdem Möglichkeiten für Cheats.

---

# 40. Multiplayer-Erweiterung

Das Spiel lässt sich später relativ einfach erweitern.

Beispielsweise:

```text
4 Spieler
1 Spielfeld
1 aktives Kreuz
```

Alle Spieler suchen gleichzeitig den Kreuzungspunkt.

Wer zuerst die korrekte Bombe platziert, erhält den Punkt.

Beispiel:

```text
PLAYER A    5
PLAYER B    3
PLAYER C    2
PLAYER D    1
```

Nach der Explosion erscheint sofort das nächste Kreuz.

---

# 41. Multiplayer-Regeln

Bereits im Singleplayer kann ein Spieler pro Target nur eine Bombe platzieren. Im Multiplayer darf ein Spieler ebenfalls nur eine aktive Bombe besitzen.

Dadurch kann niemand einfach wahllos auf jede Kachel Bomben werfen.

Zusätzlich könnte es im Multiplayer nach einer falschen Bombe beispielsweise:

```text
3 Sekunden Bomben-Sperre
```

geben.

Damit wird blindes Raten unattraktiv.

---

# 42. Alternative Multiplayer-Modi

Später könnten mehrere Modi entstehen.

### Race

Alle Spieler suchen dasselbe Kreuz.

Der erste Treffer gewinnt den Punkt.

### Individual Targets

Jeder Spieler erhält seine eigenen vier Objekte.

### Chaos

Mehrere Kreuze befinden sich gleichzeitig auf dem Feld.

### Elimination

Falsche Bombe oder Explosionstreffer bedeutet Ausscheiden.

### Survival

Kacheln verschwinden zunehmend.

---

# 43. Visual Style

Das Spiel eignet sich gut für einen minimalistischen Stil.

Vorstellbar:

```text
dunkler Himmel
schwebendes silbernes Raster
kräftig leuchtende Kugeln
Glow beziehungsweise dezentes Licht für Fernsichtbarkeit
leichte Reflexionen
dezente Neon-Effekte
```

Die vier Kugeln sollten sofort als zusammengehörige Gruppe wahrgenommen werden.

---

# 44. Sound Design

Sound ist bei diesem Spiel besonders wichtig.

Mögliche Sounds:

```text
Target erscheint
Timer nähert sich Null
Bombe wird gesetzt
Bomben-Fuse
Explosion
richtiger Treffer
Fehlversuch
Level abgeschlossen
Game Over
```

Gerade die zwei Sekunden nach Bombenplatzierung können durch immer schnellere Beeps sehr spannend wirken.

---

# 45. Kamera

Standard:

**First Person**

Die Kamera sollte möglichst wenig eingeschränkt werden.

Eine leichte Kameraerschütterung bei Explosionen kann verwendet werden.

Sie sollte allerdings nur sehr kurz dauern, damit die Orientierung nicht verloren geht.

---

# 46. Fairness-Regeln

Beim Generieren eines neuen Targets sollten mehrere Bedingungen geprüft werden.

Der Kreuzungspunkt sollte:

- erreichbar sein
- nicht außerhalb des Spielfelds liegen
- nicht unmittelbar am Rand liegen
- nicht direkt unter dem Spieler entstehen

Die vier Objekte sollten:

- vollständig innerhalb des Boards liegen
- ausreichend weit auseinander liegen
- gut sichtbar sein

Zusätzlich sollte berücksichtigt werden, wie weit der Spieler vom neuen Target entfernt ist.

Ein Target am anderen Ende des Feldes könnte bei einem kurzen Timer sonst praktisch unerreichbar sein.

Ob alle vier Kugeln jederzeit gleichzeitig im aktuellen Sichtfeld liegen müssen, wird in Playtests entschieden. Unabhängig davon müssen alle Kugeln vollständig auf dem Board liegen und durch Farbe sowie Glow auch aus größerer Entfernung erkennbar sein.

---

# 47. Empfohlene MVP-Version

Für die erste wirklich spielbare Version würde ich bewusst nur folgende Funktionen bauen:

```text
30×30 Board
First Person
graue Kacheln
zufälliger Player Spawn

1 Kreuz gleichzeitig
4 farbige Kugeln
20-Sekunden-Timer
3 Leben

Bombenplatzierung
Bomben-Snap auf Tile
maximal 1 Bombe pro Target
2-Sekunden-Fuse
Explosion

Trefferprüfung
Spieler muss Abstand halten
Fehlversuch, Timeout, Explosionstreffer oder Sturz: 1 Leben

Score
Levelabschluss über Punktzahl
Game Over
Play / Restart
```

Noch nicht notwendig:

```text
Multiplayer
Leaderboards
Skins
verschwindende Kacheln
mehrere Targets
Power-Ups
Shop
Matchmaking
```

Damit lässt sich sehr schnell feststellen, ob der eigentliche Spielmechanismus Spaß macht.

---

# 48. Asymmetrische Kreuze

Wenn die vier Kugeln immer exakt denselben Abstand vom Mittelpunkt haben:

```text
        ●


●       X       ●


        ●
```

ist der Kreuzungspunkt visuell sehr leicht zu erkennen.

Interessanter wird:

```text
             ●
             |
             |
●------------X----●
             |
             |
             |
             |
             ●
```

Der Schnittpunkt bleibt eindeutig.

Aber der Spieler muss tatsächlich die horizontalen und vertikalen Linien erkennen und kann nicht einfach den Mittelpunkt der vier Objekte schätzen.

---

# 49. Nicht pixelgenau spielen

Der Spieler sollte niemals eine mathematisch exakte Position mit seinem Roblox-Charakter treffen müssen.

Die Spiellogik sollte vollständig auf:

```text
Grid-Koordinaten
```

basieren.

Beispielsweise:

```text
Target = Tile 14/17

Player = Tile 14/17

Bomb → Tile 14/17

Treffer.
```

Dadurch fühlt sich das Spiel fair an.

---

# 50. Falsches Raten verhindern

Ohne Einschränkung könnte ein Spieler ständig Bomben platzieren. Deshalb ist pro Target genau eine Bombe erlaubt. Nach einem fehlgeschlagenen Versuch verliert der Spieler ein Leben und es wird unmittelbar ein neues Target erstellt.

Ein zusätzlicher Bomben-Cooldown ist im Singleplayer-MVP nicht notwendig. Für spätere Multiplayer-Modi kann weiterhin eine Bombensperre von zwei bis drei Sekunden verwendet werden.

---

# 51. Zeitbonus

Je schneller der Spieler das Kreuz erkennt, desto mehr Punkte sollte er bekommen.

Damit entstehen zwei Spielstile:

```text
vorsichtig und sicher
```

gegen:

```text
schnell und riskant
```

Das erhöht den Wiederspielwert erheblich.

---

# 52. Bombe wirklich gefährlich machen

Wenn der Spieler nach dem Platzieren nicht fliehen müsste, wäre die Zwei-Sekunden-Regel hauptsächlich eine Animation.

Deshalb sollte eine Explosion innerhalb des Sicherheitsradius tatsächlich eine Konsequenz haben.

Im Standardmodus gilt:

```text
Leben verlieren
```

In einem späteren Hardcore-Modus kann stattdessen gelten:

```text
Game Over
```

So entsteht jedes Mal ein kleiner Spannungsmoment:

```text
Position gefunden
↓
Bombe
↓
RUN!
↓
BOOM
```

Das könnte zu einem wichtigen Teil der Identität des Spiels werden.

---

# 53. Entscheidungsstand und offene Playtests

Die Regeln für den MVP sind festgelegt:

1. Ein Timeout, eine falsche Bombe, ein Explosionstreffer oder ein Sturz kostet jeweils ein Leben.
2. Der Spieler startet mit drei Leben.
3. Nach einem Fehlversuch wird unmittelbar ein neues Target erzeugt.
4. Pro Target kann genau eine Bombe platziert werden.
5. Der Sicherheitsabstand ist ein Radius von zwei Kachellängen und wird visuell markiert.
6. Die vier Abstände des Kreuzes dürfen unterschiedlich sein. Im MVP stammen sie aus einem kleinen konfigurierbaren Wertebereich.
7. Ein Level wird über die konfigurierte Punktzahl abgeschlossen.
8. Bei null Leben erscheint Game Over; anschließend erfolgt die Rückkehr zum Startscreen.
9. Springen ist im MVP deaktiviert.
10. Der Spieler darf das Spielfeld über den Rand verlassen, verliert dabei jedoch ein Leben.
11. Kugeln erhalten Glow beziehungsweise Licht und bleiben auch aus größerer Entfernung erkennbar.
12. Das Spiel verbindet die geometrische Suche mit schnellem Arcade-Tempo; der Schwerpunkt liegt auf Arcade.

Für Erweiterungen nach dem MVP sind verschwindende Kacheln beziehungsweise Löcher sowie Fake-Kugeln vorgesehen.

Offen bleiben bewusst nur Punkte, die durch Playtests oder die spätere Multiplayer-Konzeption entschieden werden:

- Müssen alle vier Kugeln jederzeit gleichzeitig im Sichtfeld liegen, oder reicht ihre gute Erkennbarkeit beim Umschauen?
- Verwendet der spätere Multiplayer ein gemeinsames Target für alle Spieler, individuelle Targets oder bietet er beide Varianten als getrennte Modi an?