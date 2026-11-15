extends Control
# Pantalla GRÁFICA de la misión (los 14 días).
#
# Las reglas del juego NO están aquí: siguen en GameManager.gd y Eventos.gd. Este script solo dibuja:
#   - la cabina con la ventana al espacio (la Tierra y la Luna cambian de tamaño según el día)
#   - el panel de la nave (barras con iconos) y el de la tripulación (retratos que cambian de expresión)
#   - las decisiones como tarjetas, con el retrato del responsable y un temporizador
#   - el resultado con fichas de colores (qué subió y qué bajó) y el Memo NASA
#
# El ciclo de cada día es el mismo de Mission.gd (la versión antigua, de solo texto):
#   órdenes del día -> registro (consumo y eventos) -> decisión 1 -> decisión 2 -> resumen -> día siguiente

const Estilo = preload("res://srcipts/Estilo.gd")
const FondoEspacio = preload("res://srcipts/FondoEspacio.gd")
const Memos = preload("res://srcipts/Memos.gd")

const VITALES: Array = [["agua", "Agua"], ["comida", "Comida"], ["oxigeno", "Oxígeno"], ["electricidad", "Electricidad"], ["combustible", "Combustible"]]
const SECUNDARIAS: Array = [["integridad", "Integridad"], ["ciencia", "Ciencia"], ["datos", "Memoria de datos"]]
const RACIONES: Array = ["completa", "reducida", "minima"]
const INSTRUMENTOS: Array = ["apagados", "basicos", "todos"]
const HIGIENES: Array = ["normal", "suspendida"]
const NOMBRE_ORDEN: Dictionary = {
	"completa": "Completa", "reducida": "Reducida", "minima": "Mínima",
	"apagados": "Apagados", "basicos": "Básicos", "todos": "Todos",
	"normal": "Normal", "suspendida": "Suspendida",
}
const TIER_TEXTO: Dictionary = {"bueno": "BUENO", "intermedio": "INTERMEDIO", "malo": "MALO"}
const ETQ_STAT: Dictionary = {"salud": "Salud", "estres": "Estrés", "hambre": "Hambre", "confianza": "Confianza"}
const UNIDAD: Dictionary = {"temperatura": " °C", "filtros": ""}
const RUTA_CABINA: String = "res://scenes/TileMaps/2x/cabina trasparente.png"

# --- Nodos del fondo ---
var fondo: Control
var luz_alerta: TextureRect

# --- Barra superior ---
var etq_dia: Label
var etq_acto: Label
var trayectoria: Control
var icono_alarma: TextureRect
var etq_alarma: Label
var boton_sonido: TextureButton
var tex_tierra: Texture2D = Estilo.icono("tierra")      # se guardan aquí para que no se liberen de la memoria
var tex_luna: Texture2D = Estilo.icono("luna")
var tex_nave: Texture2D = Estilo.icono("orion_mini")

# --- Panel de la nave ---
var filas: Dictionary = {}            # clave -> {barra, valor, nombre, icono}
var etq_temperatura: Label
var etq_filtros: Label
var etq_enlace: Label
var etq_avisos: Label
var iconos_orden: Dictionary = {}     # racion/instrumentos/higiene -> TextureRect
var marca_meta: ColorRect

# --- Panel de la tripulación ---
var tarjetas: Dictionary = {}         # id -> {panel, retrato, insignia, confianza, salud, estres, hambre}

# --- Centro ---
var centro: VBoxContainer
var banner: PanelContainer
var etq_banner_dia: Label
var etq_banner_sub: Label
var espaciador: Control
var panel_config: PanelContainer
var botones_orden: Dictionary = {}    # grupo -> {opcion -> Button}
var pistas_orden: Dictionary = {}     # grupo -> Label
var seleccion: Dictionary = {"racion": "completa", "instrumentos": "basicos", "higiene": "normal"}
var panel_central: PanelContainer
var cabecera: VBoxContainer
var scroll: ScrollContainer
var cuerpo: VBoxContainer
var pie: HBoxContainer
var barra_tiempo: ProgressBar
var etq_tiempo: Label

# --- Capas encima de todo ---
var capa_flotante: Control
var velo_dia: ColorRect
var etq_velo_dia: Label
var etq_velo_acto: Label
var pausa: Control

# --- Estado de la pantalla ---
var fase: String = "config"
var numero_decision: int = 1
var decision_actual: Dictionary = {}
var orden_opciones: Array = []
var tiempo_total: float = 0.0
var tiempo_restante: float = 0.0
var reloj_activo: bool = false
var snap_dia: Dictionary = {}
var siguiente: String = ""
var _mostrado: Dictionary = {}        # último valor dibujado de cada barra (para animar los cambios)
var _alarmas_antes: int = 0
var _en_alerta: bool = false
var _destello: float = 0.0
var _ultimo_tic: int = -1
var _ajuste_id: int = 0
var _t: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_construir_fondo()
	_construir_hud()
	_construir_capas()
	Sonido.zumbido(true)
	_actualizar_espacio(0.0)
	_mostrar_config()
	Estilo.aparecer(self, 0.6)

# ===============================================================
# CONSTRUCCIÓN DE LA PANTALLA
# ===============================================================
func _construir_fondo() -> void:
	fondo = FondoEspacio.new()
	fondo.velocidad = Vector2(14.0, 0.0)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Cabina con la ventana transparente (dibujo del equipo)
	if ResourceLoader.exists(RUTA_CABINA):
		var cabina = TextureRect.new()
		cabina.texture = load(RUTA_CABINA)
		cabina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cabina.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cabina.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		cabina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cabina.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cabina)

	# Luz roja de alerta en los bordes (se enciende con las alarmas)
	var degradado = Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	degradado.colors = PackedColorArray([Color(1, 0.1, 0.1, 0.0), Color(1, 0.1, 0.1, 0.0), Color(1, 0.1, 0.1, 0.75)])
	var tex = GradientTexture2D.new()
	tex.gradient = degradado
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 144
	luz_alerta = TextureRect.new()
	luz_alerta.texture = tex
	luz_alerta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luz_alerta.stretch_mode = TextureRect.STRETCH_SCALE
	luz_alerta.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	luz_alerta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	luz_alerta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	luz_alerta.modulate.a = 0.0
	add_child(luz_alerta)

func _construir_hud() -> void:
	var margen = MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margen)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(col)
	col.add_child(_construir_barra_superior())
	var fila = HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(fila)
	fila.add_child(_construir_panel_nave())
	fila.add_child(_construir_centro())
	fila.add_child(_construir_panel_tripulacion())

func _subtitulo(texto: String, color: Color = Estilo.C_CIAN) -> Label:
	return Estilo.nuevo_texto(texto, 16, color)

# --- Barra superior: día, acto, mapa del viaje y alarma ---
func _construir_barra_superior() -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Estilo.C_BORDE, 8)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)

	etq_dia = Estilo.nuevo_texto("DÍA 1/14", 32, Estilo.C_AMARILLO, false)
	etq_dia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(etq_dia)
	etq_acto = Estilo.nuevo_texto("", 16, Estilo.C_CIAN, false)
	etq_acto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	etq_acto.custom_minimum_size = Vector2(250, 0)
	h.add_child(etq_acto)

	trayectoria = Control.new()
	trayectoria.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trayectoria.custom_minimum_size = Vector2(300, 48)
	trayectoria.tooltip_text = "Mapa del viaje: Tierra - Luna - Tierra"
	trayectoria.draw.connect(_dibujar_trayectoria)
	h.add_child(trayectoria)

	icono_alarma = Estilo.nuevo_icono("alarma", 32)
	h.add_child(icono_alarma)
	etq_alarma = Estilo.nuevo_texto("SIN ALARMAS", 16, Estilo.C_VERDE, false)
	etq_alarma.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	etq_alarma.custom_minimum_size = Vector2(150, 0)
	etq_alarma.mouse_filter = Control.MOUSE_FILTER_STOP
	h.add_child(etq_alarma)

	boton_sonido = TextureButton.new()
	boton_sonido.ignore_texture_size = true
	boton_sonido.stretch_mode = TextureButton.STRETCH_SCALE
	boton_sonido.custom_minimum_size = Vector2(40, 40)
	boton_sonido.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boton_sonido.tooltip_text = "Activar o silenciar el sonido"
	boton_sonido.pressed.connect(_on_sonido)
	h.add_child(boton_sonido)
	_pintar_sonido()

	var menu: Button = Estilo.nuevo_boton("MENÚ", 16, 90, 40)
	Estilo.estilo_holo(menu)
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.focus_mode = Control.FOCUS_NONE
	menu.pressed.connect(_alternar_pausa)
	h.add_child(menu)
	return p

