extends Control

var contenedor: VBoxContainer
var etiqueta_presupuesto: Label
var etiqueta_masa: Label
var mensaje: Label
var grupo := ButtonGroup.new()
var seleccionado: String = ""

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)

	contenedor = VBoxContainer.new()
	contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(contenedor)

	var titulo = Label.new()
	titulo.text = "SELECCIÓN DEL VEHÍCULO DE LANZAMIENTO"
	contenedor.add_child(titulo)

	etiqueta_presupuesto = Label.new()
	contenedor.add_child(etiqueta_presupuesto)

	etiqueta_masa = Label.new()
	contenedor.add_child(etiqueta_masa)

	for c in GameManager.cohetes:
		var b = Button.new()
		b.toggle_mode = true
		b.button_group = grupo
		b.text = "%s  |  Costo: %d  |  Capacidad: %d kg  |  Fiabilidad: %d%%" % [c["nombre"], c["costo"], c["capacidad"], c["fiabilidad"]]
		b.pressed.connect(_on_cohete_pressed.bind(c["id"]))
		if c["id"] == GameManager.cohete_elegido:
			b.set_pressed_no_signal(true)
			seleccionado = c["id"]
		contenedor.add_child(b)

	mensaje = Label.new()
	contenedor.add_child(mensaje)

	var confirmar = Button.new()
	confirmar.text = "Confirmar cohete"
	confirmar.pressed.connect(_on_confirmar)
	contenedor.add_child(confirmar)

	var volver = Button.new()
	volver.text = "Volver al diseño a instrumento"
	volver.pressed.connect(_on_volver)
	contenedor.add_child(volver)

	actualizar()

func _on_cohete_pressed(id: String):
	seleccionado = id
	mensaje.text = ""

func _on_confirmar():
	if seleccionado == "":
		mensaje.text = "Elige un cohete primero."
		return
	var error = GameManager.elegir_cohete(seleccionado)
	if error != "":
		mensaje.text = error
	else:
		mensaje.text = "¡Cohete confirmado! Listo para continuar."
	actualizar()

func _on_volver():
	GameManager.quitar_cohete()
	get_tree().change_scene_to_file("res://scenes/instruments.tscn")

func actualizar():
	etiqueta_presupuesto.text = "Presupuesto disponible: %d créditos" % GameManager.presupuesto
	etiqueta_masa.text = "Masa de tu nave: %d kg" % GameManager.masa_actual
