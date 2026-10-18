# 005 — Gefahrenzonen-Anzeige als serverseitiges Weltobjekt statt 2D-UI

## Kontext

`docs/SPEC.md` §22 fordert, dass der Sicherheitsabstand um die platzierte Bombe "durch einen Ring oder hervorgehobene Kacheln sichtbar" gemacht wird. Das ließe sich als 2D-Bildschirm-Overlay (Client-UI, z. B. ein Distanz-Ring am Bildschirmrand) oder als tatsächliches Objekt in der 3D-Welt umsetzen.

## Entscheidung

Die Gefahrenzone wird von `BombService` als Weltobjekt (z. B. ein flacher, nicht-kollidierender Ring-/Zylinder-Part oder hervorgehobene Tile-Overlays) direkt an der Bombenposition erzeugt, mit Radius `GameConfig.SafeDistanceTiles * GameConfig.TileSize`, und beim Auflösen der Bombe (Explosion) wieder entfernt.

## Begründung

- In First-Person (Spec §9, §45) ist ein Weltobjekt beim Umschauen natürlich sichtbar, ein 2D-Overlay müsste zusätzlich Kamerawinkel/Entfernung berücksichtigen.
- Automatische Replikation durch die Roblox-Engine (kein zusätzlicher Client-Code, kein Remote nötig).
- Konsistent mit dem server-autoritativen Prinzip: Die Sichtbarkeit der Gefahrenzone ist ein direktes Abbild des serverseitig berechneten `SafeDistance`-Werts, kann also nicht durch Client-Logik verfälscht werden.

## Konsequenz

- `EffectsController` (Client) muss die Gefahrenzone nicht selbst rendern.
- `BombService` ist für die Erzeugung *und* Entfernung dieses Weltobjekts verantwortlich (Teil von Task 007).