func _dibujar_trayectoria() -> void:
	var c: Control = trayectoria
	var cy: float = c.size.y * 0.5
	var x0: float = 26.0
	var x1: float = c.size.x - 30.0
	var x: float = x0 + 30.0
	while x < x1 - 30.0:
		c.draw_rect(Rect2(x, cy - 1.0, 6.0, 2.0), Color(0.5, 0.66, 0.95, 0.75))
		x += 12.0
	c.draw_texture_rect(tex_tierra, Rect2(x0 - 20.0, cy - 20.0, 40.0, 40.0), false)
	c.draw_texture_rect(tex_luna, Rect2(x1 - 20.0, cy - 20.0, 40.0, 40.0), false)
	var dia: int = GameManager.dia_actual
	var a: float = x0 + 40.0
	var b: float = x1 - 40.0
	var pos: Vector2 = Vector2.ZERO
	var hacia_derecha: bool = true
	if dia <= 4:
		pos = Vector2(lerpf(a, b, float(dia - 1) / 4.0), cy)
	elif dia <= 9:
		var ang: float = _t * 0.9
		pos = Vector2(x1 + cos(ang) * 26.0, cy + sin(ang) * 15.0)     # en órbita alrededor de la Luna
		hacia_derecha = sin(ang) < 0.0
	else:
		pos = Vector2(lerpf(b, a, float(dia - 9) / 5.0), cy)
		hacia_derecha = false
	pos.y += sin(_t * 2.2) * 2.0
	var nave: Texture2D = tex_nave
	if hacia_derecha:
		c.draw_texture_rect(nave, Rect2(pos.x - 16.0, pos.y - 16.0, 32.0, 32.0), false)
	else:
		c.draw_texture_rect(nave, Rect2(pos.x + 16.0, pos.y - 16.0, -32.0, 32.0), false)

# --- Panel izquierdo: la nave ---
func _construir_panel_nave() -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Estilo.C_BORDE, 12)
	p.custom_minimum_size = Vector2(320, 0)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var t: Label = Estilo.nuevo_texto("NAVE ORIÓN", 24, Estilo.C_CIAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for par in VITALES:
		v.add_child(_fila_recurso(String(par[0]), String(par[1]), 32, 14))
	v.add_child(HSeparator.new())
	for par in SECUNDARIAS:
		v.add_child(_fila_recurso(String(par[0]), String(par[1]), 24, 10))

	# Marca de la meta de ciencia (70 %) sobre la barra
	var barra_ciencia: ProgressBar = filas["ciencia"]["barra"]
	marca_meta = ColorRect.new()
	marca_meta.color = Estilo.C_AMARILLO
	marca_meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marca_meta.anchor_left = GameManager.CIENCIA_FINAL_BUENO / 100.0
	marca_meta.anchor_right = GameManager.CIENCIA_FINAL_BUENO / 100.0
	marca_meta.anchor_bottom = 1.0
	marca_meta.offset_left = -1
	marca_meta.offset_right = 1
	barra_ciencia.add_child(marca_meta)
	filas["ciencia"]["fila"].tooltip_text = "La marca amarilla es la meta del final bueno: %d %% de ciencia." % int(GameManager.CIENCIA_FINAL_BUENO)

	v.add_child(HSeparator.new())
	var estado = GridContainer.new()
	estado.columns = 2
	estado.add_theme_constant_override("h_separation", 8)
	estado.add_theme_constant_override("v_separation", 2)
	v.add_child(estado)
	estado.add_child(Estilo.nuevo_icono("temperatura", 24))
	etq_temperatura = Estilo.nuevo_texto("", 16)
	estado.add_child(etq_temperatura)
	estado.add_child(Estilo.nuevo_icono("filtros", 24))
	etq_filtros = Estilo.nuevo_texto("", 16)
	estado.add_child(etq_filtros)
	estado.add_child(Estilo.nuevo_icono("enlace", 24))
	etq_enlace = Estilo.nuevo_texto("", 16)
	estado.add_child(etq_enlace)
	etq_avisos = Estilo.nuevo_texto("", 16, Estilo.C_NARANJA)
	etq_avisos.visible = false
	v.add_child(etq_avisos)

	v.add_child(HSeparator.new())
	v.add_child(_subtitulo("ÓRDENES DE HOY"))
	var ordenes = HBoxContainer.new()
	ordenes.add_theme_constant_override("separation", 12)
	ordenes.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(ordenes)
	for grupo in ["racion", "instrumentos", "higiene"]:
		var ic: TextureRect = Estilo.nuevo_icono("racion_completa", 40)
		ic.mouse_filter = Control.MOUSE_FILTER_STOP
		ordenes.add_child(ic)
		iconos_orden[grupo] = ic
	return p

func _fila_recurso(clave: String, nombre: String, tam_icono: int, alto_barra: int) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var ic: TextureRect = Estilo.nuevo_icono(clave, tam_icono)
	h.add_child(ic)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var linea = HBoxContainer.new()
	v.add_child(linea)
	var etq: Label = Estilo.nuevo_texto(nombre, 16, Estilo.C_TEXTO, false)
	etq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linea.add_child(etq)
	var valor: Label = Estilo.nuevo_texto("100 %", 16, Estilo.C_TEXTO, false)
	linea.add_child(valor)
	var barra: ProgressBar = Estilo.nueva_barra(Estilo.C_VERDE, alto_barra)
	v.add_child(barra)
	filas[clave] = {"barra": barra, "valor": valor, "nombre": etq, "icono": ic, "fila": h}
	return h

# --- Panel derecho: la tripulación ---
func _construir_panel_tripulacion() -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Estilo.C_BORDE, 12)
	p.custom_minimum_size = Vector2(340, 0)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t: Label = Estilo.nuevo_texto("TRIPULACIÓN", 24, Estilo.C_CIAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for id in GameManager.TRIPULANTES:
		v.add_child(_tarjeta_tripulante(String(id)))
	return p

func _tarjeta_tripulante(id: String) -> PanelContainer:
	var datos: Dictionary = GameManager.tripulantes[id]
	var color: Color = Estilo.ACENTO[id]
	var panel: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Color(color, 0.7), 8)
	panel.tooltip_text = "%s\n%s" % [datos["nombre"], datos["rol"]]
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)
	var retrato: PanelContainer = Estilo.nuevo_retrato(id, "normal", 2)
	h.add_child(retrato)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	var nombre: Label = Estilo.nuevo_texto(String(datos["nombre"]), 16, color, false)
	nombre.clip_text = true
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(nombre)
	var linea = HBoxContainer.new()
	v.add_child(linea)
	var insignia: Label = Estilo.nuevo_texto("ESTABLE", 16, Estilo.C_VERDE, false)
	insignia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linea.add_child(insignia)
	var ic_conf: TextureRect = Estilo.nuevo_icono("confianza", 16)
	ic_conf.mouse_filter = Control.MOUSE_FILTER_STOP
	ic_conf.tooltip_text = "Confianza en tu mando. Si baja de 30, puede ignorar tus órdenes."
	linea.add_child(ic_conf)
	var confianza: Label = Estilo.nuevo_texto("70", 16, Estilo.C_AMARILLO, false)
	linea.add_child(confianza)
	var tarjeta: Dictionary = {"panel": panel, "retrato": retrato, "insignia": insignia, "confianza": confianza}
	for par in [["salud", Estilo.C_VERDE], ["estres", Estilo.C_VIOLETA], ["hambre", Estilo.C_NARANJA]]:
		var f = HBoxContainer.new()
		f.add_theme_constant_override("separation", 6)
		v.add_child(f)
		var ic: TextureRect = Estilo.nuevo_icono(String(par[0]), 16)
		ic.mouse_filter = Control.MOUSE_FILTER_STOP
		ic.tooltip_text = String(ETQ_STAT[par[0]])
		f.add_child(ic)
		var barra: ProgressBar = Estilo.nueva_barra(par[1], 10)
		f.add_child(barra)
		var valor: Label = Estilo.nuevo_texto("0", 16, Estilo.C_TEXTO_SUAVE, false)
		valor.custom_minimum_size = Vector2(30, 0)
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		f.add_child(valor)
		tarjeta[par[0]] = {"barra": barra, "valor": valor}
	tarjetas[id] = tarjeta
	return panel

