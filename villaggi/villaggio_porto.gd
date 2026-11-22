@tool
extends VillaggioBase
## Villaggio 2 - Porto Azzurro: casette bianche sul mare, cupole blu, faro e barche.

const MURO := Color("f6f3ec")
const BLU := Color("2f6fc4")
const COTTO := Color("cf6a3f")
const STRADA := Color("e9dcbc")

# x, y, larghezza, profondità, altezza, tipo di tetto, colore tetto, nome della chat
var case := [
	[2, 3, 2, 2, 46, "piatto", COTTO, "Studio"],
	[5, 2, 2, 2, 36, "cupola", BLU, "Idee"],
	[10, 3, 2, 2, 40, "piatto", BLU, "Lavoro"],
	[2, 11, 2, 2, 38, "cupola", BLU, "Svago"],
	[5, 12, 2, 2, 48, "piatto", COTTO, "Salute"],
	[10, 12, 2, 2, 36, "piatto", BLU, "Casa"],
]


func prepara() -> void:
	nome = "Porto Azzurro"
	sottotitolo = "Casette bianche sul mare, un faro e le barche al molo"
	cielo_alto = Color("4fb3f2")
	cielo_basso = Color("fdf3dc")
	colore_bordo = Color("b38b5a")
	colori_terreno = {
		"erba": Color("b4d46a"),
		"strada": STRADA,
		"piazza": Color("f2ead8"),
		"sabbia": Color("f2dd9c"),
		"acqua": Color("35a2dc"),
	}
	segna(13, 0, 5, N, "acqua")
	segna(12, 0, 1, N, "sabbia")
	segna(8, 0, 2, N, "strada")
	segna(0, 8, 13, 2, "strada")
	segna(7, 7, 4, 4, "piazza")
	segna(15, 14, 2, 2, "sabbia")
	for c in case:
		occupa(c[0] - 0.3, c[1] - 0.3, c[2] + 0.6, c[3] + 0.6)
	occupa(15, 14, 2, 2)


func sfondo() -> void:
	draw_circle(Vector2(1130, 120), 42, Color("fff2b0"))
	alone(Vector2(1130, 120), 42, Color("fff2b0"), 0.8)
	for i in 3:
		var x := 220.0 + i * 330.0
		var y := 170.0 + (i % 2) * 30.0
		for o in [Vector2(0, 0), Vector2(24, -8), Vector2(48, 0)]:
			draw_circle(Vector2(x, y) + o, 18, Color(1, 1, 1, 0.75))


func terreno_extra() -> void:
	for c in case:
		var px: float = c[0] + c[2] * 0.5
		var py: float = c[1] + c[3]
		var vx := 8.0 if px < 9 else 10.0
		vialetto(px, py, 8.0, vx, STRADA.lightened(0.05))
	# onde
	for gx in range(13, N):
		for gy in N:
			if tipo_di(gx, gy) == "acqua" and rumore(gx, gy) > 0.45:
				var p := iso(gx + 0.5, gy + 0.5) + Vector2(sin(tempo + gx) * 4, 0)
				draw_arc(p, 6, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.6), 1.5, true)
	# battigia
	draw_line(iso(13, 0), iso(13, N), Color(1, 1, 1, 0.8), 3.0)
	# piccole aiuole in piazza
	for p in [Vector2(7.3, 7.3), Vector2(10.7, 7.3), Vector2(7.3, 10.7), Vector2(10.7, 10.7)]:
		ellisse_terra(p.x, p.y, 0.25, Color("c96a3f"), 0, true)


func pozzo(cx: float, cy: float) -> void:
	cilindro(cx, cy, 0.55, 16, Color("e9e2d2"))
	ellisse(iso(cx, cy, 16), 0.45 * RX, 0.45 * RY, Color("2e6f9e"))
	for s in [-1, 1]:
		var b := iso(cx + s * 0.45, cy - s * 0.45, 16)
		draw_line(b, b - Vector2(0, 26), Color("7a5030"), 3.0)
	tetto_piramide(cx - 0.55, cy - 0.55, 1.1, 1.1, 42, 16, COTTO)


func molo() -> void:
	box(12.6, 8.25, 4.6, 1.5, 4, Color("a77445"), -1)
	for i in 14:
		var x := 12.7 + i * 0.32
		draw_line(iso(x, 8.25, 3), iso(x, 9.75, 3), Color("8a5c34"), 1.0)
	for x in [13.5, 15, 16.6]:
		box(x, 9.75, 0.18, 0.18, 10, Color("6b4428"), -6)


