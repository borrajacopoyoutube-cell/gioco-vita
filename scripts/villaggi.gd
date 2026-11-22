extends Node
## Schermata per sfogliare i 4 villaggi.
## Frecce sinistra/destra oppure tasti 1-4 per cambiare villaggio.

const VILLAGGI := [
	"res://villaggi/villaggio_bosco.tscn",
	"res://villaggi/villaggio_porto.tscn",
	"res://villaggi/villaggio_funghinia.tscn",
	"res://villaggi/villaggio_neo.tscn",
]

var indice := 0
var corrente: Node
var etichetta: Label


func _ready() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var barra := HBoxContainer.new()
	barra.position = Vector2(640 - 230, 664)
	barra.size = Vector2(460, 40)
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	ui.add_child(barra)

	var prima := Button.new()
	prima.text = "  <  "
	prima.pressed.connect(func() -> void: mostra(indice - 1))
	barra.add_child(prima)

	etichetta = Label.new()
	etichetta.custom_minimum_size = Vector2(300, 0)
	etichetta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etichetta.add_theme_color_override("font_color", Color.WHITE)
	etichetta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	etichetta.add_theme_constant_override("outline_size", 6)
	barra.add_child(etichetta)

	var dopo := Button.new()
	dopo.text = "  >  "
	dopo.pressed.connect(func() -> void: mostra(indice + 1))
	barra.add_child(dopo)

	mostra(0)


func mostra(i: int) -> void:
	indice = posmod(i, VILLAGGI.size())
	if corrente:
		corrente.queue_free()
	corrente = load(VILLAGGI[indice]).instantiate()
	add_child(corrente)
	move_child(corrente, 0)
	etichetta.text = "Villaggio %d di %d   (frecce o tasti 1-4)" % [indice + 1, VILLAGGI.size()]


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_right"):
		mostra(indice + 1)
	elif evento.is_action_pressed("ui_left"):
		mostra(indice - 1)
	elif evento is InputEventKey and evento.pressed and not evento.echo:
		var n: int = evento.keycode - KEY_1
		if n >= 0 and n < VILLAGGI.size():
			mostra(n)