# --- Centro: título del día, órdenes y panel de decisiones ---
func _construir_centro() -> VBoxContainer:
	centro = VBoxContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 8)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	banner = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.78), Estilo.C_AMARILLO, 10)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(banner)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	banner.add_child(vb)
	etq_banner_dia = Estilo.nuevo_texto("DÍA 1", 48, Estilo.C_AMARILLO, false)
	etq_banner_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(etq_banner_dia)
	etq_banner_sub = Estilo.nuevo_texto("", 16, Estilo.C_TEXTO, false)
	etq_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(etq_banner_sub)

	espaciador = Control.new()
	espaciador.size_flags_vertical = Control.SIZE_EXPAND_FILL
	espaciador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(espaciador)

	panel_config = _construir_config()
	centro.add_child(panel_config)

	panel_central = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.95), Estilo.C_CIAN, 14)
	panel_central.visible = false
	centro.add_child(panel_central)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel_central.add_child(v)
	cabecera = VBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 6)
	v.add_child(cabecera)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	cuerpo = VBoxContainer.new()
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 8)
	scroll.add_child(cuerpo)
	pie = HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 12)
	v.add_child(pie)
	return centro

func _construir_config() -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.93), Estilo.C_CIAN, 14)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var t: Label = Estilo.nuevo_texto("ÓRDENES DEL DÍA", 24, Estilo.C_CIAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub: Label = Estilo.nuevo_texto("Gastar menos cuida las reservas, pero sube el hambre o el estrés. Tú decides.", 16, Estilo.C_TEXTO_SUAVE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(_grupo_orden("racion", "Ración de comida", RACIONES, "racion_"))
	v.add_child(_grupo_orden("instrumentos", "Instrumentos", INSTRUMENTOS, "instrumentos_"))
	v.add_child(_grupo_orden("higiene", "Higiene", HIGIENES, "higiene_"))
	var iniciar: Button = Estilo.nuevo_boton("INICIAR EL DÍA", 32, 440, 64)
	iniciar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	iniciar.pressed.connect(_on_iniciar_dia)
	iniciar.name = "BotonIniciar"
	v.add_child(iniciar)
	return p

func _grupo_orden(grupo: String, titulo: String, opciones: Array, prefijo_icono: String) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var etq: Label = Estilo.nuevo_texto(titulo, 16, Estilo.C_TEXTO, false)
	etq.custom_minimum_size = Vector2(170, 0)
	etq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(etq)
	var botones: Dictionary = {}
	var grupo_botones = ButtonGroup.new()
	for op in opciones:
		var b = Button.new()
		b.text = String(NOMBRE_ORDEN[op])
		b.icon = Estilo.icono(prefijo_icono + String(op))
		b.toggle_mode = true
		b.button_group = grupo_botones
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		Estilo.estilo_holo(b)
		b.pressed.connect(_on_orden.bind(grupo, String(op)))
		h.add_child(b)
		botones[op] = b
	botones_orden[grupo] = botones
	var pista: Label = Estilo.nuevo_texto("", 16, Estilo.C_VERDE)
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(pista)
	pistas_orden[grupo] = pista
	return v

# --- Capas: números flotantes, cambio de día y pausa ---
func _construir_capas() -> void:
	capa_flotante = Control.new()
	capa_flotante.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_flotante.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa_flotante)

	velo_dia = ColorRect.new()
	velo_dia.color = Color(0, 0, 0, 1)
	velo_dia.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo_dia.visible = false
	add_child(velo_dia)
	var c = CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo_dia.add_child(c)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	c.add_child(v)
	etq_velo_dia = Estilo.nuevo_texto("DÍA 2", 96, Estilo.C_AMARILLO, false)
	etq_velo_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(etq_velo_dia)
	etq_velo_acto = Estilo.nuevo_texto("", 24, Estilo.C_CIAN, false)
	etq_velo_acto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(etq_velo_acto)

	pausa = Control.new()
	pausa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pausa.visible = false
	add_child(pausa)
	var sombra = ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.7)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pausa.add_child(sombra)
	var c2 = CenterContainer.new()
	c2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pausa.add_child(c2)
	var caja: PanelContainer = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.98), Estilo.C_AMARILLO, 24)
	c2.add_child(caja)
	var v2 = VBoxContainer.new()
	v2.add_theme_constant_override("separation", 14)
	caja.add_child(v2)
	var t: Label = Estilo.nuevo_texto("MISIÓN EN PAUSA", 32, Estilo.C_AMARILLO, false)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v2.add_child(t)
	var aviso: Label = Estilo.nuevo_texto("Si sales al menú se pierde esta partida.", 16, Estilo.C_TEXTO_SUAVE, false)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v2.add_child(aviso)
	var seguir: Button = Estilo.nuevo_boton("SEGUIR JUGANDO", 24, 380, 56)
	seguir.pressed.connect(_alternar_pausa)
	v2.add_child(seguir)
	var salir: Button = Estilo.nuevo_boton("SALIR AL MENÚ", 24, 380, 56)
	salir.pressed.connect(func(): Estilo.cambiar_escena(self, "res://scenes/main_menu.tscn"))
	v2.add_child(salir)

# ===============================================================
# TEXTOS DEL VIAJE
# ===============================================================
func _acto(dia: int) -> Array:
	if dia <= 4:
		return ["ACTO I", "El tránsito y las primeras grietas"]
	if dia <= 10:
		return ["ACTO II", "La órbita lunar y el punto de quiebre"]
	return ["ACTO III", "El abismo de regreso"]

func _tramo(dia: int) -> String:
	if dia <= 4:
		return "Rumbo a la Luna"
	if dia <= 9:
		return "En órbita lunar"
	if dia <= 13:
		return "Regreso a la Tierra"
	return "Reentrada en la atmósfera"

# La Tierra y la Luna se ven más grandes o más pequeñas según en qué parte del viaje estamos
func _actualizar_espacio(duracion: float) -> void:
	var dia: int = GameManager.dia_actual
	if dia <= 4:
		var f: float = float(dia - 1) / 3.0
		fondo.colocar("tierra", Vector2(0.40, 0.33), lerpf(3.5, 1.0, f), duracion)
		fondo.colocar("luna", Vector2(0.62, 0.26), lerpf(0.5, 2.0, f), duracion)
	elif dia <= 9:
		fondo.colocar("luna", Vector2(0.50, 0.36), 3.5, duracion)
		fondo.colocar("tierra", Vector2(0.66, 0.19), 0.5, duracion)
	else:
		var f2: float = float(dia - 10) / 4.0
		fondo.colocar("luna", Vector2(0.38, 0.24), lerpf(2.0, 0.5, f2), duracion)
		fondo.colocar("tierra", Vector2(0.58, 0.34), lerpf(1.0, 4.0, f2), duracion)

