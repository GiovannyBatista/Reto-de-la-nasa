extends Control
# Generado/modificado con ayuda de IA (Claude, Anthropic) y revisado por el equipo.
# Pantalla GRÁFICA de la misión (los 14 días).
#
# Las reglas del juego NO están aquí: siguen en GameManager.gd y Eventos.gd. Este script solo dibuja.
#
# Cómo está acomodada la pantalla (pensada para mostrar poco texto):
#   ARRIBA     -> día, los 5 recursos vitales (icono + barra + número), mapa del viaje, alarma y ayuda
#   IZQUIERDA  -> riel de "sistemas": casco, ciencia, datos, cabina, filtros de CO2 y radio
#   DERECHA    -> las órdenes activas de hoy
#   ABAJO      -> la tripulación: retrato (cambia de expresión) + 3 barritas (salud, estrés, hambre)
#   CENTRO     -> la ventana al espacio y, encima, el panel de lo que está pasando
#
# Ciclo de cada día:
#   órdenes -> consumo del día -> aviso -> decisión 1 -> (minijuego) -> resultado
#           -> aviso -> decisión 2 -> (minijuego) -> resultado -> fin del día -> día siguiente
#
# Ayudas para el jugador:
#   - Recorrido guiado: la primera vez que se llega al día 1 se señala cada zona de la pantalla.
#   - Botón "?": abre la guía completa (Guia.gd) y detiene el reloj mientras está abierta.
#   - Los detalles (nombres, números exactos) salen al dejar el ratón quieto sobre cada cosa.
#
# Idioma: los textos fijos se traducen solos; los que llevan números pasan por Idioma.t() (ver Idioma.gd).

const Estilo = preload("res://srcipts/Estilo.gd")
const FondoEspacio = preload("res://srcipts/FondoEspacio.gd")
const Memos = preload("res://srcipts/Memos.gd")
const Minijuego = preload("res://srcipts/Minijuego.gd")
const Guia = preload("res://srcipts/Guia.gd")

const VITALES: Array = [["agua", "Agua"], ["comida", "Comida"], ["oxigeno", "Oxígeno"], ["electricidad", "Electricidad"], ["combustible", "Combustible"]]
const SISTEMAS: Array = [["integridad", "Casco"], ["ciencia", "Ciencia"], ["datos", "Datos"], ["temperatura", "Cabina"], ["filtros", "CO2"], ["enlace", "Radio"]]
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
# En las fichas de cambios, los 5 recursos vitales van solo con su icono; estos otros llevan nombre corto
const NOMBRE_FICHA: Dictionary = {"integridad": "Casco", "datos": "Datos", "ciencia": "Ciencia", "temperatura": "Cabina", "filtros": "Filtros"}
const RUTA_CABINA: String = "res://scenes/TileMaps/2x/cabina trasparente.png"
const ANCHO_PANEL: float = 1240.0
const SEGUNDOS_EXTRA: float = 10.0       # tiempo que se suma a cada decisión para que dé tiempo de leer
# En qué tipos de decisión aparece un minijuego después de elegir bien
const CON_MINIJUEGO: Array = ["nave", "recursos"]

# Recorrido guiado del primer día: [título, explicación, zona que se señala]
const PASOS_RECORRIDO: Array = [
	["RECURSOS VITALES", "Bajan cada día. Si el agua, el oxígeno, la electricidad o el combustible llegan a 0, la misión termina.", "recursos"],
	["SISTEMAS DE LA NAVE", "Casco, ciencia, datos, cabina, filtros de CO2 y radio. Deja el ratón encima de cada uno para ver qué hace.", "sistemas"],
	["TU TRIPULACIÓN", "Cada uno tiene salud, estrés y hambre. Con mucho estrés cometen errores; con poca salud dejan de ayudar.", "tripulacion"],
	["ÓRDENES DEL DÍA", "Cada mañana eliges cómo vivir hoy. En verde lo que ganas y en rojo lo que te cuesta. Después pulsa INICIAR EL DÍA.", "ordenes"],
	["¿DUDAS?", "Este botón abre la guía completa cuando quieras: explica qué significa cada cosa.", "ayuda"],
]
# El recorrido solo sale una vez por sesión de juego
static var recorrido_visto: bool = false

# --- Fondo ---
var fondo: Control
var luz_alerta: TextureRect

# --- Barra superior ---
var etq_dia: Label
var etq_tramo: Label
var medidores: Dictionary = {}        # clave -> {barra, valor, icono, caja}
var trayectoria: Control
var icono_alarma: TextureRect
var etq_alarma: Label
var boton_sonido: TextureButton
var boton_ayuda: TextureButton
var tex_tierra: Texture2D = Estilo.icono("tierra")      # guardadas aquí para que no se liberen de la memoria
var tex_luna: Texture2D = Estilo.icono("luna")
var tex_nave: Texture2D = Estilo.icono("orion_mini")

# --- Rieles laterales ---
var pastillas: Dictionary = {}        # clave -> {panel, valor}
var iconos_orden: Dictionary = {}     # racion/instrumentos/higiene -> TextureRect
var etq_avisos: Label

# --- Tripulación ---
var tarjetas: Dictionary = {}         # id -> {panel, retrato, insignia, aviso, salud, estres, hambre}
var _golpes: Dictionary = {}          # id -> segundos de temblor que le quedan al retrato

# --- Centro ---
var centro: VBoxContainer
var banner: PanelContainer
var etq_banner: Label
var espaciador: Control
var panel_config: PanelContainer
var etq_consejo: Label
var botones_orden: Dictionary = {}    # grupo -> {opcion -> Button}
var nombres_orden: Dictionary = {}    # grupo -> Label con el nombre de la opción elegida
var cajas_efecto: Dictionary = {}     # grupo -> VBoxContainer con lo bueno y lo malo de la opción elegida
var seleccion: Dictionary = {"racion": "completa", "instrumentos": "basicos", "higiene": "normal"}
var panel_central: PanelContainer
var cabecera: VBoxContainer
var scroll: ScrollContainer
var cuerpo: VBoxContainer
var pie: HBoxContainer
var barra_tiempo: ProgressBar
var etq_tiempo: Label
var icono_reloj: TextureRect
var minijuego: Control
var ultimo_minijuego: String = ""

# --- Capas encima de todo ---
var capa_flotante: Control
var anuncio: Control
var anuncio_banda: ColorRect
var anuncio_titulo: Label
var anuncio_sub: Label
var velo_dia: ColorRect
var etq_velo_dia: Label
var etq_velo_acto: Label
var pausa: Control
var guia: Control
var recorrido: Control
var recorrido_caja: PanelContainer
var recorrido_titulo: Label
var recorrido_texto: Label
var recorrido_boton: Button
var recorrido_paso: int = 0

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
var nota_reparacion: float = NAN       # resultado del último minijuego (NAN = no hubo)
var _mostrado: Dictionary = {}         # último valor dibujado de cada barra (para animar los cambios)
var _alarmas_antes: int = 0
var _en_alerta: bool = false
var _destello: float = 0.0
var _ultimo_tic: int = -1
var _ajuste_id: int = 0
var _paso_id: int = 0
var _dia_mapa: float = 1.0
var _t: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dia_mapa = float(GameManager.dia_actual)
	_construir_fondo()
	_construir_hud()
	_construir_capas()
	Sonido.zumbido(true)
	_actualizar_espacio(0.0)
	_mostrar_config()
	Estilo.aparecer(self, 0.6)
	if GameManager.dia_actual == 1 and not recorrido_visto:
		_abrir_recorrido()

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
	var medio = HBoxContainer.new()
	medio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	medio.add_theme_constant_override("separation", 10)
	medio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(medio)
	medio.add_child(_construir_riel_sistemas())
	medio.add_child(_construir_centro())
	medio.add_child(_construir_riel_ordenes())
	col.add_child(_construir_tripulacion())

func _subtitulo(texto: String, color: Color = Estilo.C_CIAN) -> Label:
	return Estilo.nuevo_texto(texto, 16, color)

