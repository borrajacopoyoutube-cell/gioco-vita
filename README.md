# Gioco Vita

Un gioco per PC fatto con Godot 4 per organizzare la vita. Le tue chat con Claude abitano in un borgo medievale: ognuna ha la sua casa, parlano tra loro e con te in modo giocoso.

## Il borgo medievale 3D (scena principale)
Tutto è generato via codice, senza modelli esterni:
- mura ottagonali con torri e porta d'ingresso
- chiesa con campanile e rosone
- piazza del mercato con pozzo, bancarelle e abitanti
- case a graticcio per le chat, ognuna con insegna e fumetto
- campi coltivati, mulino a vento, boschi, colline e montagne innevate

Per cambiare nomi, frasi o posizioni delle chat modifica l'elenco `CHAT` in `borgo/borgo3d.gd`.

### Comandi
- Tasto sinistro + trascina: ruota la vista
- Rotellina: zoom
- Tasto destro + trascina: sposta la vista
- Frecce o WASD: ruota e avvicina
- Se non tocchi nulla la vista gira piano da sola

## Come aprirlo
1. Apri Godot 4 (versione 4.3 o successiva).
2. Clicca **Importa** e scegli il file `project.godot` in questa cartella.
3. Premi **F5**.

## Struttura
- `borgo/borgo3d.tscn` + `borgo/borgo3d.gd`: il borgo 3D
- `borgo/camera_orbita.gd`: telecamera che gira attorno al borgo
- `borgo/shader/`: materiali (erba, ciottoli, pietra, tegole)
- `tools/cattura3d.tscn`: salva le immagini delle viste del borgo
- `villaggi/` + `scenes/villaggi.tscn`: le prime 4 proposte in 2D
- `scenes/main.tscn`: il primo prototipo (lista missioni con XP)