# ===============================================================
# FASE 1: ÓRDENES DEL DÍA
# ===============================================================
func _mostrar_config() -> void:
	fase = "config"
	reloj_activo = false
	var dia: int = GameManager.dia_actual
	var acto: Array = _acto(dia)
	etq_banner_dia.text = "DÍA %d DE %d" % [dia, GameManager.DIAS_TOTALES]
	var sub: String = _tramo(dia)
	var hito: Dictionary = Eventos.hito_del_dia(dia)
	if not hito.is_empty():
		sub = "Hoy: " + String(hito["tema"])
	etq_banner_sub.text = sub

	seleccion["racion"] = GameManager.racion
	seleccion["instrumentos"] = GameManager.instrumentos
	seleccion["higiene"] = "suspendida" if GameManager.higiene_suspendida else "normal"
	for grupo in botones_orden:
		for op in botones_orden[grupo]:
			var b: Button = botones_orden[grupo][op]
			b.set_pressed_no_signal(String(op) == String(seleccion[grupo]))
			if grupo == "instrumentos":
				b.disabled = GameManager.instrumentos_bloqueados
		_pintar_pista(String(grupo))

	banner.visible = true
	espaciador.visible = true
	panel_config.visible = true
	panel_central.visible = false
	Sonido.musica("musica_contrarreloj" if String(acto[0]) == "ACTO III" else "musica_tension")
	actualizar_hud(false)
	var iniciar: Button = panel_config.find_child("BotonIniciar", true, false)
	if iniciar != null:
		iniciar.grab_focus.call_deferred()

func _on_orden(grupo: String, opcion: String) -> void:
	seleccion[grupo] = opcion
	_pintar_pista(grupo)

# Explica con números qué hace la opción elegida (los números salen de GameManager)
func _pintar_pista(grupo: String) -> void:
	var op: String = String(seleccion[grupo])
	var texto: String = ""
	match grupo:
		"racion":
			texto = "Gasto de comida x%s  ·  Hambre %s por día" % [
				str(GameManager.COMIDA_RACION[op]).replace(".", ","), GameManager.signo(float(GameManager.HAMBRE_RACION[op]))]
		"instrumentos":
			if GameManager.instrumentos_bloqueados:
				texto = "Carga científica soltada: los instrumentos ya no funcionan."
			elif op == "apagados":
				texto = "Sin gasto extra, pero la ciencia no avanza"
			else:
				texto = "Ciencia +%s  ·  Datos +%s  ·  Electricidad -%s por día" % [
					str(GameManager.CIENCIA_DIA[op]).replace(".", ","), str(GameManager.DATOS_DIA[op]).replace(".", ","),
					str(GameManager.ELEC_INSTRUMENTOS[op]).replace(".", ",")]
		"higiene":
			if op == "normal":
				texto = "Consumo de agua normal"
			else:
				texto = "Ahorra 15 %% de agua  ·  Estrés +%d por día para todos" % int(GameManager.ESTRES_AISLAMIENTO_HIGIENE)
	pistas_orden[grupo].text = texto

func _on_iniciar_dia() -> void:
	if fase != "config":
		return
	GameManager.racion = String(seleccion["racion"])
	if not GameManager.instrumentos_bloqueados:
		GameManager.instrumentos = String(seleccion["instrumentos"])
	GameManager.higiene_suspendida = (String(seleccion["higiene"]) == "suspendida")
	snap_dia = GameManager.instantanea()
	var lineas: Array = GameManager.procesar_inicio_dia()
	var despues: Dictionary = GameManager.instantanea()
	actualizar_hud(true)
	_mostrar_registro(lineas, snap_dia, despues)

# ===============================================================
# FASE 2: REGISTRO DEL DÍA (consumo automático y eventos por estrés)
# ===============================================================
func _mostrar_registro(lineas: Array, antes: Dictionary, despues: Dictionary) -> void:
	fase = "registro"
	_abrir_panel(Estilo.C_CIAN)
	var t: Label = Estilo.nuevo_texto("REGISTRO DEL DÍA %d" % GameManager.dia_actual, 32, Estilo.C_AMARILLO)
	cabecera.add_child(t)
	cabecera.add_child(Estilo.nuevo_texto("Esto gastó la nave hoy solo por mantener viva a la tripulación:", 16, Estilo.C_TEXTO_SUAVE))
	_agregar_fichas(cuerpo, _fichas_cambios(antes, despues))
	var hubo_novedad: bool = false
	for linea in lineas:
		var texto: String = String(linea)
		if texto.begins_with("Consumo diario"):
			continue
		if not hubo_novedad:
			cuerpo.add_child(_subtitulo("NOVEDADES"))
			hubo_novedad = true
		var icono: String = "alarma"
		var color: Color = Estilo.C_TEXTO
		if texto.begins_with("Estrés"):
			icono = "estres"
			color = Estilo.C_VIOLETA
		elif texto.contains("ha muerto"):
			icono = "sin_senal"
			color = Estilo.C_ROJO
		cuerpo.add_child(_aviso(texto, color, icono))
	if GameManager.hay_final_inmediato():
		siguiente = "final"
		_boton_pie("VER EL DESENLACE DE LA MISIÓN")
	else:
		siguiente = "decision1"
		_boton_pie("CONTINUAR")
	_cerrar_panel()