func _boton_icono(icono: String, ayuda: String) -> TextureButton:
	var b = TextureButton.new()
	b.texture_normal = Estilo.icono(icono)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.custom_minimum_size = Vector2(40, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = ayuda
	b.focus_mode = Control.FOCUS_NONE
	Estilo.animar_hover(b, 1.12)
	return b

# --- Barra superior: día, recursos vitales, mapa del viaje, alarma y ayuda ---
func _construir_barra_superior() -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Estilo.C_BORDE, 8)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)

	var bloque_dia = VBoxContainer.new()
	bloque_dia.add_theme_constant_override("separation", -4)
	bloque_dia.custom_minimum_size = Vector2(196, 0)
	h.add_child(bloque_dia)
	etq_dia = Estilo.nuevo_texto("DÍA 1/14", 32, Estilo.C_AMARILLO, false)
	bloque_dia.add_child(etq_dia)
	etq_tramo = Estilo.nuevo_texto("", 16, Estilo.C_CIAN, false)
	bloque_dia.add_child(etq_tramo)

	for par in VITALES:
		h.add_child(_medidor(String(par[0]), String(par[1])))

	trayectoria = Control.new()
	trayectoria.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trayectoria.custom_minimum_size = Vector2(180, 48)
	trayectoria.tooltip_text = "Mapa del viaje: Tierra - Luna - Tierra"
	trayectoria.draw.connect(_dibujar_trayectoria)
	h.add_child(trayectoria)

	var caja_alarma = HBoxContainer.new()
	caja_alarma.add_theme_constant_override("separation", 4)
	caja_alarma.mouse_filter = Control.MOUSE_FILTER_STOP
	h.add_child(caja_alarma)
	icono_alarma = Estilo.nuevo_icono("alarma", 32)
	caja_alarma.add_child(icono_alarma)
	etq_alarma = Estilo.nuevo_texto("0", 24, Estilo.C_VERDE, false)
	etq_alarma.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	etq_alarma.custom_minimum_size = Vector2(22, 0)
	caja_alarma.add_child(etq_alarma)

	boton_ayuda = _boton_icono("ayuda", "Guía: qué significa cada cosa")
	boton_ayuda.pressed.connect(_abrir_guia)
	h.add_child(boton_ayuda)
	boton_sonido = _boton_icono("sonido_on", "Activar o silenciar el sonido")
	boton_sonido.pressed.connect(_on_sonido)
	h.add_child(boton_sonido)
	_pintar_sonido()

	var menu: Button = Estilo.nuevo_boton("MENÚ", 16, 84, 40)
	Estilo.estilo_holo(menu)
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.focus_mode = Control.FOCUS_NONE
	menu.pressed.connect(_alternar_pausa)
	h.add_child(menu)
	return p

# Medidor de un recurso vital: icono + número + barra (sin nombre: sale al dejar el ratón encima)
func _medidor(clave: String, nombre: String) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_STOP
	h.tooltip_text = Idioma.t("%s\nSi llega a 0, la misión termina. Por debajo de %d %% salta la alarma.") % [Idioma.t(nombre), int(GameManager.UMBRAL_ALARMA)]
	if clave == "comida":
		h.tooltip_text = Idioma.t("Comida\nSin comida, la tripulación pierde salud cada día. Por debajo de %d %% salta la alarma.") % int(GameManager.UMBRAL_ALARMA)
	var ic: TextureRect = Estilo.nuevo_icono(clave, 40)
	h.add_child(ic)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var valor: Label = Estilo.nuevo_texto("100", 24, Estilo.C_VERDE, false)
	v.add_child(valor)
	var barra: ProgressBar = Estilo.nueva_barra(Estilo.C_VERDE, 10)
	barra.custom_minimum_size = Vector2(92, 10)
	v.add_child(barra)
	medidores[clave] = {"barra": barra, "valor": valor, "icono": ic, "caja": h}
	return h

# Dónde va la navecita del mapa según el día (acepta decimales para que se mueva suave)
func _pos_mapa(dia: float, a: float, b: float, cy: float, x_luna: float) -> Vector2:
	if dia <= 4.0:
		return Vector2(lerpf(a, b, (dia - 1.0) / 4.0), cy)
	if dia < 5.0:
		return Vector2(lerpf(lerpf(a, b, 0.75), x_luna - 26.0, dia - 4.0), cy)
	if dia <= 9.0:
		var ang: float = _t * 0.9
		return Vector2(x_luna + cos(ang) * 26.0, cy + sin(ang) * 15.0)     # en órbita alrededor de la Luna
	return Vector2(lerpf(b, a, (dia - 9.0) / 5.0), cy)

func _dibujar_trayectoria() -> void:
	var c: Control = trayectoria
	var cy: float = c.size.y * 0.5
	var x0: float = 24.0
	var x1: float = c.size.x - 30.0
	var x: float = x0 + 30.0
	while x < x1 - 30.0:
		c.draw_rect(Rect2(x, cy - 1.0, 6.0, 2.0), Color(0.5, 0.66, 0.95, 0.75))
		x += 12.0
	c.draw_texture_rect(tex_tierra, Rect2(x0 - 20.0, cy - 20.0, 40.0, 40.0), false)
	c.draw_texture_rect(tex_luna, Rect2(x1 - 20.0, cy - 20.0, 40.0, 40.0), false)
	var pos: Vector2 = _pos_mapa(_dia_mapa, x0 + 40.0, x1 - 40.0, cy, x1)
	var hacia_derecha: bool = _dia_mapa < 5.0
	if _dia_mapa >= 5.0 and _dia_mapa <= 9.0:
		hacia_derecha = sin(_t * 0.9) < 0.0
	pos.y += sin(_t * 2.2) * 2.0
	if hacia_derecha:
		c.draw_texture_rect(tex_nave, Rect2(pos.x - 16.0, pos.y - 16.0, 32.0, 32.0), false)
	else:
		c.draw_texture_rect(tex_nave, Rect2(pos.x + 16.0, pos.y - 16.0, -32.0, 32.0), false)

# --- Riel izquierdo: sistemas de la nave (pastillas pequeñas) ---
func _construir_riel_sistemas() -> VBoxContainer:
	var v = VBoxContainer.new()
	v.custom_minimum_size = Vector2(140, 0)
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for par in SISTEMAS:
		v.add_child(_pastilla(String(par[0]), String(par[1])))
	return v

func _pastilla(clave: String, titulo: String) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Color(Estilo.C_BORDE, 0.8), 6)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(Estilo.nuevo_icono(clave, 32))
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(Estilo.nuevo_texto(titulo, 16, Estilo.C_TEXTO_SUAVE, false))
	var valor: Label = Estilo.nuevo_texto("", 16, Estilo.C_TEXTO, false)
	v.add_child(valor)
	pastillas[clave] = {"panel": p, "valor": valor}
	return p

# --- Riel derecho: órdenes activas y avisos ---
func _construir_riel_ordenes() -> VBoxContainer:
	var v = VBoxContainer.new()
	v.custom_minimum_size = Vector2(140, 0)
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL, Color(Estilo.C_BORDE, 0.8), 8)
	v.add_child(p)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(col)
	var t: Label = Estilo.nuevo_texto("ÓRDENES", 16, Estilo.C_CIAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	for grupo in ["racion", "instrumentos", "higiene"]:
		var ic: TextureRect = Estilo.nuevo_icono("racion_completa", 48)
		ic.mouse_filter = Control.MOUSE_FILTER_STOP
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		iconos_orden[grupo] = ic
	var caja_avisos: PanelContainer = Estilo.nuevo_panel(Color(0.20, 0.10, 0.03, 0.9), Estilo.C_NARANJA, 6)
	caja_avisos.visible = false
	v.add_child(caja_avisos)
	etq_avisos = Estilo.nuevo_texto("", 16, Estilo.C_NARANJA)
	etq_avisos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja_avisos.add_child(etq_avisos)
	return v

# --- Abajo: la tripulación ---
func _construir_tripulacion() -> HBoxContainer:
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in GameManager.TRIPULANTES:
		h.add_child(_tarjeta_tripulante(String(id)))
	return h

func _tarjeta_tripulante(id: String) -> PanelContainer:
	var color: Color = Estilo.ACENTO[id]
	var panel: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Color(color, 0.7), 6)
	panel.custom_minimum_size = Vector2(300, 0)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(h)
	var retrato: PanelContainer = Estilo.nuevo_retrato(id, "normal", 2)
	h.add_child(retrato)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var linea = HBoxContainer.new()
	linea.add_theme_constant_override("separation", 6)
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(linea)
	var nombre: Label = Estilo.nuevo_texto(String(GameManager.NOMBRES_TRIPULANTE[id]), 16, color, false)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linea.add_child(nombre)
	var aviso: TextureRect = Estilo.nuevo_icono("confianza", 16)
	aviso.modulate = Estilo.C_ROJO
	aviso.visible = false
	linea.add_child(aviso)
	var insignia: Label = Estilo.nuevo_texto("ESTABLE", 16, Estilo.C_VERDE, false)
	linea.add_child(insignia)
	var tarjeta: Dictionary = {"panel": panel, "retrato": retrato, "insignia": insignia, "aviso": aviso}
	for par in [["salud", Estilo.C_VERDE], ["estres", Estilo.C_VIOLETA], ["hambre", Estilo.C_NARANJA]]:
		var f = HBoxContainer.new()
		f.add_theme_constant_override("separation", 6)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(f)
		f.add_child(Estilo.nuevo_icono(String(par[0]), 16))
		var barra: ProgressBar = Estilo.nueva_barra(par[1], 10)
		f.add_child(barra)
		tarjeta[par[0]] = {"barra": barra}
	tarjetas[id] = tarjeta
	return panel

# --- Centro: título del día, órdenes y panel de lo que pasa ---
func _construir_centro() -> VBoxContainer:
	centro = VBoxContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 8)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	banner = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.80), Estilo.C_AMARILLO, 8)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(banner)
	etq_banner = Estilo.nuevo_texto("", 24, Estilo.C_AMARILLO, false)
	etq_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(etq_banner)

	espaciador = Control.new()
	espaciador.size_flags_vertical = Control.SIZE_EXPAND_FILL
	espaciador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(espaciador)

	panel_config = _construir_config()
	centro.add_child(panel_config)

	panel_central = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.95), Estilo.C_CIAN, 14)
	panel_central.custom_minimum_size = Vector2(ANCHO_PANEL, 0)
	panel_central.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_central.visible = false
	centro.add_child(panel_central)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel_central.add_child(v)
	cabecera = VBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 4)
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

