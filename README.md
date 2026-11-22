# Gioco Vita

Un gioco-app fatto con Godot 4 per organizzare la vita: le cose da fare diventano **missioni**, completarle dà **XP** e fa salire di **livello**.

## Come aprirlo
1. Apri Godot 4.
2. Clicca **Importa** e scegli il file `project.godot` in questa cartella.
3. Premi **F5** per avviare il gioco.

## Cosa fa (versione 0.1)
- Aggiungi missioni con una categoria: Salute, Lavoro, Casa, Studio.
- Spunta una missione per completarla: +10 XP.
- Ogni 100 XP sali di livello.
- I progressi vengono salvati automaticamente.

## Struttura
- `project.godot`: configurazione del progetto
- `scenes/main.tscn`: scena principale
- `scripts/main.gd`: logica del gioco e interfaccia