# ===============================================================
# FASE 3: DECISIONES
# ===============================================================
func _mostrar_decision() -> void:
	decision_actual = GameManager.elegir_decision(numero_decision)
	if decision_actual.is_empty():
		_cerrar_dia()
		return
	var d: Dictionary = decision_actual
	if d.has("al_iniciar"):
		GameManager.aplicar_efecto(d["al_iniciar"])
		actualizar_hud(true)
	fase = "decision"
	reloj_activo = false

	var categoria: String = String(d["categoria"])
	var gravedad: int = int(d["gravedad"])
	var color: Color = Estilo.C_VERDE
	var tipo: String = "GESTIÓN DE RECURSOS"
	if categoria == "nave":
		tipo = "EMERGENCIA EN LA NAVE"
		color = Estilo.C_ROJO if gravedad >= 3 else Estilo.C_NARANJA
		Sonido.efecto("alarma" if gravedad >= 2 else "aviso")
		_destello = 1.0 if gravedad >= 2 else 0.4
	elif categoria == "hito":
		tipo = "MOMENTO CLAVE DE LA MISIÓN"
		color = Estilo.C_AMARILLO
		Sonido.efecto("estatica")
	else:
		Sonido.efecto("aviso")
	_abrir_panel(color)

	# --- Cabecera: tipo, gravedad y número de decisión ---
	var linea = HBoxContainer.new()
	linea.add_theme_constant_override("separation", 8)
	cabecera.add_child(linea)
	var etiqueta: PanelContainer = Estilo.nuevo_panel(Color(color, 0.18), color, 6)
	etiqueta.add_child(Estilo.nuevo_texto(tipo, 16, color, false))
	linea.add_child(etiqueta)
	if categoria == "nave":
		for i in gravedad:
			linea.add_child(Estilo.nuevo_icono("alarma", 24))
	var relleno = Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linea.add_child(relleno)
	var cuenta: Label = Estilo.nuevo_texto("DECISIÓN %d DE 2" % numero_decision, 16, Estilo.C_TEXTO_SUAVE, false)
	cuenta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linea.add_child(cuenta)
	cabecera.add_child(Estilo.nuevo_texto(String(d["tema"]).to_upper(), 24, Estilo.C_TEXTO))

	# --- Temporizador (el estrés de Elena puede recortarlo) ---
	tiempo_total = maxf(5.0, float(d["tiempo_s"]) - GameManager.penal_tiempo)
	GameManager.penal_tiempo = 0.0
	tiempo_restante = tiempo_total
	_ultimo_tic = -1
	var fila_tiempo = HBoxContainer.new()
	fila_tiempo.add_theme_constant_override("separation", 8)
	cabecera.add_child(fila_tiempo)
	if GameManager.modo_sin_temporizador:
		fila_tiempo.add_child(Estilo.nuevo_icono("reloj", 24))
		fila_tiempo.add_child(Estilo.nuevo_texto("MODO APRENDIZAJE: decide sin límite de tiempo", 16, Estilo.C_VERDE))
		barra_tiempo = null
		etq_tiempo = null
	else:
		fila_tiempo.add_child(Estilo.nuevo_icono("reloj", 32))
		barra_tiempo = Estilo.nueva_barra(Estilo.C_VERDE, 20)
		barra_tiempo.max_value = tiempo_total
		barra_tiempo.value = tiempo_total
		fila_tiempo.add_child(barra_tiempo)
		etq_tiempo = Estilo.nuevo_texto("%d s" % ceili(tiempo_total), 24, Estilo.C_TEXTO, false)
		etq_tiempo.custom_minimum_size = Vector2(70, 0)
		etq_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila_tiempo.add_child(etq_tiempo)

	# --- Quién habla y qué pasa ---
	var resp: String = String(d.get("responsable", ""))
	var escena = HBoxContainer.new()
	escena.add_theme_constant_override("separation", 12)
	cuerpo.add_child(escena)
	if GameManager.tripulantes.has(resp):
		var t: Dictionary = GameManager.tripulantes[resp]
		var quien = VBoxContainer.new()
		quien.add_theme_constant_override("separation", 2)
		escena.add_child(quien)
		quien.add_child(Estilo.nuevo_retrato(resp, Estilo.expresion(float(t["salud"]), float(t["estres"])), 3))
		var nombre: Label = Estilo.nuevo_texto(String(GameManager.NOMBRES_TRIPULANTE[resp]), 16, Estilo.ACENTO[resp], false)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quien.add_child(nombre)
		var rol: Label = Estilo.nuevo_texto("Responsable", 16, Estilo.C_TEXTO_SUAVE, false)
		rol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quien.add_child(rol)
	var globo: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Color(color, 0.6), 14)
	globo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	escena.add_child(globo)
	var vg = VBoxContainer.new()
	vg.add_theme_constant_override("separation", 8)
	globo.add_child(vg)
	vg.add_child(Estilo.nuevo_texto(String(d["texto"]), 16, Estilo.C_TEXTO))
	var aborto: bool = GameManager.aborto_disponible()
	if d.get("ruta_aborto", false) and aborto:
		vg.add_child(_aviso("Tus reservas están en rojo: puedes soltar la carga científica para aligerar la nave.", Estilo.C_ROJO, "alarma"))

	# --- Opciones (se barajan para que la buena no esté siempre en el mismo lugar) ---
	var indices: Array = []
	var extra: Array = []
	for i in d["opciones"].size():
		var o: Dictionary = d["opciones"][i]
		if o.get("requiere_aborto", false):
			if aborto:
				extra.append(i)
			continue
		indices.append(i)
	indices.shuffle()
	orden_opciones = indices + extra
	var letras: Array = ["A", "B", "C", "D"]
	for pos in orden_opciones.size():
		var opcion: Dictionary = d["opciones"][orden_opciones[pos]]
		cuerpo.add_child(_tarjeta_opcion(String(letras[pos]), opcion, int(orden_opciones[pos]), color))
	var ayuda: Label = Estilo.nuevo_texto("Elige con el ratón o con las teclas A, B, C", 16, Estilo.C_TEXTO_SUAVE)
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.add_child(ayuda)

	_resaltar_responsable(resp)
	actualizar_hud(true)
	await _cerrar_panel()
	if fase == "decision":
		reloj_activo = not GameManager.modo_sin_temporizador