# Órdenes del día: tres mosaicos con botones de solo icono y, debajo, lo bueno y lo malo de cada elección
func _construir_config() -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.93), Estilo.C_CIAN, 12)
	p.custom_minimum_size = Vector2(ANCHO_PANEL, 0)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	etq_consejo = Estilo.nuevo_texto("Elige las órdenes de hoy. En verde lo que ganas y en rojo lo que te cuesta.", 16, Estilo.C_TEXTO_SUAVE)
	etq_consejo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(etq_consejo)
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	v.add_child(fila)
	fila.add_child(_mosaico_orden("racion", "RACIÓN DE COMIDA", RACIONES, "racion_"))
	fila.add_child(_mosaico_orden("instrumentos", "INSTRUMENTOS", INSTRUMENTOS, "instrumentos_"))
	fila.add_child(_mosaico_orden("higiene", "HIGIENE", HIGIENES, "higiene_"))
	var iniciar: Button = Estilo.nuevo_boton("INICIAR EL DÍA", 32, 440, 60)
	iniciar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	iniciar.pressed.connect(_on_iniciar_dia)
	iniciar.name = "BotonIniciar"
	v.add_child(iniciar)
	return p

func _mosaico_orden(grupo: String, titulo: String, opciones: Array, prefijo_icono: String) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Color(Estilo.C_BORDE, 0.7), 8)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var t: Label = Estilo.nuevo_texto(titulo, 16, Estilo.C_CIAN)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var botones: Dictionary = {}
	var grupo_botones = ButtonGroup.new()
	for op in opciones:
		var b = Button.new()
		b.icon = Estilo.icono(prefijo_icono + String(op))
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.toggle_mode = true
		b.button_group = grupo_botones
		b.custom_minimum_size = Vector2(72, 56)
		b.focus_mode = Control.FOCUS_NONE
		Estilo.estilo_holo(b)
		Estilo.animar_hover(b, 1.08)
		b.pressed.connect(_on_orden.bind(grupo, String(op)))
		h.add_child(b)
		botones[op] = b
	botones_orden[grupo] = botones
	var nombre: Label = Estilo.nuevo_texto("", 16, Estilo.C_AMARILLO)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nombre)
	nombres_orden[grupo] = nombre
	var efectos = VBoxContainer.new()
	efectos.add_theme_constant_override("separation", 0)
	efectos.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(efectos)
	cajas_efecto[grupo] = efectos
	return p

# --- Capas: números flotantes, aviso de decisión, cambio de día, pausa, guía y recorrido ---
func _construir_capas() -> void:
	capa_flotante = Control.new()
	capa_flotante.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_flotante.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa_flotante)

	# Aviso que cruza la pantalla antes de cada decisión
	anuncio = Control.new()
	anuncio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anuncio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anuncio.visible = false
	add_child(anuncio)
	anuncio_banda = ColorRect.new()
	anuncio_banda.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	anuncio_banda.offset_top = -86
	anuncio_banda.offset_bottom = 86
	anuncio_banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anuncio.add_child(anuncio_banda)
	var va = VBoxContainer.new()
	va.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	va.alignment = BoxContainer.ALIGNMENT_CENTER
	va.add_theme_constant_override("separation", 0)
	va.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anuncio_banda.add_child(va)
	anuncio_titulo = Estilo.nuevo_texto("", 64, Color(1, 1, 1), false)
	anuncio_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	va.add_child(anuncio_titulo)
	anuncio_sub = Estilo.nuevo_texto("", 24, Color(1, 1, 1), false)
	anuncio_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	va.add_child(anuncio_sub)

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

	# Recorrido guiado (señala una zona de la pantalla y la explica)
	recorrido = Control.new()
	recorrido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	recorrido.mouse_filter = Control.MOUSE_FILTER_STOP
	recorrido.visible = false
	recorrido.draw.connect(_dibujar_recorrido)
	add_child(recorrido)
	recorrido_caja = Estilo.nuevo_panel(Color(0.03, 0.05, 0.11, 0.98), Estilo.C_AMARILLO, 16)
	recorrido_caja.custom_minimum_size = Vector2(780, 0)
	recorrido.add_child(recorrido_caja)
	var vr = VBoxContainer.new()
	vr.add_theme_constant_override("separation", 8)
	recorrido_caja.add_child(vr)
	recorrido_titulo = Estilo.nuevo_texto("", 32, Estilo.C_AMARILLO)
	vr.add_child(recorrido_titulo)
	recorrido_texto = Estilo.nuevo_texto("", 16, Estilo.C_TEXTO)
	vr.add_child(recorrido_texto)
	var fila_r = HBoxContainer.new()
	fila_r.add_theme_constant_override("separation", 12)
	fila_r.alignment = BoxContainer.ALIGNMENT_END
	vr.add_child(fila_r)
	var saltar: Button = Estilo.nuevo_boton("SALTAR", 16, 150, 48)
	Estilo.estilo_holo(saltar)
	saltar.pressed.connect(_cerrar_recorrido)
	fila_r.add_child(saltar)
	recorrido_boton = Estilo.nuevo_boton("SIGUIENTE", 24, 300, 48)
	recorrido_boton.pressed.connect(_siguiente_recorrido)
	fila_r.add_child(recorrido_boton)

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
	var ayuda: Button = Estilo.nuevo_boton("VER LA GUÍA", 24, 380, 56)
	ayuda.pressed.connect(func():
		pausa.visible = false
		_abrir_guia())
	v2.add_child(ayuda)
	var salir: Button = Estilo.nuevo_boton("SALIR AL MENÚ", 24, 380, 56)
	salir.pressed.connect(func(): Estilo.cambiar_escena(self, "res://scenes/main_menu.tscn"))
	v2.add_child(salir)

	guia = Guia.new()
	add_child(guia)

# ===============================================================
# AYUDAS: GUÍA Y RECORRIDO DEL PRIMER DÍA
# ===============================================================
func _abrir_guia() -> void:
	if fase == "transicion" or fase == "saliendo":
		return
	guia.abrir()

func _en_espera() -> bool:
	# El reloj y los avances automáticos se detienen mientras hay una ventana abierta encima
	return pausa.visible or guia.visible or recorrido.visible

func _abrir_recorrido() -> void:
	recorrido_paso = 0
	recorrido.visible = true
	recorrido.modulate.a = 0.0
	_pintar_recorrido()
	# Espera a que la pantalla termine de acomodarse antes de señalar
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(recorrido) and recorrido.visible:
		create_tween().tween_property(recorrido, "modulate:a", 1.0, 0.3).set_delay(0.5)

func _pintar_recorrido() -> void:
	var paso: Array = PASOS_RECORRIDO[recorrido_paso]
	recorrido_titulo.text = "%d/%d  %s" % [recorrido_paso + 1, PASOS_RECORRIDO.size(), Idioma.t(String(paso[0]))]
	recorrido_texto.text = String(paso[1])
	recorrido_boton.text = "¡A JUGAR!" if recorrido_paso == PASOS_RECORRIDO.size() - 1 else "SIGUIENTE"
	recorrido_boton.grab_focus.call_deferred()
	recorrido.queue_redraw()

func _siguiente_recorrido() -> void:
	if recorrido_paso >= PASOS_RECORRIDO.size() - 1:
		_cerrar_recorrido()
		return
	recorrido_paso += 1
	_pintar_recorrido()

func _cerrar_recorrido() -> void:
	recorrido_visto = true
	recorrido.visible = false
	var iniciar: Button = panel_config.find_child("BotonIniciar", true, false)
	if iniciar != null and fase == "config":
		iniciar.grab_focus.call_deferred()

func _union(nodos: Array) -> Rect2:
	var r: Rect2 = Rect2()
	var primero: bool = true
	for n in nodos:
		var rect: Rect2 = n.get_global_rect()
		r = rect if primero else r.merge(rect)
		primero = false
	return r

# Zona de la pantalla que se señala en cada paso del recorrido
func _rect_recorrido(clave: String) -> Rect2:
	match clave:
		"recursos":
			var cajas: Array = []
			for k in medidores:
				cajas.append(medidores[k]["caja"])
			return _union(cajas).grow(8.0)
		"sistemas":
			var paneles: Array = []
			for k in pastillas:
				paneles.append(pastillas[k]["panel"])
			return _union(paneles).grow(6.0)
		"tripulacion":
			var todas: Array = []
			for k in tarjetas:
				todas.append(tarjetas[k]["panel"])
			return _union(todas).grow(6.0)
		"ordenes":
			return panel_config.get_global_rect().grow(4.0)
		"ayuda":
			return boton_ayuda.get_global_rect().grow(10.0)
	return Rect2()

