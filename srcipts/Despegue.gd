extends Control
# Escena del DESPEGUE: aparece entre la Fase 0 (tienda) y el Día 1 de la misión.
# Cuenta regresiva 3-2-1, ignición, humo y el cohete subiendo. Dura unos 9 segundos.
# Se puede saltar con cualquier tecla o con un clic.
#
# El cohete, la torre y el fondo son imágenes (assets/nave y assets/finales);
# el fuego y el humo se dibujan con código en _draw.

const Estilo = preload("res://srcipts/Estilo.gd")

const T_CUENTA: float = 1.0        # segundo en que empieza la cuenta regresiva
const T_IGNICION: float = 4.0      # se encienden los motores
const T_SUBIDA: float = 4.9        # el cohete se suelta de la plataforma
const T_FIN: float = 9.2           # pasa a la misión
const ESCALA: float = 4.0

var cohete: Sprite2D
var torre: Sprite2D
var capa_fuego: Control
var etq_cuenta: Label
var etq_radio: Label
var etq_lugar: Label
var mundo: Control                # todo lo que tiembla con el rugido de los motores
var humo: Array = []              # partículas: {pos, vel, vida, tam}
var _t: float = 0.0
var _ultimo_numero: int = 0
var _saliendo: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rng.seed = 351

	mundo = Control.new()
	mundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mundo)

	var fondo = TextureRect.new()
	fondo.texture = load("res://assets/finales/despegue.png")
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.offset_left = -20
	fondo.offset_right = 20
	fondo.offset_top = -20
	fondo.offset_bottom = 20
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mundo.add_child(fondo)

	torre = Sprite2D.new()
	torre.texture = load("res://assets/nave/torre.png")
	torre.scale = Vector2(ESCALA, ESCALA)
	mundo.add_child(torre)

	capa_fuego = Control.new()
	capa_fuego.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_fuego.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fuego.draw.connect(_dibujar_fuego)
	mundo.add_child(capa_fuego)

	cohete = Sprite2D.new()
	cohete.texture = load("res://assets/nave/cohete.png")
	cohete.scale = Vector2(ESCALA, ESCALA)
	mundo.add_child(cohete)

	etq_lugar = Estilo.con_borde(Estilo.nuevo_texto("CABO CAÑAVERAL  ·  MISIÓN ARTEMIS-MYG", 24, Estilo.C_CIAN, false))
	etq_lugar.position = Vector2(60, 40)
	add_child(etq_lugar)

	etq_cuenta = Estilo.con_borde(Estilo.nuevo_texto("", 96, Estilo.C_AMARILLO, false), 12)
	add_child(etq_cuenta)

	etq_radio = Estilo.con_borde(Estilo.nuevo_texto("", 24, Estilo.C_TEXTO, false))
	etq_radio.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	etq_radio.position = Vector2(60, -90)
	add_child(etq_radio)

	var saltar: Label = Estilo.con_borde(Estilo.nuevo_texto("Pulsa una tecla para saltar", 16, Estilo.C_TEXTO_SUAVE, false))
	saltar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	saltar.position = Vector2(-420, -50)
	add_child(saltar)

	Sonido.musica("")
	Sonido.zumbido(false)
	_colocar()
	Estilo.aparecer(self, 0.8)

func _base() -> Vector2:
	# Punto de la plataforma donde se apoya el cohete (centro de la pantalla, sobre el suelo)
	return Vector2(size.x * 0.5, size.y * 0.845)

func _colocar() -> void:
	var base: Vector2 = _base()
	torre.position = base + Vector2(-112.0, -340.0)
	var subida: float = 0.0
	if _t > T_SUBIDA:
		var k: float = _t - T_SUBIDA
		subida = 0.5 * 150.0 * k * k        # acelera cada vez más
	cohete.position = base + Vector2(0.0, -296.0 - subida)
	etq_cuenta.position = Vector2(110.0, size.y * 0.30)