func _tarjeta_opcion(letra: String, opcion: Dictionary, indice: int, color: Color) -> PanelContainer:
	var normal: StyleBoxFlat = Estilo.caja(Color(0.06, 0.09, 0.18, 0.96), Color(Estilo.C_BORDE, 0.9), 2, 10)
	var encima: StyleBoxFlat = Estilo.caja(Color(0.12, 0.18, 0.32, 1.0), Estilo.C_AMARILLO, 3, 9)
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", normal)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var marca: PanelContainer = Estilo.nuevo_panel(Color(color, 0.2), color, 4)
	marca.custom_minimum_size = Vector2(48, 48)
	marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l: Label = Estilo.nuevo_texto(letra, 32, color, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marca.add_child(l)
	h.add_child(marca)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var titulo: Label = Estilo.nuevo_texto(String(opcion["texto"]), 16, Estilo.C_TEXTO)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(titulo)
	var detalle: String = String(opcion.get("descripcion", ""))
	if detalle != "":
		var sub: Label = Estilo.nuevo_texto(detalle, 16, Estilo.C_TEXTO_SUAVE)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(sub)
	p.mouse_entered.connect(func(): p.add_theme_stylebox_override("panel", encima))
	p.mouse_exited.connect(func(): p.add_theme_stylebox_override("panel", normal))
	p.gui_input.connect(func(evento: InputEvent):
		if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			_on_opcion(indice))
	return p

func _on_opcion(indice: int) -> void:
	if fase != "decision" or pausa.visible:
		return
	Sonido.clic()
	_resolver(indice, false)

func _resolver(indice: int, por_tiempo: bool) -> void:
	fase = "feedback"
	reloj_activo = false
	var antes: Dictionary = GameManager.instantanea()
	var res: Dictionary = GameManager.resolver(decision_actual, indice, por_tiempo)
	var despues: Dictionary = GameManager.instantanea()
	_resaltar_responsable("")
	actualizar_hud(true)
	_mostrar_feedback(res, antes, despues)

# ===============================================================
# FASE 4: RESULTADO DE LA DECISIÓN
# ===============================================================
func _mostrar_feedback(res: Dictionary, antes: Dictionary, despues: Dictionary) -> void:
	var tier: String = String(res["tier"])
	var color: Color = Estilo.COLOR_RESULTADO[tier]
	var opcion: Dictionary = res["opcion"]
	Sonido.efecto({"bueno": "exito", "intermedio": "aviso", "malo": "fallo"}[tier])
	if tier == "malo":
		_destello = 0.8
	_abrir_panel(color)

	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	cabecera.add_child(h)
	h.add_child(Estilo.nuevo_icono("resultado_" + tier, 64))
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(Estilo.nuevo_texto("RESULTADO: " + String(TIER_TEXTO[tier]), 32, color))
	v.add_child(Estilo.nuevo_texto("Decisión: " + String(opcion["texto"]), 16, Estilo.C_TEXTO))

	if String(res["nota"]) != "":
		cuerpo.add_child(_aviso(String(res["nota"]), Estilo.C_NARANJA, "reloj"))
	for m in res["muertes"]:
		cuerpo.add_child(_aviso(String(m), Estilo.C_ROJO, "sin_senal"))

	cuerpo.add_child(_subtitulo("QUÉ PASÓ"))
	var fichas: Array = _fichas_cambios(antes, despues)
	if fichas.is_empty():
		cuerpo.add_child(Estilo.nuevo_texto("Las barras no cambiaron.", 16, Estilo.C_TEXTO_SUAVE))
	else:
		_agregar_fichas(cuerpo, fichas)

	var por_que: String = String(opcion.get("por_que", ""))
	if por_que != "":
		cuerpo.add_child(_subtitulo("POR QUÉ"))
		cuerpo.add_child(Estilo.nuevo_texto(por_que, 16, Estilo.C_TEXTO))

	cuerpo.add_child(_tarjeta_memo(Memos.para_decision(decision_actual), String(opcion.get("fuente", ""))))

	# Análisis completo (se abre con un botón para no llenar la pantalla de texto)
	var analisis = VBoxContainer.new()
	analisis.add_theme_constant_override("separation", 4)
	analisis.visible = false
	if not res["factores"].is_empty():
		analisis.add_child(_subtitulo("FACTORES QUE PESARON"))
		for f in res["factores"]:
			analisis.add_child(Estilo.nuevo_texto("- " + String(f), 16, Estilo.C_TEXTO_SUAVE))
	if not res["alternativas"].is_empty():
		analisis.add_child(_subtitulo("QUÉ HABRÍA PASADO CON LAS OTRAS OPCIONES"))
		for a in res["alternativas"]:
			analisis.add_child(_linea_alternativa(String(a)))
	if analisis.get_child_count() > 0:
		var ver: Button = Estilo.nuevo_boton("VER ANÁLISIS COMPLETO", 16, 0, 40)
		Estilo.estilo_holo(ver)
		ver.focus_mode = Control.FOCUS_NONE
		ver.pressed.connect(func():
			analisis.visible = not analisis.visible
			ver.text = "OCULTAR ANÁLISIS" if analisis.visible else "VER ANÁLISIS COMPLETO"
			_ajustar_panel(false))
		cuerpo.add_child(ver)
		cuerpo.add_child(analisis)

	if GameManager.hay_final_inmediato():
		siguiente = "final"
		_boton_pie("VER EL DESENLACE DE LA MISIÓN")
	elif numero_decision == 1:
		siguiente = "decision2"
		_boton_pie("CONTINUAR")
	else:
		siguiente = "cerrar"
		_boton_pie("VER EL RESUMEN DEL DÍA")
	_cerrar_panel()

# Una alternativa llega como "texto: TIER (efectos)". Se pinta el nivel con su color.
func _linea_alternativa(texto: String) -> Label:
	var color: Color = Estilo.C_TEXTO_SUAVE
	for tier in TIER_TEXTO:
		if texto.contains(": %s (" % TIER_TEXTO[tier]):
			color = Estilo.COLOR_RESULTADO[tier].lerp(Estilo.C_TEXTO, 0.35)
	return Estilo.nuevo_texto("- " + texto, 16, color)

func _tarjeta_memo(memo: Dictionary, fuente_opcion: String) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Color(0.05, 0.12, 0.10, 0.95), Estilo.C_VERDE, 10)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var ic: TextureRect = Estilo.nuevo_icono("memo", 48)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(ic)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)
	var texto: String = String(memo["texto"])
	if texto != "":
		v.add_child(Estilo.nuevo_texto("MEMO NASA: " + String(memo["titulo"]), 16, Estilo.C_VERDE))
		v.add_child(Estilo.nuevo_texto(texto, 16, Estilo.C_TEXTO))
	else:
		v.add_child(Estilo.nuevo_texto("PARA SABER MÁS: " + String(memo["titulo"]), 16, Estilo.C_VERDE))
	var url: String = fuente_opcion if fuente_opcion != "" else String(memo["url"])
	var nombre: String = "Fuente NASA de esta decisión" if fuente_opcion != "" else String(memo["fuente"])
	var enlace: Button = Estilo.nuevo_boton("Abrir: " + nombre, 16, 0, 36)
	Estilo.estilo_holo(enlace, Estilo.C_VERDE)
	enlace.focus_mode = Control.FOCUS_NONE
	enlace.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	enlace.tooltip_text = url
	enlace.pressed.connect(OS.shell_open.bind(url))
	v.add_child(enlace)
	return p

func _on_continuar() -> void:
	match siguiente:
		"decision1":
			numero_decision = 1
			_mostrar_decision()
		"decision2":
			numero_decision = 2
			_mostrar_decision()
		"cerrar":
			_cerrar_dia()
		"dia":
			_siguiente_dia()
		"final":
			_ir_al_final()

# ===============================================================
# FASE 5: RESUMEN DEL DÍA
# ===============================================================
func _cerrar_dia() -> void:
	fase = "resumen"
	reloj_activo = false
	var ahora: Dictionary = GameManager.instantanea()
	_abrir_panel(Estilo.C_CIAN)
	cabecera.add_child(Estilo.nuevo_texto("RESUMEN DEL DÍA %d" % GameManager.dia_actual, 32, Estilo.C_AMARILLO))
	cabecera.add_child(Estilo.nuevo_texto("Todo lo que cambió hoy, de la mañana a la noche:", 16, Estilo.C_TEXTO_SUAVE))
	var fichas: Array = _fichas_cambios(snap_dia, ahora)
	if fichas.is_empty():
		cuerpo.add_child(Estilo.nuevo_texto("Sin cambios.", 16, Estilo.C_TEXTO_SUAVE))
	else:
		_agregar_fichas(cuerpo, fichas)
	for a in GameManager.alarmas():
		cuerpo.add_child(_aviso("ALARMA: " + String(a), Estilo.C_ROJO, "alarma"))
	GameManager.cerrar_dia()
	if GameManager.hay_final_inmediato() or GameManager.dia_actual >= GameManager.DIAS_TOTALES:
		siguiente = "final"
		_boton_pie("VER EL DESENLACE DE LA MISIÓN")
	else:
		var faltan: int = GameManager.DIAS_TOTALES - GameManager.dia_actual
		cuerpo.add_child(Estilo.nuevo_texto("Faltan %d día(s) para volver a la Tierra." % faltan, 16, Estilo.C_CIAN))
		siguiente = "dia"
		_boton_pie("CONTINUAR AL DÍA %d" % (GameManager.dia_actual + 1))
	actualizar_hud(true)
	_cerrar_panel()

func _siguiente_dia() -> void:
	if fase == "transicion":
		return
	fase = "transicion"
	var nuevo: int = GameManager.dia_actual + 1
	var acto: Array = _acto(nuevo)
	etq_velo_dia.text = "DÍA %d" % nuevo
	etq_velo_acto.text = "%s  ·  %s" % [acto[0], _tramo(nuevo)]
	velo_dia.modulate.a = 0.0
	velo_dia.visible = true
	var tw: Tween = create_tween()
	tw.tween_property(velo_dia, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func():
		GameManager.dia_actual = nuevo
		_actualizar_espacio(0.0)
		_mostrar_config())
	tw.tween_interval(0.9)
	tw.tween_property(velo_dia, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): velo_dia.visible = false)

func _ir_al_final() -> void:
	if fase == "saliendo":
		return
	fase = "saliendo"
	Estilo.cambiar_escena(self, "res://scenes/final.tscn", 0.8)

# ===============================================================
# PIEZAS DEL PANEL CENTRAL
# ===============================================================
func _limpiar(nodo: Node) -> void:
	for hijo in nodo.get_children():
		nodo.remove_child(hijo)
		hijo.queue_free()

func _abrir_panel(color: Color) -> void:
	_limpiar(cabecera)
	_limpiar(cuerpo)
	_limpiar(pie)
	panel_central.add_theme_stylebox_override("panel", Estilo.caja(Color(0.03, 0.05, 0.11, 0.95), color, 2, 14))
	banner.visible = false
	espaciador.visible = false
	panel_config.visible = false
	panel_central.visible = true
	panel_central.modulate.a = 0.0

func _cerrar_panel() -> void:
	await _ajustar_panel(true)

