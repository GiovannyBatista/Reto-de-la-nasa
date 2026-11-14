extends Control

var contenedor: VBoxContainer
var etiqueta_presupuesto: Label
var etiqueta_masa: Label
var barra_masa: ProgressBar
var etiqueta_niveles: Label
var mensaje: Label
var etiquetas_suministro: Dictionary = {}
var botones_mejora: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	contenedor = VBoxContainer.new()
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contenedor)

	_agregar_texto("TIENDA DE LA MISIÓN: PREPARA A ORION")

	etiqueta_presupuesto = _agregar_texto("")
	etiqueta_masa = _agregar_texto("")
	barra_masa = ProgressBar.new()
	contenedor.add_child(barra_masa)
	etiqueta_niveles = _agregar_texto("")

	_agregar_texto("")
	_agregar_texto("SUMINISTROS (usa + y - para cambiar la cantidad)")
	for s in GameManager.suministros:
		var fila = HBoxContainer.new()
		var etiqueta = Label.new()
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(etiqueta)
		var menos = Button.new()
		menos.text = " - "
		menos.pressed.connect(_on_quitar.bind(s["id"]))
		fila.add_child(menos)
		var mas = Button.new()
		mas.text = " + "
		mas.pressed.connect(_on_comprar.bind(s["id"]))
		fila.add_child(mas)
		contenedor.add_child(fila)
		etiquetas_suministro[s["id"]] = etiqueta

	_agregar_texto("")
	_agregar_texto("MEJORAS DE ORION (clic para comprar o devolver)")
	for m in GameManager.mejoras:
		var b = Button.new()
		b.toggle_mode = true
		b.text = "%s | Costo: %d | Masa: %.1f kg | %s" % [m["nombre"], m["costo"], m["masa"], m["efecto"]]
		b.toggled.connect(_on_mejora_toggled.bind(m["id"]))
		b.set_pressed_no_signal(m["id"] in GameManager.mejoras_compradas)
		contenedor.add_child(b)
		botones_mejora[m["id"]] = b

	mensaje = _agregar_texto("")

	var iniciar = Button.new()
	iniciar.text = "INICIAR MISIÓN"
	iniciar.pressed.connect(_on_iniciar)
	contenedor.add_child(iniciar)

	actualizar()

func _agregar_texto(texto: String) -> Label:
	var l = Label.new()
	l.text = texto
	contenedor.add_child(l)
	return l

func _on_comprar(id: String):
	mensaje.text = GameManager.comprar_suministro(id)
	actualizar()

func _on_quitar(id: String):
	GameManager.quitar_suministro(id)
	mensaje.text = ""
	actualizar()

func _on_mejora_toggled(activado: bool, id: String):
	var error: String = ""
	if activado:
		error = GameManager.comprar_mejora(id)
	else:
		error = GameManager.vender_mejora(id)
	if error != "":
		botones_mejora[id].set_pressed_no_signal(not activado)
	mensaje.text = error
	actualizar()

func _on_iniciar():
	GameManager.iniciar_mision()
	var ruta = "res://scenes/mission.tscn"
	if ResourceLoader.exists(ruta):
		get_tree().change_scene_to_file(ruta)
	else:
		mensaje.text = "Compras listas. La pantalla de misión se crea en un paso siguiente."
		print("Niveles al despegar: ", GameManager.nave)
		print("Mejoras: ", GameManager.mejoras_compradas)

func actualizar():
	etiqueta_presupuesto.text = "Presupuesto: %d / %d créditos" % [GameManager.presupuesto, GameManager.presupuesto_inicial]
	etiqueta_masa.text = "Carga de Orion: %.1f / %.1f kg" % [GameManager.masa_usada(), GameManager.capacidad_total()]
	barra_masa.max_value = GameManager.capacidad_total()
	barra_masa.value = GameManager.masa_usada()
	etiqueta_niveles.text = "Niveles al despegar -> Agua: %d%% | Comida: %d%% | Oxígeno: %d%% | Electricidad: %d%%" % [
		GameManager.nivel_inicial("agua"), GameManager.nivel_inicial("comida"),
		GameManager.nivel_inicial("oxigeno"), GameManager.nivel_inicial("electricidad")]
	for s in GameManager.suministros:
		var n: int = GameManager.compras_suministros.get(s["id"], 0)
		etiquetas_suministro[s["id"]].text = "%s | Costo: %d | Masa: %.1f kg | Comprados: %d/%d" % [s["nombre"], s["costo"], s["masa"], n, s["max"]]
