extends Control
## Gioco Vita - prima versione.
## Aggiungi "missioni" (le cose da fare nella vita reale), completale e guadagna XP per salire di livello.
## I progressi vengono salvati automaticamente.

const SAVE_PATH := "user://salvataggio.json"
const XP_PER_MISSIONE := 10
const XP_PER_LIVELLO := 100
const CATEGORIE := {
	"Salute": Color("4caf50"),
	"Lavoro": Color("2196f3"),
	"Casa": Color("ff9800"),
	"Studio": Color("9c27b0"),
}

var xp: int = 0
## Ogni missione: {"testo": String, "categoria": String, "fatta": bool}
var missioni: Array = []

var _label_livello: Label
var _barra_xp: ProgressBar
var _lista: VBoxContainer
var _input: LineEdit
var _scelta_categoria: OptionButton


func _ready() -> void:
	_costruisci_interfaccia()
	_carica()
	_aggiorna()


# --- Interfaccia ---------------------------------------------------------

func _costruisci_interfaccia() -> void:
	var margine := MarginContainer.new()
	margine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "right", "top", "bottom"]:
		margine.add_theme_constant_override("margin_" + lato, 16)
	add_child(margine)

	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 12)
	margine.add_child(colonna)

	var titolo := Label.new()
	titolo.text = "Gioco Vita"
	titolo.add_theme_font_size_override("font_size", 32)
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonna.add_child(titolo)

	_label_livello = Label.new()
	_label_livello.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_livello.add_theme_font_size_override("font_size", 20)
	colonna.add_child(_label_livello)

	_barra_xp = ProgressBar.new()
	_barra_xp.custom_minimum_size.y = 24
	_barra_xp.max_value = XP_PER_LIVELLO
	colonna.add_child(_barra_xp)

	var riga := HBoxContainer.new()
	colonna.add_child(riga)

	_input = LineEdit.new()
	_input.placeholder_text = "Nuova missione..."
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(func(_testo: String) -> void: _aggiungi_missione())
	riga.add_child(_input)

	_scelta_categoria = OptionButton.new()
	for categoria in CATEGORIE:
		_scelta_categoria.add_item(categoria)
	riga.add_child(_scelta_categoria)

	var bottone := Button.new()
	bottone.text = " + "
	bottone.pressed.connect(_aggiungi_missione)
	riga.add_child(bottone)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonna.add_child(scroll)

	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 6)
	scroll.add_child(_lista)


func _aggiorna() -> void:
	var livello := xp / XP_PER_LIVELLO + 1
	_label_livello.text = "Livello %d  -  %d / %d XP" % [livello, xp % XP_PER_LIVELLO, XP_PER_LIVELLO]
	_barra_xp.value = xp % XP_PER_LIVELLO

	for figlio in _lista.get_children():
		figlio.queue_free()

	for i in missioni.size():
		var m: Dictionary = missioni[i]
		var riga := HBoxContainer.new()

		var colore := ColorRect.new()
		colore.color = CATEGORIE.get(m["categoria"], Color.GRAY)
		colore.custom_minimum_size = Vector2(8, 0)
		riga.add_child(colore)

		var spunta := CheckBox.new()
		spunta.text = "%s  [%s]" % [m["testo"], m["categoria"]]
		spunta.button_pressed = m["fatta"]
		spunta.disabled = m["fatta"]
		spunta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spunta.toggled.connect(_completa.bind(i))
		riga.add_child(spunta)

		var elimina := Button.new()
		elimina.text = " X "
		elimina.pressed.connect(_elimina.bind(i))
		riga.add_child(elimina)

		if m["fatta"]:
			riga.modulate = Color(1, 1, 1, 0.5)
		_lista.add_child(riga)


# --- Logica di gioco -----------------------------------------------------

func _aggiungi_missione() -> void:
	var testo := _input.text.strip_edges()
	if testo.is_empty():
		return
	missioni.append({
		"testo": testo,
		"categoria": _scelta_categoria.get_item_text(_scelta_categoria.selected),
		"fatta": false,
	})
	_input.clear()
	_salva()
	_aggiorna()


func _completa(premuto: bool, indice: int) -> void:
	if not premuto or missioni[indice]["fatta"]:
		return
	missioni[indice]["fatta"] = true
	var livello_prima := xp / XP_PER_LIVELLO
	xp += XP_PER_MISSIONE
	if xp / XP_PER_LIVELLO > livello_prima:
		print("Livello superato! Ora sei al livello ", xp / XP_PER_LIVELLO + 1)
	_salva()
	_aggiorna.call_deferred()


func _elimina(indice: int) -> void:
	missioni.remove_at(indice)
	_salva()
	_aggiorna.call_deferred()


# --- Salvataggio ---------------------------------------------------------

func _salva() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"xp": xp, "missioni": missioni}))


func _carica() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var dati = JSON.parse_string(file.get_as_text())
	if dati is Dictionary:
		xp = int(dati.get("xp", 0))
		missioni = dati.get("missioni", [])