# El panel toma el alto de su contenido; si no cabe en la pantalla, aparece la barra de desplazamiento.
func _ajustar_panel(con_fundido: bool) -> void:
	_ajuste_id += 1
	var mi_id: int = _ajuste_id
	scroll.custom_minimum_size.y = 0
	for vuelta in 2:
		await get_tree().process_frame
		await get_tree().process_frame
		if mi_id != _ajuste_id:
			return
		var alto: float = cuerpo.get_combined_minimum_size().y
		var otros: float = panel_central.get_combined_minimum_size().y - scroll.custom_minimum_size.y
		var maximo: float = maxf(centro.size.y - otros, 120.0)
		scroll.custom_minimum_size.y = minf(alto, maximo)
	scroll.scroll_vertical = 0
	if con_fundido:
		var tw: Tween = create_tween()
		tw.tween_property(panel_central, "modulate:a", 1.0, 0.2)
		await tw.finished

func _boton_pie(texto: String) -> void:
	var b: Button = Estilo.nuevo_boton(texto, 24, 460, 56)
	b.pressed.connect(_on_continuar)
	pie.add_child(b)
	b.grab_focus.call_deferred()

func _aviso(texto: String, color: Color, icono: String) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Color(color, 0.12), Color(color, 0.8), 8)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, 32))
	h.add_child(Estilo.nuevo_texto(texto, 16, color.lerp(Color(1, 1, 1), 0.45)))
	return p

func _agregar_fichas(padre: Control, fichas: Array) -> void:
	var flujo = HFlowContainer.new()
	flujo.add_theme_constant_override("h_separation", 8)
	flujo.add_theme_constant_override("v_separation", 8)
	padre.add_child(flujo)
	for f in fichas:
		flujo.add_child(f)

# Ficha de color: icono + nombre + cuánto cambió
func _ficha(icono: String, texto: String, valor: String, color: Color, color_texto: Color = Estilo.C_TEXTO) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Color(color, 0.14), Color(color, 0.85), 6)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, 32))
	h.add_child(Estilo.nuevo_texto(texto, 16, color_texto, false))
	h.add_child(Estilo.nuevo_texto(valor, 24, color, false))
	return p

# Compara dos "fotos" del estado (GameManager.instantanea) y devuelve una ficha por cada cosa que cambió
func _fichas_cambios(antes: Dictionary, despues: Dictionary) -> Array:
	var lista: Array = []
	for clave in ["agua", "comida", "oxigeno", "electricidad", "combustible", "integridad", "datos", "ciencia", "temperatura", "filtros"]:
		var d: float = float(despues[clave]) - float(antes[clave])
		if absf(d) < 0.5:
			continue
		var color: Color = Estilo.C_VERDE if d > 0.0 else Estilo.C_ROJO
		if clave == "datos":
			color = Estilo.C_VERDE if d < 0.0 else Estilo.C_AMARILLO
		elif clave == "temperatura":
			color = Estilo.C_AMARILLO
		var nombre: String = String(GameManager.ETIQUETAS.get(clave, clave)).replace(" (°C)", "")
		lista.append(_ficha(clave, nombre, GameManager.signo(d) + String(UNIDAD.get(clave, " %")), color))
	for stat in ["salud", "estres", "hambre", "confianza"]:
		var deltas: Dictionary = {}
		for id in GameManager.TRIPULANTES:
			var d2: float = roundf(float(despues[stat + "_" + id]) - float(antes[stat + "_" + id]))
			if d2 != 0.0:
				deltas[id] = d2
		if deltas.is_empty():
			continue
		var valores: Array = deltas.values()
		var iguales: bool = true
		for v in valores:
			if v != valores[0]:
				iguales = false
		var sube_es_bueno: bool = (stat == "salud" or stat == "confianza")
		if iguales and deltas.size() >= 2 and deltas.size() == GameManager.vivos().size():
			var bueno: bool = (float(valores[0]) > 0.0) == sube_es_bueno
			lista.append(_ficha(stat, "%s de todos" % ETQ_STAT[stat], GameManager.signo(float(valores[0])), Estilo.C_VERDE if bueno else Estilo.C_ROJO))
		else:
			for id in deltas:
				var bueno2: bool = (float(deltas[id]) > 0.0) == sube_es_bueno
				lista.append(_ficha(stat, "%s de %s" % [ETQ_STAT[stat], GameManager.NOMBRES_TRIPULANTE[id]], GameManager.signo(float(deltas[id])),
					Estilo.C_VERDE if bueno2 else Estilo.C_ROJO, Estilo.ACENTO[id].lerp(Color(1, 1, 1), 0.4)))
	return lista

# ===============================================================
# HUD: barras, retratos, alarmas
# ===============================================================
func actualizar_hud(animar: bool = true) -> void:
	var dia: int = GameManager.dia_actual
	var acto: Array = _acto(dia)
	etq_dia.text = "DÍA %d/%d" % [dia, GameManager.DIAS_TOTALES]
	etq_acto.text = "%s\n%s" % [acto[0], _tramo(dia)]

	# --- Nave ---
	for par in VITALES + SECUNDARIAS:
		var clave: String = String(par[0])
		var v: float = GameManager.valor_estado(clave)
		var fila: Dictionary = filas[clave]
		var color: Color = Estilo.color_nivel(v)
		var sube_es_bueno: bool = true
		if clave == "datos":
			color = Estilo.C_ROJO if v > 85.0 else Estilo.C_CIAN
			sube_es_bueno = false
		elif clave == "ciencia":
			color = Estilo.C_VIOLETA
		Estilo.color_barra(fila["barra"], color)
		fila["valor"].text = "%d %%" % roundi(v)
		fila["valor"].add_theme_color_override("font_color", color if clave != "ciencia" else Estilo.C_TEXTO)
		_poner_barra(clave, fila["barra"], v, animar, sube_es_bueno)
	filas["ciencia"]["valor"].text = "%d / %d %%" % [roundi(GameManager.ciencia), roundi(GameManager.ciencia_max)]
	filas["ciencia"]["nombre"].text = "Ciencia (tope)"

	var temp: float = GameManager.temperatura
	var temp_ok: bool = temp >= 18.0 and temp <= 28.0
	etq_temperatura.text = "Cabina: %d °C" % roundi(temp)
	etq_temperatura.add_theme_color_override("font_color", Estilo.C_TEXTO if temp_ok else Estilo.C_ROJO)
	etq_filtros.text = "Filtros de CO2: %d" % GameManager.filtros
	etq_filtros.add_theme_color_override("font_color", Estilo.C_TEXTO if GameManager.filtros > 0 else Estilo.C_ROJO)
	if GameManager.enlace_dias > 0:
		etq_enlace.text = "Enlace PERDIDO (%d d)" % GameManager.enlace_dias
		etq_enlace.add_theme_color_override("font_color", Estilo.C_ROJO)
	else:
		etq_enlace.text = "Enlace con la Tierra"
		etq_enlace.add_theme_color_override("font_color", Estilo.C_TEXTO)
	var avisos: Array = []
	if GameManager.modulo_dias > 0:
		avisos.append("Módulo de servicio bloqueado: %d día(s)" % GameManager.modulo_dias)
	if GameManager.reparaciones_dias > 0:
		avisos.append("Reparaciones lentas: %d día(s)" % GameManager.reparaciones_dias)
	if GameManager.mision_abortada:
		avisos.append("Carga científica soltada")
	etq_avisos.text = "\n".join(avisos)
	etq_avisos.visible = not avisos.is_empty()

	var higiene: String = "suspendida" if GameManager.higiene_suspendida else "normal"
	iconos_orden["racion"].texture = Estilo.icono("racion_" + GameManager.racion)
	iconos_orden["racion"].tooltip_text = "Ración: " + String(NOMBRE_ORDEN[GameManager.racion])
	iconos_orden["instrumentos"].texture = Estilo.icono("instrumentos_" + GameManager.instrumentos)
	iconos_orden["instrumentos"].tooltip_text = "Instrumentos: " + String(NOMBRE_ORDEN[GameManager.instrumentos])
	iconos_orden["higiene"].texture = Estilo.icono("higiene_" + higiene)
	iconos_orden["higiene"].tooltip_text = "Higiene: " + String(NOMBRE_ORDEN[higiene])

	# --- Alarmas ---
	var alarmas: Array = GameManager.alarmas()
	_en_alerta = not alarmas.is_empty()
	if _en_alerta:
		etq_alarma.text = "%d ALARMA(S)" % alarmas.size()
		etq_alarma.add_theme_color_override("font_color", Estilo.C_ROJO)
		etq_alarma.tooltip_text = "\n".join(alarmas)
		if alarmas.size() > _alarmas_antes and animar:
			Sonido.efecto("alarma")
	else:
		etq_alarma.text = "SIN ALARMAS"
		etq_alarma.add_theme_color_override("font_color", Estilo.C_VERDE)
		etq_alarma.tooltip_text = "Una alarma salta cuando un recurso vital baja de %d %%." % int(GameManager.UMBRAL_ALARMA)
	_alarmas_antes = alarmas.size()

	# --- Tripulación ---
	for id in GameManager.TRIPULANTES:
		var t: Dictionary = GameManager.tripulantes[id]
		var c: Dictionary = tarjetas[id]
		var salud: float = float(t["salud"])
		var estres: float = float(t["estres"])
		Estilo.cambiar_retrato(c["retrato"], Estilo.expresion(salud, estres))
		var insignia: Array = _insignia(salud, estres)
		c["insignia"].text = String(insignia[0])
		c["insignia"].add_theme_color_override("font_color", insignia[1])
		c["confianza"].text = str(roundi(float(t["confianza"])))
		c["confianza"].add_theme_color_override("font_color", Estilo.C_ROJO if float(t["confianza"]) < 30.0 else Estilo.C_AMARILLO)
		for stat in ["salud", "estres", "hambre"]:
			var valor: float = float(t[stat])
			c[stat]["valor"].text = str(roundi(valor))
			if stat == "salud":
				Estilo.color_barra(c[stat]["barra"], Estilo.color_nivel(valor))
			_poner_barra(stat + "_" + String(id), c[stat]["barra"], valor, animar, stat == "salud")
		c["panel"].modulate = Color(0.55, 0.55, 0.62) if salud <= 0.0 else Color(1, 1, 1)

