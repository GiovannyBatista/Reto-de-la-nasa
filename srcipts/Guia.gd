extends Control
# Generado/modificado con ayuda de IA (Claude, Anthropic) y revisado por el equipo.
# GUÍA DEL JUEGO: ventana con pestañas que explica, con iconos y frases cortas, qué es cada cosa
# y qué pasa cuando sube o baja (recursos, sistemas, tripulación y decisiones).
#
# Se abre desde el menú principal (CÓMO JUGAR) y desde el botón "?" de la misión.
#
# Cómo usarla:
#     const Guia = preload("res://srcipts/Guia.gd")
#     var guia = Guia.new()
#     add_child(guia)
#     guia.abrir()                 # guia.abrir(3) abre directamente la pestaña TRIPULACIÓN
#     guia.cerrada.connect(...)    # avisa cuando el jugador la cierra
#
# Los números que salen de GameManager (alarma, meta de ciencia...) se leen de sus constantes.
# Los demás (por ejemplo 18-28 °C o estrés 40/70) están escritos aquí: si cambian las reglas, cámbialos también.

signal cerrada

const Estilo = preload("res://srcipts/Estilo.gd")

# Cada tarjeta: [icono, título, explicación]. "{alarma}", "{meta}", "{minimo}" y "{casco}" se cambian por los números del juego.
const PAGINAS: Array = [
	{"titulo": "LO BÁSICO", "tarjetas": [
		["tierra", "Tu misión", "Sobrevive 14 días, reúne {meta} % de ciencia y trae a los cuatro astronautas de vuelta."],
		["racion_completa", "1. Órdenes del día", "Cada mañana eliges ración, instrumentos e higiene. En verde lo que ganas y en rojo lo que te cuesta."],
		["reloj", "2. Dos decisiones", "Una emergencia o momento clave y una decisión de recursos. Tienen límite de tiempo."],
		["herramienta", "3. Tarea manual", "Si eliges un buen procedimiento, un minijuego decide qué tan bien sale."],
		["resultado_bueno", "4. Resultado", "Verás qué subió y qué bajó. Después empieza el día siguiente."],
		["alarma", "Cómo se pierde", "Si el agua, el oxígeno, la electricidad o el combustible llegan a 0, o si no queda nadie vivo."],
	]},
	{"titulo": "RECURSOS", "tarjetas": [
		["agua", "Agua", "Baja cada día. Si llega a 0, la misión termina."],
		["comida", "Comida", "Baja cada día. Sin comida, todos pierden salud muy rápido."],
		["oxigeno", "Oxígeno", "Baja cada día. Si llega a 0, la misión termina."],
		["electricidad", "Electricidad", "Mantiene vivo el soporte vital. Si llega a 0, la misión termina."],
		["combustible", "Combustible", "Solo se gasta en maniobras. Si llega a 0, no hay cómo volver."],
		["alarma", "Alarma", "Salta cuando un recurso baja de {alarma} %. Para el mejor final todos deben terminar sobre {minimo} %."],
	]},
	{"titulo": "SISTEMAS", "tarjetas": [
		["integridad", "Casco", "Es el daño de la nave. Bajo 60 % se escapa oxígeno. Con {casco} % o menos no resiste la reentrada."],
		["ciencia", "Ciencia", "Sube cada día con los instrumentos encendidos. Necesitas {meta} % para el mejor final."],
		["datos", "Datos", "Los instrumentos llenan la memoria. Si llega a 100 %, se apagan solos. Se vacía cuando hay radio."],
		["temperatura", "Cabina", "Entre 18 y 28 °C todo va bien. Fuera de ahí sube el estrés y baja la salud de todos."],
		["filtros", "Filtros de CO2", "Cartuchos que limpian el aire. Si se acaban, todos pierden salud cada día."],
		["enlace", "Radio", "Es el enlace con la Tierra. Si se pierde, la memoria de datos no se vacía."],
	]},
	{"titulo": "TRIPULACIÓN", "tarjetas": [
		["salud", "Salud", "Bajo 50 está herido y ya no ayuda en su especialidad. Bajo 25 está crítico. Si llega a 0, muere."],
		["estres", "Estrés", "Sube cada día. Con mucho estrés comete errores que gastan recursos, y la nave consume más."],
		["hambre", "Hambre", "Sube si das poca comida y baja con la ración completa. Con mucha hambre pierde salud cada día."],
		["confianza", "Confianza", "Baja si se te acaba el tiempo o si algo sale mal. Con poca confianza puede ignorar tu orden."],
		["pulso", "Su cara lo dice", "El retrato cambia: tranquilo, estresado, herido o crítico. Pasa el ratón por su tarjeta para ver los números."],
		["resultado_intermedio", "Cada uno es especialista", "Si el responsable de una decisión está sano y tranquilo, el resultado sale mejor."],
	]},
	{"titulo": "DECISIONES", "tarjetas": [
		["reloj", "Contra reloj", "Si se acaba el tiempo, la tripulación decide sola: suele salir peor y confían menos en ti."],
		["alarma", "Cuidado con las trampas", "Algunas opciones suenan rápidas pero son peligrosas. Piensa qué protege a la tripulación."],
		["herramienta", "Tarea manual", "Tu puntería en el minijuego mejora o empeora el resultado de esa decisión."],
		["resultado_bueno", "Tres resultados", "BUENO, INTERMEDIO o MALO. Depende de tu opción, del estado de la nave y del especialista."],
		["memo", "Memo NASA", "Después de decidir, el botón MEMO NASA explica lo que recomienda la NASA en ese caso."],
		["ciencia", "Tres finales", "Misión cumplida, misión abortada o silencio total. Depende de cómo llegues al día 14."],
	]},
]

