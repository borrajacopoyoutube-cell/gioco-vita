# Gioco Vita

Un gioco per PC fatto con Godot 4 per organizzare la vita. Le tue chat con Claude abitano in un villaggio: ognuna ha la sua casa, parlano tra loro e con te in modo giocoso.

## Fase attuale: scegliere il villaggio
Ci sono 4 proposte di villaggio, tutte disegnate via codice (nessuna immagine esterna):

1. **Borgo del Bosco**: casette di legno, pini, fontana in piazza
2. **Porto Azzurro**: casette bianche sul mare, faro, molo e barche
3. **Funghinia**: case a fungo, cristalli magici, lucciole
4. **Neo Borgo**: villaggio futuristico di notte, torri al neon e ologramma

Le anteprime sono nella cartella `anteprime/`.

## Come aprirlo
1. Apri Godot 4 (versione 4.3 o successiva).
2. Clicca **Importa** e scegli il file `project.godot` in questa cartella.
3. Premi **F5**. Con le frecce o i tasti 1-4 cambi villaggio.

## Struttura
- `villaggi/villaggio_base.gd`: strumenti di disegno comuni (case, alberi, fumetti...)
- `villaggi/villaggio_*.gd` / `.tscn`: i 4 villaggi
- `scenes/villaggi.tscn` + `scripts/villaggi.gd`: schermata per sfogliarli
- `tools/cattura.tscn`: salva un'immagine PNG di ogni villaggio
- `scenes/main.tscn` + `scripts/main.gd`: il primo prototipo (lista missioni con XP)