func _insignia(salud: float, estres: float) -> Array:
	if salud <= 0.0:
		return ["SIN SEÑAL", Color(0.7, 0.7, 0.78)]
	if salud < 25.0:
		return ["CRÍTICO", Estilo.C_ROJO]
	if salud < 50.0:
		return ["HERIDO", Estilo.C_NARANJA]
	if estres >= 70.0:
		return ["AL LÍMITE", Estilo.C_NARANJA]
	if estres >= 40.0:
		return ["TENSO", Estilo.C_AMARILLO]
	return ["ESTABLE", Estilo.C_VERDE]

# Mueve una barra a su nuevo valor. Si cambió, la anima y suelta un número flotante (+5, -12...)
func _poner_barra(clave: String, barra: ProgressBar, valor: float, animar: bool, sube_es_bueno: bool) -> void:
	var antes: float = float(_mostrado.get(clave, valor))
	_mostrado[clave] = valor
	var d: float = valor - antes
	if not animar or absf(d) < 0.5:
		barra.value = valor
		return
	var tw: Tween = create_tween()
	tw.tween_property(barra, "value", valor, 0.6).set_trans(Tween.TRANS_SINE)
	var bueno: bool = (d > 0.0) == sube_es_bueno
	_flotar(GameManager.signo(d), Estilo.C_VERDE if bueno else Estilo.C_ROJO, barra.global_position + Vector2(barra.size.x * 0.5 - 14.0, -26.0))

func _flotar(texto: String, color: Color, donde: Vector2) -> void:
	var l: Label = Estilo.con_borde(Estilo.nuevo_texto(texto, 24, color, false), 6)
	l.position = donde
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_flotante.add_child(l)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", donde.y - 30.0, 1.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.9)
	tw.chain().tween_callback(l.queue_free)

# Marca con borde amarillo la tarjeta del tripulante que responde por la decisión actual
func _resaltar_responsable(id: String) -> void:
	for otro in tarjetas:
		var color: Color = Estilo.ACENTO[otro]
		var es: bool = (String(otro) == id)
		tarjetas[otro]["panel"].add_theme_stylebox_override("panel",
			Estilo.caja(Color(0.12, 0.17, 0.30, 0.97) if es else Estilo.C_PANEL_CLARO, Estilo.C_AMARILLO if es else Color(color, 0.7), 3 if es else 2, 7 if es else 8))

# ===============================================================
# CADA CUADRO: reloj, luces y mapa
# ===============================================================
func _process(delta: float) -> void:
	_t += delta
	trayectoria.queue_redraw()

	# Luz roja: late mientras haya alarmas y da un destello cuando llega una emergencia
	_destello = maxf(0.0, _destello - delta * 0.8)
	var objetivo: float = _destello * (0.6 + 0.4 * sin(_t * 14.0))
	if _en_alerta:
		objetivo = maxf(objetivo, 0.35 + 0.25 * sin(_t * 4.0))
	luz_alerta.modulate.a = lerpf(luz_alerta.modulate.a, objetivo, minf(1.0, delta * 8.0))
	icono_alarma.modulate.a = (0.55 + 0.45 * sin(_t * 8.0)) if _en_alerta else 0.25

	# Las barras vitales en zona de alarma parpadean
	for par in VITALES:
		var clave: String = String(par[0])
		var bajo: bool = GameManager.valor_estado(clave) < GameManager.UMBRAL_ALARMA
		filas[clave]["icono"].modulate.a = (0.5 + 0.5 * sin(_t * 9.0)) if bajo else 1.0

	if fase != "decision" or not reloj_activo or pausa.visible:
		return
	tiempo_restante -= delta
	var queda: float = maxf(tiempo_restante, 0.0)
	if barra_tiempo != null and is_instance_valid(barra_tiempo):
		barra_tiempo.value = queda
		var fraccion: float = queda / maxf(tiempo_total, 0.01)
		var color: Color = Estilo.C_VERDE
		if fraccion < 0.25:
			color = Estilo.C_ROJO
		elif fraccion < 0.5:
			color = Estilo.C_AMARILLO
		Estilo.color_barra(barra_tiempo, color)
		etq_tiempo.text = "%d s" % ceili(queda)
		etq_tiempo.add_theme_color_override("font_color", color)
	var segundo: int = ceili(queda)
	if segundo <= 5 and segundo != _ultimo_tic:
		_ultimo_tic = segundo
		Sonido.efecto("tic")
	if tiempo_restante <= 0.0:
		_resolver(0, true)

func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla: InputEventKey = evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	if tecla.keycode == KEY_ESCAPE:
		_alternar_pausa()
		return
	if fase != "decision" or pausa.visible:
		return
	var pos: int = -1
	match tecla.keycode:
		KEY_A, KEY_1, KEY_KP_1:
			pos = 0
		KEY_B, KEY_2, KEY_KP_2:
			pos = 1
		KEY_C, KEY_3, KEY_KP_3:
			pos = 2
	if pos >= 0 and pos < orden_opciones.size():
		_on_opcion(int(orden_opciones[pos]))

func _alternar_pausa() -> void:
	if fase == "transicion" or fase == "saliendo":
		return
	pausa.visible = not pausa.visible

func _pintar_sonido() -> void:
	boton_sonido.texture_normal = Estilo.icono("sonido_off" if Sonido.silenciado else "sonido_on")

func _on_sonido() -> void:
	Sonido.alternar_silencio()
	_pintar_sonido()
