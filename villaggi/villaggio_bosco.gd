@tool
extends VillaggioBase
## Villaggio 1 - Borgo del Bosco: casette di legno, pini, fontana in piazza.

const LEGNO := Color("d9a066")
const STRADA := Color("d8b67a")

# x, y, larghezza, profondità, altezza, colore tetto, nome della chat
var case := [
	[2, 2, 2, 2, 40, Color("b5452f"), "Studio"],
	[5, 4, 2, 2, 34, Color("3f7a4a"), "Idee"],
	[11, 2, 2, 2, 42, Color("c46a2b"), "Lavoro"],
	[13, 5, 2, 2, 34, Color("b5452f"), "Soldi"],
	[2, 11, 2, 2, 36, Color("7a4fa0"), "Svago"],
	[5, 13, 2, 2, 40, Color("b5452f"), "Salute"],
	[13, 11, 2, 2, 38, Color("3f7a4a"), "Casa"],
	[14, 15, 2, 2, 32, Color("c46a2b"), "Cucina"],
]


func prepara() -> void:
	nome = "Borgo del Bosco"
	sottotitolo = "Casette di legno, pini e una fontana in piazza"
	cielo_alto = Color("74c0f0")
	cielo_basso = Color("e8f6ff")
	colore_bordo = Color("8a6440")
	colori_terreno = {
		"erba": Color("7cc35b"),
		"strada": STRADA,
		"piazza": Color("bdb6aa"),
		"acqua": Color("4fa3e0"),
	}
	segna(8, 0, 2, N, "strada")
	segna(0, 8, N, 2, "strada")
	segna(7, 7, 4, 4, "piazza")
	segna(14, 0, 3, 3, "acqua")
	for c in case:
		occupa(c[0] - 0.3, c[1] - 0.3, c[2] + 0.6, c[3] + 0.6)


func sfondo() -> void:
	for i in 4:
		var x := 180.0 + i * 300.0 + sin(tempo * 0.05 + i) * 20.0
		var y := 150.0 + (i % 2) * 40.0
		for o in [Vector2(0, 0), Vector2(26, -10), Vector2(52, 0)]:
			draw_circle(Vector2(x, y) + o, 22, Color(1, 1, 1, 0.8))


func terreno_extra() -> void:
	for c in case:
		var px: float = c[0] + c[2] * 0.5
		var py: float = c[1] + c[3]
		var vx := 8.0 if px < 9 else 10.0
		vialetto(px, py, 8.0, vx, STRADA.lightened(0.08))
	# fiorellini sull'erba
	var colori_fiori := [Color("fff3a0"), Color("ffffff"), Color("f59ac4")]
	for gx in N:
		for gy in N:
			if libero(gx, gy) and rumore(gx + 3, gy) > 0.7:
				var p := iso(gx + rumore(gx, gy + 1), gy + rumore(gx + 2, gy))
				var col: Color = colori_fiori[int(rumore(gy, gx) * 3) % 3]
				draw_circle(p, 2.2, col)
	# riva del laghetto
	draw_line(iso(14, 3), iso(17, 3), Color("e9d9a6"), 3.0)
	draw_line(iso(14, 0), iso(14, 3), Color("e9d9a6"), 3.0)


func _laghetto() -> void:
	for p in [Vector2(14.6, 0.8), Vector2(15.8, 2.1)]:
		ellisse(iso(p.x, p.y), 9, 4.5, Color("5fae4c"), true)
	var b := iso(15.4, 1.3) + Vector2(0, sin(tempo) * 1.5)
	_poly([b + Vector2(-16, -4), b + Vector2(16, -4), b + Vector2(10, 4), b + Vector2(-10, 4)], Color("9c5b33"))


func costruisci() -> void:
	for c in case:
		aggiungi(c[0] + c[2] + c[1] + c[3], casa.bind(c[0], c[1], c[2], c[3], c[4], LEGNO, c[5], "capanna"))
	aggiungi(18, fontana.bind(9, 9))
	for p in [Vector2(7, 7), Vector2(11, 7), Vector2(7, 11), Vector2(11, 11)]:
		aggiungi(p.x + p.y, lampione.bind(p.x, p.y))
	aggiungi(3, _laghetto)
	for gx in N:
		for gy in N:
			if not libero(gx, gy):
				continue
			var ai_bordi := gx <= 1 or gy <= 1 or gx >= 16 or gy >= 16
			var r := rumore(gx, gy)
			if ai_bordi and r > 0.35:
				aggiungi(gx + gy + 1, pino.bind(gx, gy, 0.85 + rumore(gy, gx) * 0.35))
			elif not ai_bordi and r > 0.84:
				aggiungi(gx + gy + 1, albero.bind(gx, gy, 0.9))
			elif r > 0.78:
				aggiungi(gx + gy + 1, cespuglio.bind(gx, gy, Color("5aa843"), Color("ff8fb8")))


func sopra() -> void:
	var battute := {
		"Studio": "Ciao vicini!",
		"Lavoro": "Riunione in piazza?",
		"Salute": "Chi viene a correre?",
		"Casa": "Stasera pizza!",
	}
	for c in case:
		if battute.has(c[6]):
			fumetto(iso(c[0] + c[2] * 0.5, c[1] + c[3] * 0.5, c[4] + 48), c[6] + ": " + battute[c[6]])
