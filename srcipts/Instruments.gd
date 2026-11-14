extends Control

var contenedor: VBoxContainer
var etiqueta_presupuesto: Label
var etiqueta_masa: Label
var etiqueta_energia: Label
var barra_energia: ProgressBar
var etiqueta_ciencia: Label
var mensaje: Label
var botones: Dictionary = {}

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)

	contenedor = VBoxContainer.new()
	contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(contenedor)

	var titulo = Label.new()
	titulo.text = "INSTRUMENTOS CIENTÍFICOS"
	contenedor.add_child(titulo)

	etiqueta_presupuesto = Label.new()
	contenedor.add_child(etiqueta_presupuesto)

	etiqueta_masa = Label.new()
	contenedor.add_child(etiqueta_masa)

	etiqueta_energia = Label.new()
	contenedor.add_child(etiqueta_energia)

	barra_energia = ProgressBar.new()
	contenedor.add_child(barra_energia)

	etiqueta_ciencia = Label.new()
	contenedor.add_child(etiqueta_ciencia)

	for i in GameManager.instrumentos:
		var b = Button.new()
		b.toggle_mode = true
		b.text = "%s  |  Costo: %d  |  Masa: %d kg  |  Energía: %d  |  Ciencia: +%d" % [i["nombre"], i["costo"], i["masa"], i["consumo"], i["ciencia"]]
		b.toggled.connect(_on_boton_toggled.bind(i["id"]))
		b.set_pressed_no_signal(i["id"] in GameManager.instrumentos_comprados)
		contenedor.add_child(b)
		botones[i["id"]] = b

	mensaje = Label.new()
	contenedor.add_child(mensaje)

	var seguir = Button.new()
	seguir.text = "Continuar: elegir cohete"
	seguir.pressed.connect(_on_continuar)
	contenedor.add_child(seguir)

	var volver = Button.new()
	volver.text = "Volver al diseño de la nave"
	volver.pressed.connect(_on_volver)
	contenedor.add_child(volver)

	actualizar()

func _on_boton_toggled(activado: bool, id: String):
	if activado:
		var error = GameManager.comprar_instrumento(id)
		if error != "":
			botones[id].set_pressed_no_signal(false)
			mensaje.text = error
		else:
			mensaje.text = ""
	else:
		GameManager.vender_instrumento(id)
		mensaje.text = ""
	actualizar()

func _on_continuar():
	if GameManager.energia_consumida() > GameManager.energia_generada():
		mensaje.text = "Consumes más energía de la que generas. Quita instrumentos o revisa tus paneles."
		return
	if GameManager.instrumentos_comprados.is_empty():
		mensaje.text = "Elige al menos un instrumento científico."
		return
	get_tree().change_scene_to_file("res://scenes/launch_vehicle.tscn")

func _on_volver():
	get_tree().change_scene_to_file("res://scenes/ship_designer.tscn")

func actualizar():
	etiqueta_presupuesto.text = "Presupuesto disponible: %d créditos" % GameManager.presupuesto
	etiqueta_masa.text = "Masa: %d / %d kg" % [GameManager.masa_actual, GameManager.masa_maxima]
	etiqueta_energia.text = "Energía: %d consumida / %d generada" % [GameManager.energia_consumida(), GameManager.energia_generada()]
	barra_energia.max_value = maxi(GameManager.energia_generada(), 1)
	barra_energia.value = GameManager.energia_consumida()
	etiqueta_ciencia.text = "Valor científico: %d puntos" % GameManager.ciencia_total()