func _process(delta: float) -> void:
	_t += delta
	_colocar()

	# Cuenta regresiva
	var numero: int = 0
	if _t >= T_CUENTA and _t < T_IGNICION:
		numero = 3 - int(_t - T_CUENTA)
	if numero != _ultimo_numero and numero > 0:
		_ultimo_numero = numero
		etq_cuenta.text = str(numero)
		Estilo.saltar(etq_cuenta, 0.0, 1.6)
		Sonido.efecto("tic", 4.0)
	if _t >= T_IGNICION and _ultimo_numero != -1:
		_ultimo_numero = -1
		etq_cuenta.text = "¡IGNICIÓN!"
		etq_cuenta.add_theme_color_override("font_color", Estilo.C_NARANJA)
		Estilo.saltar(etq_cuenta, 0.0, 1.4)
		Sonido.efecto("despegue", 6.0)
	if _t >= T_SUBIDA + 0.6 and etq_cuenta.text == "¡IGNICIÓN!":
		etq_cuenta.text = "¡DESPEGUE!"
		etq_cuenta.add_theme_color_override("font_color", Estilo.C_VERDE)
		Estilo.saltar(etq_cuenta, 0.0, 1.4)

	# Radio de Houston
	if _t < T_CUENTA:
		etq_radio.text = "Houston: «Orión, tienen luz verde para el lanzamiento.»"
	elif _t < T_IGNICION:
		etq_radio.text = "Elena: «Tripulación lista. Sistemas en verde.»"
	elif _t < T_SUBIDA + 1.5:
		etq_radio.text = "Houston: «Tenemos ignición... ¡y despegue de la Orión!»"
	else:
		etq_radio.text = "Leo: «¡Nos vamos a la Luna!»"

	# Humo y temblor
	if _t >= T_IGNICION:
		var boca: Vector2 = cohete.position + Vector2(0.0, 296.0)
		for i in 3:
			var lado: float = _rng.randf_range(-1.0, 1.0)
			humo.append({
				"pos": Vector2(boca.x + lado * 30.0, minf(boca.y + 40.0, _base().y + 30.0)),
				"vel": Vector2(lado * _rng.randf_range(120.0, 380.0), _rng.randf_range(-60.0, 10.0)),
				"vida": 1.0, "tam": _rng.randf_range(18.0, 34.0)})
		var fuerza: float = clampf(1.0 - (_t - T_IGNICION) / 5.0, 0.0, 1.0) * 7.0
		mundo.position = Vector2(_rng.randf_range(-fuerza, fuerza), _rng.randf_range(-fuerza, fuerza))
	for p in humo:
		p["pos"] = p["pos"] + p["vel"] * delta
		p["vel"] = p["vel"] * (1.0 - 0.9 * delta)
		p["vida"] = float(p["vida"]) - delta * 0.45
		p["tam"] = float(p["tam"]) + 26.0 * delta
	humo = humo.filter(func(p): return float(p["vida"]) > 0.0)
	capa_fuego.queue_redraw()

	if _t >= T_FIN:
		_terminar()

func _dibujar_fuego() -> void:
	var c: Control = capa_fuego
	# Humo: cuadrados que crecen y se apagan (aspecto pixel-art)
	for p in humo:
		var vida: float = float(p["vida"])
		var tam: float = roundf(float(p["tam"]) / 4.0) * 4.0
		var gris: float = 0.55 + 0.45 * vida
		c.draw_rect(Rect2(Vector2(p["pos"]) - Vector2(tam, tam) * 0.5, Vector2(tam, tam)), Color(gris, gris, gris * 0.98, vida * 0.85))
	if _t < T_IGNICION:
		return
	# Llamas debajo de los motores
	var boca: Vector2 = cohete.position + Vector2(0.0, 290.0)
	var potencia: float = clampf((_t - T_IGNICION) / 0.6, 0.2, 1.0)
	for dx in [-56.0, 0.0, 56.0]:
		var largo: float = (150.0 if dx == 0.0 else 190.0) * potencia * (0.85 + 0.15 * sin(_t * 47.0 + dx))
		var ancho: float = 26.0 if dx == 0.0 else 18.0
		var punta: Vector2 = boca + Vector2(dx, largo)
		c.draw_colored_polygon(PackedVector2Array([boca + Vector2(dx - ancho, 0), boca + Vector2(dx + ancho, 0), punta]), Color(1.0, 0.55, 0.15))
		c.draw_colored_polygon(PackedVector2Array([boca + Vector2(dx - ancho * 0.6, 0), boca + Vector2(dx + ancho * 0.6, 0), boca + Vector2(dx, largo * 0.7)]), Color(1.0, 0.86, 0.35))
		c.draw_colored_polygon(PackedVector2Array([boca + Vector2(dx - ancho * 0.3, 0), boca + Vector2(dx + ancho * 0.3, 0), boca + Vector2(dx, largo * 0.4)]), Color(1.0, 0.98, 0.85))

func _unhandled_input(evento: InputEvent) -> void:
	if _t < 0.6:
		return
	var tecla: bool = evento is InputEventKey and evento.pressed and not evento.echo
	var clic: bool = evento is InputEventMouseButton and evento.pressed
	if tecla or clic:
		_terminar()

func _terminar() -> void:
	if _saliendo:
		return
	_saliendo = true
	Estilo.cambiar_escena(self, "res://scenes/mission.tscn", 0.6)