func _dibujar_recorrido() -> void:
	var zona: Rect2 = _rect_recorrido(String(PASOS_RECORRIDO[recorrido_paso][2]))
	var total: Vector2 = recorrido.size
	var sombra: Color = Color(0.0, 0.0, 0.02, 0.80)
	# Cuatro franjas oscuras alrededor de la zona señalada (la zona queda a la vista)
	recorrido.draw_rect(Rect2(0, 0, total.x, zona.position.y), sombra)
	recorrido.draw_rect(Rect2(0, zona.end.y, total.x, total.y - zona.end.y), sombra)
	recorrido.draw_rect(Rect2(0, zona.position.y, zona.position.x, zona.size.y), sombra)
	recorrido.draw_rect(Rect2(zona.end.x, zona.position.y, total.x - zona.end.x, zona.size.y), sombra)
	var pulso: float = 3.0 + 2.0 * (0.5 + 0.5 * sin(_t * 5.0))
	recorrido.draw_rect(zona.grow(pulso), Estilo.C_AMARILLO, false, 4.0)
	# La caja de texto se pone donde no tape la zona: debajo si la zona está arriba, y al revés
	var alto: float = recorrido_caja.size.y
	var y: float = zona.end.y + 26.0
	if zona.get_center().y > total.y * 0.5:
		y = zona.position.y - alto - 26.0
	recorrido_caja.position = Vector2((total.x - recorrido_caja.size.x) * 0.5, clampf(y, 20.0, total.y - alto - 20.0))

# ===============================================================
# TEXTOS DEL VIAJE
# ===============================================================
func _acto(dia: int) -> String:
	if dia <= 4:
		return "ACTO I"
	if dia <= 10:
		return "ACTO II"
	return "ACTO III"

func _tramo(dia: int) -> String:
	if dia <= 4:
		return "Rumbo a la Luna"
	if dia <= 9:
		return "En órbita lunar"
	if dia <= 13:
		return "Regreso a la Tierra"
	return "Reentrada"

# La Tierra y la Luna se ven más grandes o más pequeñas según en qué parte del viaje estamos
func _actualizar_espacio(duracion: float) -> void:
	var dia: int = GameManager.dia_actual
	if dia <= 4:
		var f: float = float(dia - 1) / 3.0
		fondo.colocar("tierra", Vector2(0.40, 0.36), lerpf(3.5, 1.0, f), duracion)
		fondo.colocar("luna", Vector2(0.62, 0.30), lerpf(0.5, 2.0, f), duracion)
	elif dia <= 9:
		fondo.colocar("luna", Vector2(0.50, 0.40), 3.5, duracion)
		fondo.colocar("tierra", Vector2(0.67, 0.24), 0.5, duracion)
	else:
		var f2: float = float(dia - 10) / 4.0
		fondo.colocar("luna", Vector2(0.38, 0.28), lerpf(2.0, 0.5, f2), duracion)
		fondo.colocar("tierra", Vector2(0.58, 0.38), lerpf(1.0, 4.0, f2), duracion)

# ===============================================================
# FASE 1: ÓRDENES DEL DÍA
# ===============================================================
func _mostrar_config() -> void:
	fase = "config"
	reloj_activo = false
	var dia: int = GameManager.dia_actual
	var hito: Dictionary = Eventos.hito_del_dia(dia)
	banner.visible = not hito.is_empty()
	if not hito.is_empty():
		etq_banner.text = Idioma.t("HOY: ") + Idioma.t(String(hito["tema"])).to_upper()

	seleccion["racion"] = GameManager.racion
	seleccion["instrumentos"] = GameManager.instrumentos
	seleccion["higiene"] = "suspendida" if GameManager.higiene_suspendida else "normal"
	for grupo in botones_orden:
		for op in botones_orden[grupo]:
			var b: Button = botones_orden[grupo][op]
			b.set_pressed_no_signal(String(op) == String(seleccion[grupo]))
			if grupo == "instrumentos":
				b.disabled = GameManager.instrumentos_bloqueados
			var lineas: Array = [Idioma.t(String(NOMBRE_ORDEN[op]))]
			for e in _efectos_orden(String(grupo), String(op)):
				lineas.append(String(e[1]))
			b.tooltip_text = "\n".join(lineas)
		_pintar_orden(String(grupo))
	etq_consejo.visible = (dia == 1)

	espaciador.visible = true
	panel_config.visible = true
	panel_central.visible = false
	Sonido.musica("musica_contrarreloj" if _acto(dia) == "ACTO III" else "musica_tension")
	actualizar_hud(false)
	var iniciar: Button = panel_config.find_child("BotonIniciar", true, false)
	if iniciar != null:
		iniciar.grab_focus.call_deferred()

func _on_orden(grupo: String, opcion: String) -> void:
	seleccion[grupo] = opcion
	_pintar_orden(grupo)

# Lo bueno y lo malo de cada orden, con los números de GameManager.
# Devuelve una lista de [icono, texto, tipo]; tipo es "bueno" (verde), "malo" (rojo) o "neutro" (gris).
func _efectos_orden(grupo: String, op: String) -> Array:
	var lista: Array = []
	match grupo:
		"racion":
			var mult: float = float(GameManager.COMIDA_RACION[op])
			var hambre: float = float(GameManager.HAMBRE_RACION[op])
			if mult >= 1.0:
				lista.append(["comida", Idioma.t("Gasto normal de comida"), "neutro"])
			else:
				lista.append(["comida", Idioma.t("Ahorras %d %% de comida") % roundi((1.0 - mult) * 100.0), "bueno"])
			if hambre > 0.0:
				lista.append(["hambre", Idioma.t("El hambre sube %s al día") % Idioma.num(hambre), "malo"])
			else:
				lista.append(["hambre", Idioma.t("El hambre baja %s al día") % Idioma.num(absf(hambre)), "bueno"])
		"instrumentos":
			if GameManager.instrumentos_bloqueados:
				lista.append(["ciencia", Idioma.t("Carga soltada: no funcionan"), "malo"])
			elif op == "apagados":
				lista.append(["ciencia", Idioma.t("La ciencia no avanza"), "malo"])
				lista.append(["electricidad", Idioma.t("No gastan electricidad"), "bueno"])
			else:
				lista.append(["ciencia", Idioma.t("La ciencia sube %s al día") % Idioma.num(float(GameManager.CIENCIA_DIA[op])), "bueno"])
				lista.append(["electricidad", Idioma.t("Electricidad baja %s al día") % Idioma.num(float(GameManager.ELEC_INSTRUMENTOS[op])), "malo"])
				lista.append(["datos", Idioma.t("Los datos suben %s al día") % Idioma.num(float(GameManager.DATOS_DIA[op])), "malo"])
		"higiene":
			if op == "normal":
				lista.append(["agua", Idioma.t("Gasto normal de agua"), "neutro"])
				lista.append(["estres", Idioma.t("Sin estrés extra"), "bueno"])
			else:
				lista.append(["agua", Idioma.t("Ahorras 15 % de agua"), "bueno"])
				lista.append(["estres", Idioma.t("El estrés sube %s al día") % Idioma.num(GameManager.ESTRES_AISLAMIENTO_HIGIENE), "malo"])
	return lista