var pestanas: Array = []
var rejilla: GridContainer
var pagina: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.72)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel: PanelContainer = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.98), Estilo.C_CIAN, 20)
	panel.custom_minimum_size = Vector2(1320, 0)
	centro.add_child(panel)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var titulo: Label = Estilo.nuevo_texto("GUÍA: QUÉ SIGNIFICA CADA COSA", 32, Estilo.C_AMARILLO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titulo)

	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(fila)
	var grupo = ButtonGroup.new()
	for i in PAGINAS.size():
		var b: Button = Estilo.nuevo_boton(String(PAGINAS[i]["titulo"]), 16, 220, 44)
		Estilo.estilo_holo(b)
		b.toggle_mode = true
		b.button_group = grupo
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_mostrar.bind(i))
		fila.add_child(b)
		pestanas.append(b)

	rejilla = GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 12)
	rejilla.add_theme_constant_override("v_separation", 10)
	col.add_child(rejilla)

	var pie = HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 16)
	col.add_child(pie)
	var anterior: Button = Estilo.nuevo_boton("ANTERIOR", 24, 240, 52)
	anterior.pressed.connect(func(): _mostrar(posmod(pagina - 1, PAGINAS.size())))
	pie.add_child(anterior)
	var cerrar: Button = Estilo.nuevo_boton("CERRAR", 24, 240, 52)
	cerrar.name = "BotonCerrar"
	cerrar.pressed.connect(_cerrar)
	pie.add_child(cerrar)
	var siguiente: Button = Estilo.nuevo_boton("SIGUIENTE", 24, 240, 52)
	siguiente.pressed.connect(func(): _mostrar(posmod(pagina + 1, PAGINAS.size())))
	pie.add_child(siguiente)

func abrir(cual: int = 0) -> void:
	visible = true
	move_to_front()
	_mostrar(cual)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	var cerrar: Button = find_child("BotonCerrar", true, false)
	if cerrar != null:
		cerrar.grab_focus.call_deferred()

func _cerrar() -> void:
	visible = false
	cerrada.emit()

func _unhandled_key_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cerrar()

# Cambia los números entre llaves por los valores reales de GameManager
func _con_numeros(texto: String) -> String:
	return texto.format({
		"alarma": int(GameManager.UMBRAL_ALARMA),
		"meta": int(GameManager.CIENCIA_FINAL_BUENO),
		"minimo": int(GameManager.UMBRAL_FINAL_BUENO),
		"casco": int(GameManager.INTEGRIDAD_REENTRADA),
	})

func _mostrar(cual: int) -> void:
	pagina = clampi(cual, 0, PAGINAS.size() - 1)
	for i in pestanas.size():
		pestanas[i].set_pressed_no_signal(i == pagina)
	for hijo in rejilla.get_children():
		rejilla.remove_child(hijo)
		hijo.queue_free()
	var n: int = 0
	for t in PAGINAS[pagina]["tarjetas"]:
		var tarjeta: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Color(Estilo.C_BORDE, 0.8), 12)
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(tarjeta)
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		tarjeta.add_child(h)
		h.add_child(Estilo.nuevo_icono(String(t[0]), 56))
		var v = VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 0)
		h.add_child(v)
		v.add_child(Estilo.nuevo_texto(String(t[1]), 24, Estilo.C_AMARILLO))
		v.add_child(Estilo.nuevo_texto(_con_numeros(Idioma.t(String(t[2]))), 16, Estilo.C_TEXTO))
		Estilo.saltar(tarjeta, 0.04 * float(n), 0.9)
		n += 1
