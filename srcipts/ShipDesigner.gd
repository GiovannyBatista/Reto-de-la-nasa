extends Control

@onready var etiqueta_presupuesto: Label = $VBoxContainer/EtiquetaPresupuesto
@onready var etiqueta_masa: Label = $VBoxContainer/EtiquetaMasa
@onready var barra_masa: ProgressBar = $VBoxContainer/BarraMasa
@onready var lista: VBoxContainer = $VBoxContainer/Lista
@onready var mensaje: Label = $VBoxContainer/Mensaje
@onready var barra_presupuesto: ProgressBar = $VBoxContainer/BarraPresupuesto


var botones: Dictionary = {}

func _ready():
	barra_presupuesto.max_value = GameManager.presupuesto_inicial
	barra_masa.max_value = GameManager.masa_maxima

	for c in GameManager.catalogo:
		var b = Button.new()
		b.toggle_mode = true
		b.text = "%s  |  Costo: %d  |  Masa: %d kg" % [c["nombre"], c["costo"], c["masa"]]
		b.toggled.connect(_on_boton_toggled.bind(c["id"]))
		lista.add_child(b)
		botones[c["id"]] = b

	actualizar()

func _on_boton_toggled(activado: bool, id: String):
	if activado:
		var error = GameManager.comprar(id)
		if error != "":
			botones[id].set_pressed_no_signal(false)
			mensaje.text = error
		else:
			mensaje.text = ""
	else:
		GameManager.vender(id)
		mensaje.text = ""
	actualizar()

func actualizar():
	etiqueta_presupuesto.text = "Presupuesto: %d / %d créditos" % [GameManager.presupuesto, GameManager.presupuesto_inicial]
	barra_presupuesto.value = GameManager.presupuesto
	etiqueta_masa.text = "Masa: %d / %d kg" % [GameManager.masa_actual, GameManager.masa_maxima]
	barra_masa.value = GameManager.masa_actual