func _pintar_orden(grupo: String) -> void:
	var op: String = String(seleccion[grupo])
	nombres_orden[grupo].text = String(NOMBRE_ORDEN[op])
	var caja: VBoxContainer = cajas_efecto[grupo]
	_limpiar(caja)
	for e in _efectos_orden(grupo, op):
		var tipo: String = String(e[2])
		var color: Color = Estilo.C_TEXTO_SUAVE
		if tipo == "bueno":
			color = Estilo.C_VERDE
		elif tipo == "malo":
			color = Estilo.C_ROJO
		var fila = HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		caja.add_child(fila)
		# Marca verde = te conviene; marca roja = te cuesta
		var marca: TextureRect = Estilo.nuevo_icono("resultado_bueno" if tipo == "bueno" else "resultado_malo", 20)
		marca.modulate.a = 0.0 if tipo == "neutro" else 1.0
		fila.add_child(marca)
		fila.add_child(Estilo.nuevo_icono(String(e[0]), 24))
		var l: Label = Estilo.nuevo_texto(String(e[1]), 16, color, false)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(l)

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
# FASE 2: CONSUMO DEL DÍA (automático) Y NOVEDADES
# ===============================================================
func _mostrar_registro(lineas: Array, antes: Dictionary, despues: Dictionary) -> void:
	fase = "registro"
	_paso_id += 1
	_abrir_panel(Estilo.C_CIAN)
	var titulo: Label = Estilo.nuevo_texto(Idioma.t("CONSUMO DEL DÍA %d") % GameManager.dia_actual, 24, Estilo.C_AMARILLO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cabecera.add_child(titulo)
	_agregar_fichas(cuerpo, _fichas_cambios(antes, despues))
	var novedades: int = 0
	for linea in lineas:
		var texto: String = String(linea)
		if texto.begins_with("Consumo diario"):
			continue
		novedades += 1
		var icono: String = "alarma"
		var color: Color = Estilo.C_AMARILLO
		if texto.begins_with("Estrés"):
			icono = "estres"
			color = Estilo.C_VIOLETA
		elif texto.contains("ha muerto"):
			icono = "sin_senal"
			color = Estilo.C_ROJO
		cuerpo.add_child(_aviso(Idioma.dinamico(texto), color, icono))
	if GameManager.hay_final_inmediato():
		siguiente = "final"
		_boton_pie("VER EL DESENLACE")
	else:
		siguiente = "decision1"
		_boton_pie("CONTINUAR")
		if novedades == 0:
			# Sin novedades: sigue solo después de un momento (menos clics)
			var mi_paso: int = _paso_id
			var espera: Tween = create_tween()
			espera.tween_interval(2.4)
			espera.tween_callback(func():
				if fase == "registro" and mi_paso == _paso_id and not _en_espera():
					_on_continuar())
	_cerrar_panel()

# ===============================================================
# FASE 3: DECISIONES
# ===============================================================
# Elige la decisión y muestra un aviso grande antes de abrirla
func _anunciar_decision() -> void:
	decision_actual = GameManager.elegir_decision(numero_decision)
	if decision_actual.is_empty():
		_cerrar_dia()
		return
	var d: Dictionary = decision_actual
	if d.has("al_iniciar"):
		GameManager.aplicar_efecto(d["al_iniciar"])
		actualizar_hud(true)
	fase = "aviso"
	reloj_activo = false
	panel_central.visible = false
	banner.visible = false
	var categoria: String = String(d["categoria"])
	var gravedad: int = int(d["gravedad"])
	var color: Color = _color_decision(d)
	var titulo: String = "DECISIÓN DE RECURSOS"
	if categoria == "nave":
		titulo = "¡EMERGENCIA!"
		Sonido.efecto("alarma" if gravedad >= 2 else "aviso")
		_destello = 1.0 if gravedad >= 2 else 0.4
	elif categoria == "hito":
		titulo = "MOMENTO CLAVE"
		Sonido.efecto("estatica")
	else:
		Sonido.efecto("aviso")
	anuncio_titulo.text = titulo
	anuncio_sub.text = Idioma.t(String(d["tema"])).to_upper()
	anuncio_banda.color = Color(color.darkened(0.6), 0.94)
	anuncio_titulo.add_theme_color_override("font_color", color.lerp(Color(1, 1, 1), 0.35))
	anuncio.visible = true
	anuncio.modulate.a = 0.0
	anuncio_banda.pivot_offset = Vector2(size.x * 0.5, 86.0)
	anuncio_banda.scale = Vector2(1.0, 0.1)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(anuncio, "modulate:a", 1.0, 0.12)
	tw.tween_property(anuncio_banda, "scale:y", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.75)
	tw.chain().tween_property(anuncio, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(func():
		anuncio.visible = false
		if fase == "aviso":
			_mostrar_decision())

func _color_decision(d: Dictionary) -> Color:
	var categoria: String = String(d["categoria"])
	if categoria == "nave":
		return Estilo.C_ROJO if int(d["gravedad"]) >= 3 else Estilo.C_NARANJA
	if categoria == "hito":
		return Estilo.C_AMARILLO
	return Estilo.C_VERDE

func _mostrar_decision() -> void:
	var d: Dictionary = decision_actual
	fase = "decision"
	reloj_activo = false
	nota_reparacion = NAN
	var categoria: String = String(d["categoria"])
	var color: Color = _color_decision(d)
	_abrir_panel(color)

	# --- Cabecera: tipo, gravedad, tema y número de decisión ---
	var tipo: String = "RECURSOS"
	if categoria == "nave":
		tipo = "EMERGENCIA"
	elif categoria == "hito":
		tipo = "MOMENTO CLAVE"
	var linea = HBoxContainer.new()
	linea.add_theme_constant_override("separation", 8)
	cabecera.add_child(linea)
	var etiqueta: PanelContainer = Estilo.nuevo_panel(Color(color, 0.18), color, 4)
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	etiqueta.add_child(Estilo.nuevo_texto(tipo, 16, color, false))
	linea.add_child(etiqueta)
	if categoria == "nave":
		for i in int(d["gravedad"]):
			linea.add_child(Estilo.nuevo_icono("alarma", 24))
	var tema: Label = Estilo.nuevo_texto(Idioma.t(String(d["tema"])).to_upper(), 24, Estilo.C_TEXTO)
	tema.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linea.add_child(tema)
	var cuenta: Label = Estilo.nuevo_texto(Idioma.t("%d DE 2") % numero_decision, 16, Estilo.C_TEXTO_SUAVE, false)
	cuenta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linea.add_child(cuenta)

	# --- Temporizador (el estrés de Elena puede recortarlo) ---
	tiempo_total = maxf(5.0, float(d["tiempo_s"]) + SEGUNDOS_EXTRA - GameManager.penal_tiempo)
	GameManager.penal_tiempo = 0.0
	tiempo_restante = tiempo_total
	_ultimo_tic = -1
	var fila_tiempo = HBoxContainer.new()
	fila_tiempo.add_theme_constant_override("separation", 8)
	cabecera.add_child(fila_tiempo)
	icono_reloj = Estilo.nuevo_icono("reloj", 32)
	fila_tiempo.add_child(icono_reloj)
	if GameManager.modo_sin_temporizador:
		fila_tiempo.add_child(Estilo.nuevo_texto("MODO APRENDIZAJE: sin límite de tiempo", 16, Estilo.C_VERDE))
		barra_tiempo = null
		etq_tiempo = null
	else:
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
		quien.add_theme_constant_override("separation", 0)
		escena.add_child(quien)
		var retrato: PanelContainer = Estilo.nuevo_retrato(resp, Estilo.expresion(float(t["salud"]), float(t["estres"])), 3)
		quien.add_child(retrato)
		Estilo.saltar(retrato, 0.05, 0.8)
		var nombre: Label = Estilo.nuevo_texto(String(GameManager.NOMBRES_TRIPULANTE[resp]), 16, Estilo.ACENTO[resp], false)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quien.add_child(nombre)
	var globo: PanelContainer = Estilo.nuevo_panel(Estilo.C_PANEL_CLARO, Color(color, 0.6), 14)
	globo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	escena.add_child(globo)
	var vg = VBoxContainer.new()
	vg.add_theme_constant_override("separation", 8)
	vg.alignment = BoxContainer.ALIGNMENT_CENTER
	globo.add_child(vg)
	vg.add_child(Estilo.nuevo_texto(String(d["texto"]), 16, Estilo.C_TEXTO))
	var aborto: bool = GameManager.aborto_disponible()
	if d.get("ruta_aborto", false) and aborto:
		vg.add_child(_aviso("Reservas en rojo: puedes soltar la carga científica.", Estilo.C_ROJO, "alarma"))

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
		var tarjeta: PanelContainer = _tarjeta_opcion(String(letras[pos]), opcion, int(orden_opciones[pos]), color)
		cuerpo.add_child(tarjeta)
		Estilo.saltar(tarjeta, 0.12 + 0.07 * float(pos), 0.92)

	_resaltar_responsable(resp)
	actualizar_hud(true)
	await _cerrar_panel()
	if fase == "decision":
		reloj_activo = not GameManager.modo_sin_temporizador

func _tarjeta_opcion(letra: String, opcion: Dictionary, indice: int, color: Color) -> PanelContainer:
	var normal: StyleBoxFlat = Estilo.caja(Color(0.06, 0.09, 0.18, 0.96), Color(Estilo.C_BORDE, 0.9), 2, 8)
	var encima: StyleBoxFlat = Estilo.caja(Color(0.12, 0.18, 0.32, 1.0), Estilo.C_AMARILLO, 3, 7)
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", normal)
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var marca: PanelContainer = Estilo.nuevo_panel(Color(color, 0.2), color, 2)
	marca.custom_minimum_size = Vector2(44, 44)
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
	v.add_child(Estilo.nuevo_texto(String(opcion["texto"]), 16, Estilo.C_TEXTO))
	var detalle: String = String(opcion.get("descripcion", ""))
	if detalle != "":
		v.add_child(Estilo.nuevo_texto(detalle, 16, Estilo.C_TEXTO_SUAVE))
	p.mouse_entered.connect(func(): p.add_theme_stylebox_override("panel", encima))
	p.mouse_exited.connect(func(): p.add_theme_stylebox_override("panel", normal))
	p.gui_input.connect(func(evento: InputEvent):
		if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			_on_opcion(indice))
	return p

func _on_opcion(indice: int) -> void:
	if fase != "decision" or _en_espera():
		return
	Sonido.clic()
	var opcion: Dictionary = decision_actual["opciones"][indice]
	# Un procedimiento válido se ejecuta a mano: minijuego (las trampas y los momentos clave no tienen)
	if CON_MINIJUEGO.has(String(decision_actual["categoria"])) and not opcion.get("trampa", false):
		_iniciar_minijuego(indice)
	else:
		_resolver(indice, false)

# ===============================================================
# FASE 3b: MINIJUEGO (TAREA MANUAL)
# ===============================================================
func _iniciar_minijuego(indice: int) -> void:
	fase = "minijuego"
	reloj_activo = false
	var tipo: String = Minijuego.elegir(String(decision_actual["tema"]), ultimo_minijuego)
	ultimo_minijuego = tipo
	var opcion: Dictionary = decision_actual["opciones"][indice]
	_abrir_panel(Estilo.C_AMARILLO)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	cabecera.add_child(h)
	h.add_child(Estilo.nuevo_icono("herramienta", 48))
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(Estilo.nuevo_texto(Idioma.t("TAREA MANUAL: ") + Idioma.t(String(Minijuego.TITULOS[tipo])), 32, Estilo.C_AMARILLO))
	v.add_child(Estilo.nuevo_texto(String(Minijuego.INSTRUCCIONES[tipo]), 16, Estilo.C_TEXTO))
	minijuego = Minijuego.new()
	cuerpo.add_child(minijuego)
	minijuego.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	minijuego.terminado.connect(_on_minijuego_terminado.bind(indice))
	var nota: Label = Estilo.nuevo_texto(Idioma.t("Procedimiento: ") + Idioma.t(String(opcion["texto"])), 16, Estilo.C_TEXTO_SUAVE)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.add_child(nota)
	await _cerrar_panel()
	if fase == "minijuego" and is_instance_valid(minijuego):
		minijuego.iniciar(tipo, 2.0 if GameManager.modo_sin_temporizador else 1.0)

func _on_minijuego_terminado(habilidad: float, indice: int) -> void:
	if fase != "minijuego":
		return
	nota_reparacion = habilidad
	GameManager.habilidad_manual = habilidad
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
	var sello: TextureRect = Estilo.nuevo_icono("resultado_" + tier, 64)
	h.add_child(sello)
	Estilo.saltar(sello, 0.15, 0.3)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", -2)
	h.add_child(v)
	v.add_child(Estilo.nuevo_texto(Idioma.t("RESULTADO: ") + Idioma.t(String(TIER_TEXTO[tier])), 32, color))
	v.add_child(Estilo.nuevo_texto(String(opcion["texto"]), 16, Estilo.C_TEXTO))

	if String(res["nota"]) != "":
		cuerpo.add_child(_aviso(Idioma.dinamico(String(res["nota"])), Estilo.C_NARANJA, "reloj"))
	if not is_nan(nota_reparacion):
		var texto_rep: String = "Tu tarea manual salió mal y empeoró el resultado."
		var color_rep: Color = Estilo.C_ROJO
		if nota_reparacion >= 0.6:
			texto_rep = "Tu tarea manual salió perfecta y ayudó al resultado."
			color_rep = Estilo.C_VERDE
		elif nota_reparacion >= 0.0:
			texto_rep = "Tu tarea manual salió aceptable."
			color_rep = Estilo.C_AMARILLO
		cuerpo.add_child(_aviso(texto_rep, color_rep, "herramienta"))
	for m in res["muertes"]:
		cuerpo.add_child(_aviso(Idioma.dinamico(String(m)), Estilo.C_ROJO, "sin_senal"))

	var fichas: Array = _fichas_cambios(antes, despues)
	if fichas.is_empty():
		var nada: Label = Estilo.nuevo_texto("Las barras no cambiaron.", 16, Estilo.C_TEXTO_SUAVE)
		nada.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cuerpo.add_child(nada)
	else:
		_agregar_fichas(cuerpo, fichas)

	var por_que: String = String(opcion.get("por_que", ""))
	if por_que != "":
		var explicacion: Label = Estilo.nuevo_texto(por_que, 16, Estilo.C_TEXTO_SUAVE)
		explicacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cuerpo.add_child(explicacion)

	# Memo NASA y análisis: plegados para no llenar la pantalla (el memo de los momentos clave sale abierto)
	var memo: PanelContainer = _tarjeta_memo(Memos.para_decision(decision_actual), String(opcion.get("fuente", "")))
	memo.visible = (String(decision_actual["categoria"]) == "hito")
	var analisis = VBoxContainer.new()
	analisis.add_theme_constant_override("separation", 4)
	analisis.visible = false
	if not res["factores"].is_empty():
		analisis.add_child(_subtitulo("FACTORES QUE PESARON"))
		for f in res["factores"]:
			analisis.add_child(Estilo.nuevo_texto("- " + Idioma.dinamico(String(f)), 16, Estilo.C_TEXTO_SUAVE))
	if not res["alternativas"].is_empty():
		analisis.add_child(_subtitulo("QUÉ HABRÍA PASADO CON LAS OTRAS OPCIONES"))
		for a in res["alternativas"]:
			analisis.add_child(_linea_alternativa(String(a)))
	var extras = HBoxContainer.new()
	extras.add_theme_constant_override("separation", 8)
	extras.alignment = BoxContainer.ALIGNMENT_CENTER
	cuerpo.add_child(extras)
	extras.add_child(_boton_plegable("MEMO NASA", "memo", memo, Estilo.C_VERDE))
	if analisis.get_child_count() > 0:
		extras.add_child(_boton_plegable("ANÁLISIS", "ciencia", analisis, Estilo.C_CIAN))
	cuerpo.add_child(memo)
	cuerpo.add_child(analisis)

	if GameManager.hay_final_inmediato():
		siguiente = "final"
		_boton_pie("VER EL DESENLACE")
	elif numero_decision == 1:
		siguiente = "decision2"
		_boton_pie("CONTINUAR")
	else:
		siguiente = "cerrar"
		_boton_pie("TERMINAR EL DÍA")
	_cerrar_panel()

# Botón pequeño que abre y cierra un bloque de información extra
func _boton_plegable(texto: String, icono: String, bloque: Control, color: Color) -> Button:
	var b: Button = Estilo.nuevo_boton(texto, 16, 210, 40)
	Estilo.estilo_holo(b, color)
	b.icon = Estilo.icono(icono)
	b.add_theme_constant_override("icon_max_width", 24)
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.set_pressed_no_signal(bloque.visible)
	b.toggled.connect(func(abierto: bool):
		bloque.visible = abierto
		_ajustar_panel(false))
	return b

# Una alternativa llega como "texto: TIER (efectos)". Se pinta con el color de su nivel.
func _linea_alternativa(texto: String) -> Label:
	var color: Color = Estilo.C_TEXTO_SUAVE
	var mostrado: String = texto
	for tier in TIER_TEXTO:
		var marca: String = ": %s (" % TIER_TEXTO[tier]
		var pos: int = texto.find(marca)
		if pos == -1:
			continue
		color = Estilo.COLOR_RESULTADO[tier].lerp(Estilo.C_TEXTO, 0.35)
		if Idioma.es_ingles():
			mostrado = "%s: %s (%s" % [Idioma.t(texto.substr(0, pos)), Idioma.t(String(TIER_TEXTO[tier])), Idioma.dinamico(texto.substr(pos + marca.length()))]
	return Estilo.nuevo_texto("- " + mostrado, 16, color)

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
	var titulo: String = Idioma.t(String(memo["titulo"])).to_upper()
	if texto != "":
		v.add_child(Estilo.nuevo_texto(Idioma.t("MEMO NASA: ") + titulo, 16, Estilo.C_VERDE))
		v.add_child(Estilo.nuevo_texto(texto, 16, Estilo.C_TEXTO))
	else:
		v.add_child(Estilo.nuevo_texto(Idioma.t("PARA SABER MÁS: ") + titulo, 16, Estilo.C_VERDE))
	var url: String = fuente_opcion if fuente_opcion != "" else String(memo["url"])
	var nombre: String = Idioma.t("Fuente NASA de esta decisión") if fuente_opcion != "" else String(memo["fuente"])
	var enlace: Button = Estilo.nuevo_boton(Idioma.t("Abrir: ") + nombre, 16, 0, 36)
	Estilo.estilo_holo(enlace, Estilo.C_VERDE)
	enlace.focus_mode = Control.FOCUS_NONE
	enlace.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	enlace.tooltip_text = url
	enlace.pressed.connect(OS.shell_open.bind(url))
	v.add_child(enlace)
	return p

func _on_continuar() -> void:
	_paso_id += 1
	match siguiente:
		"decision1":
			numero_decision = 1
			_anunciar_decision()
		"decision2":
			numero_decision = 2
			_anunciar_decision()
		"cerrar":
			_cerrar_dia()
		"dia":
			_siguiente_dia()
		"final":
			_ir_al_final()

# ===============================================================
# FASE 5: FIN DEL DÍA
# ===============================================================
func _cerrar_dia() -> void:
	fase = "resumen"
	reloj_activo = false
	var ahora: Dictionary = GameManager.instantanea()
	_abrir_panel(Estilo.C_CIAN)
	var titulo: Label = Estilo.nuevo_texto(Idioma.t("FIN DEL DÍA %d") % GameManager.dia_actual, 32, Estilo.C_AMARILLO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cabecera.add_child(titulo)
	var fichas: Array = _fichas_cambios(snap_dia, ahora)
	if fichas.is_empty():
		cuerpo.add_child(Estilo.nuevo_texto("Sin cambios.", 16, Estilo.C_TEXTO_SUAVE))
	else:
		_agregar_fichas(cuerpo, fichas)
	for a in GameManager.alarmas():
		cuerpo.add_child(_aviso(Idioma.t("ALARMA: ") + Idioma.dinamico(String(a)), Estilo.C_ROJO, "alarma"))
	GameManager.cerrar_dia()
	if GameManager.hay_final_inmediato() or GameManager.dia_actual >= GameManager.DIAS_TOTALES:
		siguiente = "final"
		_boton_pie("VER EL DESENLACE")
	else:
		siguiente = "dia"
		_boton_pie(Idioma.t("IR AL DÍA %d") % (GameManager.dia_actual + 1))
	actualizar_hud(true)
	_cerrar_panel()

func _siguiente_dia() -> void:
	if fase == "transicion":
		return
	fase = "transicion"
	var nuevo: int = GameManager.dia_actual + 1
	etq_velo_dia.text = Idioma.t("DÍA %d") % nuevo
	etq_velo_acto.text = "%s  ·  %s" % [Idioma.t(_acto(nuevo)), Idioma.t(_tramo(nuevo))]
	velo_dia.modulate.a = 0.0
	velo_dia.visible = true
	var tw: Tween = create_tween()
	tw.tween_property(velo_dia, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func():
		GameManager.dia_actual = nuevo
		_mostrar_config())
	tw.tween_interval(0.8)
	tw.tween_callback(func(): _actualizar_espacio(3.0))      # los planetas se mueven a la vista del jugador
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
	minijuego = null
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
		# Entra creciendo un poco desde el centro
		await get_tree().process_frame
		if mi_id != _ajuste_id:
			return
		panel_central.pivot_offset = panel_central.size * 0.5
		panel_central.scale = Vector2(0.96, 0.96)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(panel_central, "modulate:a", 1.0, 0.18)
		tw.tween_property(panel_central, "scale", Vector2(1, 1), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished

func _boton_pie(texto: String) -> void:
	var b: Button = Estilo.nuevo_boton(texto, 24, 420, 52)
	b.pressed.connect(_on_continuar)
	pie.add_child(b)
	b.grab_focus.call_deferred()

func _aviso(texto: String, color: Color, icono: String) -> PanelContainer:
	var p: PanelContainer = Estilo.nuevo_panel(Color(color, 0.12), Color(color, 0.8), 6)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, 32))
	var l: Label = Estilo.nuevo_texto(texto, 16, color.lerp(Color(1, 1, 1), 0.45))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	return p

func _agregar_fichas(padre: Control, fichas: Array) -> void:
	var flujo = HFlowContainer.new()
	flujo.add_theme_constant_override("h_separation", 8)
	flujo.add_theme_constant_override("v_separation", 8)
	flujo.alignment = FlowContainer.ALIGNMENT_CENTER
	padre.add_child(flujo)
	var n: int = 0
	for f in fichas:
		flujo.add_child(f)
		Estilo.saltar(f, 0.10 + 0.05 * float(n), 0.7)
		n += 1

# Ficha de color: icono + flecha (sube o baja) + cuánto cambió.
# Verde = te conviene, rojo = te perjudica. El nombre solo aparece cuando el icono no basta.
func _ficha(icono: String, texto: String, cambio: float, unidad: String, color: Color, ayuda: String, color_texto: Color = Estilo.C_TEXTO) -> PanelContainer:
	var valor: String = GameManager.signo(cambio) + unidad
	var p: PanelContainer = Estilo.nuevo_panel(Color(color, 0.14), Color(color, 0.85), 6)
	p.tooltip_text = "%s: %s %s" % [ayuda, Idioma.t("sube") if cambio > 0.0 else Idioma.t("baja"), valor.trim_prefix("+").trim_prefix("-")]
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(Estilo.nuevo_icono(icono, 32))
	if texto != "":
		var l: Label = Estilo.nuevo_texto(texto, 16, color_texto, false)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	var flecha: TextureRect = Estilo.nuevo_icono("flecha_sube" if cambio > 0.0 else "flecha_baja", 20)
	flecha.modulate = color
	h.add_child(flecha)
	var v: Label = Estilo.nuevo_texto(valor, 24, color, false)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
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
		var nombre: String = Idioma.t(String(GameManager.ETIQUETAS.get(clave, clave)).replace(" (°C)", ""))
		lista.append(_ficha(clave, String(NOMBRE_FICHA.get(clave, "")), d, String(UNIDAD.get(clave, " %")), color, nombre))
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
		var nombre_stat: String = Idioma.t(String(ETQ_STAT[stat]))
		if iguales and deltas.size() >= 2 and deltas.size() == GameManager.vivos().size():
			var bueno: bool = (float(valores[0]) > 0.0) == sube_es_bueno
			lista.append(_ficha(stat, "Todos", float(valores[0]), "", Estilo.C_VERDE if bueno else Estilo.C_ROJO,
				Idioma.t("%s de todos") % nombre_stat))
		else:
			for id in deltas:
				var bueno2: bool = (float(deltas[id]) > 0.0) == sube_es_bueno
				lista.append(_ficha(stat, String(GameManager.NOMBRES_TRIPULANTE[id]), float(deltas[id]), "",
					Estilo.C_VERDE if bueno2 else Estilo.C_ROJO, Idioma.t("%s de %s") % [nombre_stat, GameManager.NOMBRES_TRIPULANTE[id]],
					Estilo.ACENTO[id].lerp(Color(1, 1, 1), 0.4)))
	return lista

# ===============================================================
# HUD: medidores, pastillas, retratos, alarmas
# ===============================================================
func actualizar_hud(animar: bool = true) -> void:
	var dia: int = GameManager.dia_actual
	etq_dia.text = Idioma.t("DÍA %d/%d") % [dia, GameManager.DIAS_TOTALES]
	etq_tramo.text = _tramo(dia)

	# --- Recursos vitales ---
	for par in VITALES:
		var clave: String = String(par[0])
		var v: float = GameManager.valor_estado(clave)
		var m: Dictionary = medidores[clave]
		var color: Color = Estilo.color_nivel(v)
		Estilo.color_barra(m["barra"], color)
		m["valor"].text = str(roundi(v))
		m["valor"].add_theme_color_override("font_color", color)
		_poner_barra(clave, m["barra"], v, animar, true, true)

	# --- Sistemas ---
	_pintar_pastilla("integridad", "%d %%" % roundi(GameManager.integridad), Estilo.color_nivel(GameManager.integridad),
		Idioma.t("Integridad del casco: %d %%\nBajo 60 %% se escapa oxígeno. Con %d %% o menos, el escudo térmico no resiste la reentrada.") % [roundi(GameManager.integridad), int(GameManager.INTEGRIDAD_REENTRADA)])
	var meta: int = int(GameManager.CIENCIA_FINAL_BUENO)
	var color_ciencia: Color = Estilo.C_VERDE if GameManager.ciencia >= float(meta) else Estilo.C_VIOLETA
	var nota_tope: String = ""
	if GameManager.ciencia_max < float(meta):
		nota_tope = Idioma.t("\nOjo: con tu plan no se puede llegar a la meta.")
	_pintar_pastilla("ciencia", "%d / %d" % [roundi(GameManager.ciencia), meta], color_ciencia,
		Idioma.t("Progreso científico: %d %%\nSube con los instrumentos encendidos. Meta del final bueno: %d %%. Tope de tu plan: %d %%.") % [roundi(GameManager.ciencia), meta, roundi(GameManager.ciencia_max)] + nota_tope)
	_pintar_pastilla("datos", "%d %%" % roundi(GameManager.datos), Estilo.C_ROJO if GameManager.datos > 85.0 else Estilo.C_TEXTO,
		Idioma.t("Memoria de datos: %d %%\nLos instrumentos la llenan. Se vacía sola si hay radio. Si llega a 100 %%, los instrumentos se apagan.") % roundi(GameManager.datos))
	var temp: float = GameManager.temperatura
	var temp_ok: bool = temp >= 18.0 and temp <= 28.0
	_pintar_pastilla("temperatura", "%d °C" % roundi(temp), Estilo.C_TEXTO if temp_ok else Estilo.C_ROJO,
		Idioma.t("Temperatura de la cabina: %d °C\nZona segura: 18 a 28 °C. Fuera de ella sube el estrés y baja la salud.") % roundi(temp))
	_pintar_pastilla("filtros", "x %d" % GameManager.filtros, Estilo.C_TEXTO if GameManager.filtros > 0 else Estilo.C_ROJO,
		Idioma.t("Cartuchos de CO2 de reserva: %d\nSin cartuchos, el aire empeora y baja la salud de todos.") % GameManager.filtros)
	if GameManager.enlace_dias > 0:
		_pintar_pastilla("enlace", Idioma.t("NO (%d d)") % GameManager.enlace_dias, Estilo.C_ROJO,
			Idioma.t("Enlace con la Tierra PERDIDO: %d día(s) más.\nSin enlace, la memoria de datos no se vacía.") % GameManager.enlace_dias)
	else:
		_pintar_pastilla("enlace", "OK", Estilo.C_VERDE, Idioma.t("Enlace con la Tierra activo: la memoria de datos se vacía cada día."))

	# --- Órdenes activas y avisos ---
	var higiene: String = "suspendida" if GameManager.higiene_suspendida else "normal"
	iconos_orden["racion"].texture = Estilo.icono("racion_" + GameManager.racion)
	iconos_orden["racion"].tooltip_text = Idioma.t("Ración: ") + Idioma.t(String(NOMBRE_ORDEN[GameManager.racion]))
	iconos_orden["instrumentos"].texture = Estilo.icono("instrumentos_" + GameManager.instrumentos)
	iconos_orden["instrumentos"].tooltip_text = Idioma.t("Instrumentos: ") + Idioma.t(String(NOMBRE_ORDEN[GameManager.instrumentos]))
	iconos_orden["higiene"].texture = Estilo.icono("higiene_" + higiene)
	iconos_orden["higiene"].tooltip_text = Idioma.t("Higiene: ") + Idioma.t(String(NOMBRE_ORDEN[higiene]))
	var avisos: Array = []
	if GameManager.modulo_dias > 0:
		avisos.append(Idioma.t("Módulo bloqueado %d d") % GameManager.modulo_dias)
	if GameManager.reparaciones_dias > 0:
		avisos.append(Idioma.t("Reparación lenta %d d") % GameManager.reparaciones_dias)
	if GameManager.mision_abortada:
		avisos.append(Idioma.t("Carga soltada"))
	etq_avisos.text = "\n".join(avisos)
	etq_avisos.get_parent().visible = not avisos.is_empty()

	# --- Alarmas ---
	var alarmas: Array = GameManager.alarmas()
	_en_alerta = not alarmas.is_empty()
	var caja_alarma: Control = icono_alarma.get_parent()
	etq_alarma.text = str(alarmas.size())
	if _en_alerta:
		etq_alarma.add_theme_color_override("font_color", Estilo.C_ROJO)
		var lista: Array = []
		for a in alarmas:
			lista.append(Idioma.dinamico(String(a)))
		caja_alarma.tooltip_text = Idioma.t("ALARMAS:") + "\n" + "\n".join(lista)
		if alarmas.size() > _alarmas_antes and animar:
			Sonido.efecto("alarma")
	else:
		etq_alarma.add_theme_color_override("font_color", Estilo.C_VERDE)
		caja_alarma.tooltip_text = Idioma.t("Sin alarmas. Una alarma salta cuando un recurso vital baja de %d %%.") % int(GameManager.UMBRAL_ALARMA)
	_alarmas_antes = alarmas.size()

	# --- Tripulación ---
	for id in GameManager.TRIPULANTES:
		var t: Dictionary = GameManager.tripulantes[id]
		var c: Dictionary = tarjetas[id]
		var salud: float = float(t["salud"])
		var estres: float = float(t["estres"])
		var confianza: float = float(t["confianza"])
		Estilo.cambiar_retrato(c["retrato"], Estilo.expresion(salud, estres))
		var insignia: Array = _insignia(salud, estres)
		c["insignia"].text = String(insignia[0])
		c["insignia"].add_theme_color_override("font_color", insignia[1])
		c["aviso"].visible = confianza < 40.0 and salud > 0.0
		c["panel"].tooltip_text = Idioma.t("%s  ·  %s\nSalud %d   Estrés %d   Hambre %d\nConfianza en tu mando: %d%s") % [
			t["nombre"], Idioma.t(String(t["rol"])), roundi(salud), roundi(estres), roundi(float(t["hambre"])), roundi(confianza),
			Idioma.t("  (¡puede ignorar tus órdenes!)") if confianza < 30.0 else ""]
		var salud_antes: float = float(_mostrado.get("salud_" + String(id), salud))
		if animar and salud < salud_antes - 0.5:
			_golpes[id] = 0.45       # el retrato tiembla y la tarjeta se pone roja un instante
			var tw: Tween = create_tween()
			tw.tween_property(c["panel"], "self_modulate", Color(1.0, 0.45, 0.45), 0.08)
			tw.tween_property(c["panel"], "self_modulate", Color(1, 1, 1), 0.4)
		for stat in ["salud", "estres", "hambre"]:
			var valor: float = float(t[stat])
			if stat == "salud":
				Estilo.color_barra(c[stat]["barra"], Estilo.color_nivel(valor))
			_poner_barra(stat + "_" + String(id), c[stat]["barra"], valor, animar, stat == "salud", false)
		c["panel"].modulate = Color(0.55, 0.55, 0.62) if salud <= 0.0 else Color(1, 1, 1)

func _pintar_pastilla(clave: String, texto: String, color: Color, ayuda: String) -> void:
	var p: Dictionary = pastillas[clave]
	p["valor"].text = texto
	p["valor"].add_theme_color_override("font_color", color)
	p["panel"].tooltip_text = ayuda

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
func _poner_barra(clave: String, barra: ProgressBar, valor: float, animar: bool, sube_es_bueno: bool, hacia_abajo: bool) -> void:
	var antes: float = float(_mostrado.get(clave, valor))
	_mostrado[clave] = valor
	var d: float = valor - antes
	if not animar or absf(d) < 0.5:
		barra.value = valor
		return
	var tw: Tween = create_tween()
	tw.tween_property(barra, "value", valor, 0.6).set_trans(Tween.TRANS_SINE)
	var bueno: bool = (d > 0.0) == sube_es_bueno
	var donde: Vector2 = barra.global_position + Vector2(barra.size.x * 0.5 - 14.0, 10.0 if hacia_abajo else -30.0)
	_flotar(GameManager.signo(d), Estilo.C_VERDE if bueno else Estilo.C_ROJO, donde, 28.0 if hacia_abajo else -28.0)

func _flotar(texto: String, color: Color, donde: Vector2, recorrido_px: float) -> void:
	var l: Label = Estilo.con_borde(Estilo.nuevo_texto(texto, 24, color, false), 6)
	l.position = donde
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_flotante.add_child(l)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", donde.y + recorrido_px, 1.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.9)
	tw.chain().tween_callback(l.queue_free)

# Marca con borde amarillo la tarjeta del tripulante que responde por la decisión actual
func _resaltar_responsable(id: String) -> void:
	for otro in tarjetas:
		var color: Color = Estilo.ACENTO[otro]
		var es: bool = (String(otro) == id)
		tarjetas[otro]["panel"].add_theme_stylebox_override("panel",
			Estilo.caja(Color(0.12, 0.17, 0.30, 0.97) if es else Estilo.C_PANEL_CLARO, Estilo.C_AMARILLO if es else Color(color, 0.7), 3 if es else 2, 5 if es else 6))

# ===============================================================
# CADA CUADRO: reloj, luces, mapa y retratos que flotan
# ===============================================================
func _process(delta: float) -> void:
	_t += delta
	_dia_mapa = move_toward(_dia_mapa, float(GameManager.dia_actual), delta * 0.7)
	trayectoria.queue_redraw()
	if recorrido.visible:
		recorrido_caja.size = recorrido_caja.get_combined_minimum_size()
		recorrido.queue_redraw()

	# Luz roja: late mientras haya alarmas y da un destello cuando llega una emergencia
	_destello = maxf(0.0, _destello - delta * 0.8)
	var objetivo: float = _destello * (0.6 + 0.4 * sin(_t * 14.0))
	if _en_alerta:
		objetivo = maxf(objetivo, 0.35 + 0.25 * sin(_t * 4.0))
	luz_alerta.modulate.a = lerpf(luz_alerta.modulate.a, objetivo, minf(1.0, delta * 8.0))
	icono_alarma.modulate.a = (0.55 + 0.45 * sin(_t * 8.0)) if _en_alerta else 0.3

	# Los recursos en zona de alarma parpadean
	for par in VITALES:
		var clave: String = String(par[0])
		var bajo: bool = GameManager.valor_estado(clave) < GameManager.UMBRAL_ALARMA
		medidores[clave]["icono"].modulate.a = (0.7 + 0.3 * sin(_t * 9.0)) if bajo else 1.0

	# Los astronautas flotan; si acaban de recibir daño, tiemblan
	var n: int = 0
	for id in tarjetas:
		var marco: PanelContainer = tarjetas[id]["retrato"]
		Estilo.flotar_retrato(marco, _t, float(n) * 1.7)
		if _golpes.has(id):
			_golpes[id] = float(_golpes[id]) - delta
			var img: TextureRect = marco.get_meta("imagen")
			img.position.x += roundf(sin(_t * 70.0) * 6.0 * clampf(float(_golpes[id]) / 0.45, 0.0, 1.0))
			if float(_golpes[id]) <= 0.0:
				_golpes.erase(id)
		n += 1

	if fase != "decision" or not reloj_activo or _en_espera():
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
		if is_instance_valid(icono_reloj):
			icono_reloj.pivot_offset = icono_reloj.size * 0.5
			icono_reloj.rotation = sin(_t * 30.0) * 0.2 if fraccion < 0.25 else 0.0
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
		if recorrido.visible:
			_cerrar_recorrido()
		else:
			_alternar_pausa()
		return
	if tecla.keycode == KEY_F1:
		_abrir_guia()
		return
	if fase != "decision" or _en_espera():
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
	if fase == "transicion" or fase == "saliendo" or guia.visible:
		return
	pausa.visible = not pausa.visible

func _pintar_sonido() -> void:
	boton_sonido.texture_normal = Estilo.icono("sonido_off" if Sonido.silenciado else "sonido_on")

func _on_sonido() -> void:
	Sonido.alternar_silencio()
	_pintar_sonido()
