extends Node
## Strumento: salva un'immagine PNG di ogni villaggio.
## Uso: godot --path . res://tools/cattura.tscn -- <cartella_uscita> [nomi...]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var uscita := "user://" if args.is_empty() else args[0]
	var nomi := ["bosco", "porto", "funghinia", "neo"]
	if args.size() > 1:
		nomi = args.slice(1)
	for nome in nomi:
		var v = load("res://villaggi/villaggio_%s.tscn" % nome).instantiate()
		v.animato = false
		add_child(v)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(uscita.path_join("villaggio_%s.png" % nome))
		v.queue_free()
		await get_tree().process_frame
	get_tree().quit()