func barca(x: float, y: float, vela: Color) -> void:
	var b := iso(x, y) + Vector2(0, sin(tempo * 1.3 + x) * 2.0)
	_poly([b + Vector2(-22, -6), b + Vector2(22, -6), b + Vector2(14, 6), b + Vector2(-14, 6)], Color("8b4f2b"))
	draw_line(b + Vector2(-22, -6), b + Vector2(22, -6), Color("e9d3a8"), 2.0)
	draw_line(b + Vector2(0, -6), b + Vector2(0, -44), Color("5a3a22"), 2.0)
	_poly([b + Vector2(2, -42), b + Vector2(2, -10), b + Vector2(20, -10)], vela)


func faro(cx: float, cy: float) -> void:
	ellisse_terra(cx, cy, 1.0, Color("8e8b86"), 2)
	cilindro(cx, cy, 0.95, 6, Color("8e8b86"))
	for i in 5:
		var col := Color("e4483a") if i % 2 == 0 else Color("fbfbfb")
		cilindro(cx, cy, 0.42 - i * 0.02, 16, col, 6 + i * 16)
	var cima := 6 + 5 * 16
	cilindro(cx, cy, 0.34, 14, Color("fff2a0"), cima)
	alone(iso(cx, cy, cima + 7), 10, Color("fff2a0"), 1.2)
	cupola(cx, cy, 0.38, cima + 14, 14, Color("3a3a44"))


func palma(x: float, y: float, s: float = 1.0) -> void:
	var b := iso(x + 0.5, y + 0.5)
	ellisse(b + Vector2(0, 2), 16 * s, 7 * s, Color(0, 0, 0, 0.15))
	var pts := PackedVector2Array()
	for i in 7:
		var t := i / 6.0
		pts.append(b + Vector2(sin(t * 1.4) * 12 * s, -t * 58 * s))
	draw_polyline(pts, Color("8a6038"), 5 * s, true)
	var cima := pts[pts.size() - 1]
	for a in [-2.6, -2.0, -1.3, -0.6, 0.0, 0.5]:
		var dir := Vector2(cos(a), sin(a) * 0.6 + 0.25)
		var f := cima + dir * 30 * s
		var n := Vector2(-dir.y, dir.x) * 5 * s
		_poly([cima, cima + dir * 15 * s + n, f + Vector2(0, 8 * s), cima + dir * 15 * s - n], Color("4b9a3c"))


func costruisci() -> void:
	for c in case:
		aggiungi(c[0] + c[2] + c[1] + c[3], casa.bind(c[0], c[1], c[2], c[3], c[4], MURO, c[6], c[5], Color("3d7fd0"), BLU, 24.0))
	aggiungi(18, pozzo.bind(9, 9))
	aggiungi(20.9, molo)
	aggiungi(30, faro.bind(16, 15))
	aggiungi(16, barca.bind(14.6, 3.2, Color("ffffff")))
	aggiungi(26, barca.bind(16.2, 10.8, Color("ffd34d")))
	aggiungi(19, barca.bind(15.6, 5.8, Color("ff7a6b")))
	for gy in N:
		if libero(12, gy) or tipo_di(12, gy) == "sabbia":
			if not occupato.has(Vector2i(12, gy)) and gy != 8 and gy != 9 and rumore(12, gy) > 0.45:
				aggiungi(12 + gy + 1, palma.bind(12, gy, 0.9 + rumore(gy, 12) * 0.3))
	for gx in range(0, 12):
		for gy in N:
			if not libero(gx, gy):
				continue
			var r := rumore(gx, gy)
			var ai_bordi := gx <= 0 or gy <= 0 or gy >= 17
			if ai_bordi and r > 0.55:
				aggiungi(gx + gy + 1, albero.bind(gx, gy, 0.8, Color("7c9a3a"), Color("6b5a3a")))
			elif r > 0.86:
				aggiungi(gx + gy + 1, cespuglio.bind(gx, gy, Color("6fa54a"), Color("e64e8a")))
			elif r > 0.8:
				aggiungi(gx + gy + 1, palma.bind(gx, gy, 0.8))


func sopra() -> void:
	var battute := {
		"Studio": "Esame domani...",
		"Idee": "Gita in barca?",
		"Casa": "Ho steso i panni!",
	}
	for c in case:
		if battute.has(c[7]):
			fumetto(iso(c[0] + c[2] * 0.5, c[1] + c[3] * 0.5, c[4] + 46), c[7] + ": " + battute[c[7]])
	fumetto(iso(16, 15, 150), "Faro: Vi vedo tutti!")
