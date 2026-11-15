extends Control
# Minijuegos de REPARACIÓN MANUAL.
# Aparecen en las emergencias de la nave cuando eliges un procedimiento válido (no una trampa):
# tú mismo haces la reparación y qué tan bien te salga cambia el resultado de la decisión.
#
# Hay 4 minijuegos (todo se dibuja con código en _draw, no usan imágenes):
#   "sellar"     -> haz clic en las fugas para taparlas con parches
#   "alinear"    -> detén la aguja dentro de la zona verde (3 intentos)
#   "secuencia"  -> repite el orden en que se encienden los interruptores
#   "valvula"    -> mantén pulsado para sostener la presión dentro de la zona verde
#
# Cómo usarlo:
#     var mini = Minijuego.new()
#     padre.add_child(mini)
#     mini.terminado.connect(func(habilidad): ...)   # habilidad va de -1 (falló) a 1 (perfecto)
#     mini.iniciar("sellar", 1.0)                    # el segundo número multiplica el tiempo disponible

signal terminado(habilidad: float)

const Estilo = preload("res://srcipts/Estilo.gd")

const TITULOS: Dictionary = {
	"sellar": "SELLA LAS FUGAS",
	"alinear": "ALINEA EL SISTEMA",
	"secuencia": "REINICIA EN ORDEN",
	"valvula": "ESTABILIZA LA PRESIÓN",
}
const INSTRUCCIONES: Dictionary = {
	"sellar": "Haz clic sobre cada fuga para taparla con un parche.",
	"alinear": "Pulsa ESPACIO o haz clic cuando la aguja pase por la zona verde. Tienes 3 intentos.",
	"secuencia": "Mira en qué orden se encienden los interruptores y repítelo con clics.",
	"valvula": "Mantén pulsado el ratón (o ESPACIO) para subir la presión y sostenla en la zona verde.",
}
const DURACION: Dictionary = {"sellar": 7.0, "alinear": 12.0, "secuencia": 9.0, "valvula": 8.0}
const COLORES_INTERRUPTOR: Array = [Color(0.35, 0.80, 1.0), Color(1.0, 0.85, 0.30), Color(0.40, 0.90, 0.50), Color(0.72, 0.52, 1.0), Color(1.0, 0.60, 0.25)]

var tipo: String = "sellar"
var duracion: float = 7.0
var tiempo: float = 0.0
var activo: bool = false
var acabado: bool = false
var habilidad: float = 0.0
var _t: float = 0.0
var _pulsado: bool = false
var _rng := RandomNumberGenerator.new()
var _fuente: Font

# sellar
var fugas: Array = []
# alinear
var ronda: int = 0
var aciertos: int = 0
var marcas: Array = []
var aguja: float = 0.0
var sentido: float = 1.0
var zona_centro: float = 0.5
var congelado: float = 0.0
# secuencia
var orden: Array = []
var mostrando: bool = true
var indice: int = 0
var errores: int = 0
var destello: Dictionary = {}
# valvula
var presion: float = 0.2
var en_zona: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(1000, 330)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fuente = Estilo.fuente(24)
	_rng.randomize()

# Qué minijuego le toca a una emergencia, según su tema
static func tipo_para(tema: String) -> String:
	var t: String = tema.to_lower()
	for clave in ["despresurizaci", "integridad", "emergencias", "refrigerante"]:
		if t.contains(clave):
			return "sellar"
	for clave in ["eléctric", "energía", "computadora", "instrumentaci", "monitoreo", "incendio"]:
		if t.contains(clave):
			return "secuencia"
	for clave in ["térmic", "co₂", "co2", "aire", "agua", "higiene", "humedad"]:
		if t.contains(clave):
			return "valvula"
	return "alinear"

func iniciar(tipo_juego: String, factor_tiempo: float = 1.0) -> void:
	tipo = tipo_juego if DURACION.has(tipo_juego) else "alinear"
	duracion = float(DURACION[tipo]) * factor_tiempo
	tiempo = duracion
	acabado = false
	match tipo:
		"sellar":
			_preparar_fugas()
		"alinear":
			ronda = 0
			aciertos = 0
			marcas = []
			_nueva_zona()
		"secuencia":
			orden = []
			for i in 4:
				orden.append(_rng.randi_range(0, 4))
			mostrando = true
			indice = 0
			errores = 0
			_t = 0.0
		"valvula":
			presion = 0.2
			en_zona = 0.0
	activo = true
	queue_redraw()

# ---------------------------------------------------------------
# Lógica por cuadro
# ---------------------------------------------------------------
func _process(delta: float) -> void:
	_t += delta
	if not activo:
		queue_redraw()
		return
	var corre_reloj: bool = true
	match tipo:
		"alinear":
			if congelado > 0.0:
				congelado -= delta
				corre_reloj = false
			else:
				var velocidad: float = [0.55, 0.75, 0.95][mini(ronda, 2)]
				aguja += sentido * velocidad * delta
				if aguja >= 1.0:
					aguja = 1.0
					sentido = -1.0
				elif aguja <= 0.0:
					aguja = 0.0
					sentido = 1.0
		"secuencia":
			if mostrando:
				corre_reloj = false
				if _t > 0.5 + orden.size() * 0.55:
					mostrando = false
			for k in destello.keys():
				destello[k]["t"] = float(destello[k]["t"]) - delta
				if float(destello[k]["t"]) <= 0.0:
					destello.erase(k)
		"valvula":
			presion = clampf(presion + (0.75 if _pulsado else -0.45) * delta, 0.0, 1.0)
			if absf(presion - _centro_valvula()) <= 0.10:
				en_zona += delta
				if en_zona >= 3.0:
					_terminar(1.0)
					return
	if corre_reloj:
		tiempo -= delta
		if tiempo <= 0.0:
			_por_tiempo()
	queue_redraw()

func _centro_valvula() -> float:
	return 0.60 + 0.13 * sin(_t * 0.9)

func _por_tiempo() -> void:
	match tipo:
		"sellar":
			_terminar(_nota_fugas())
		"alinear":
			_terminar(_nota_alinear())
		"secuencia":
			errores += orden.size() - indice
			_terminar(clampf(1.0 - 0.6 * float(errores), -1.0, 1.0))
		"valvula":
			_terminar(clampf(en_zona / 3.0, 0.0, 1.0) * 2.0 - 1.0)

func _terminar(valor: float) -> void:
	if acabado:
		return
	acabado = true
	activo = false
	habilidad = clampf(valor, -1.0, 1.0)
	Sonido.efecto("exito" if habilidad >= 0.6 else ("aviso" if habilidad >= 0.0 else "fallo"), -4.0)
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	terminado.emit(habilidad)

# Para las pruebas automáticas: termina ya con una nota dada
func forzar(valor: float) -> void:
	_terminar(valor)

# ---------------------------------------------------------------
# Entradas
# ---------------------------------------------------------------
func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_pulsado = evento.pressed
		if evento.pressed and activo:
			_clic(evento.position)

func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
		_pulsado = false
	elif evento is InputEventKey and evento.keycode == KEY_SPACE and not evento.echo and is_visible_in_tree():
		_pulsado = evento.pressed
		if evento.pressed and activo and tipo == "alinear":
			_intento_alinear()
		get_viewport().set_input_as_handled()

func _clic(pos: Vector2) -> void:
	match tipo:
		"sellar":
			for f in fugas:
				if not f["sellada"] and pos.distance_to(f["pos"]) <= 46.0:
					f["sellada"] = true
					Sonido.efecto("clic")
					break
			var faltan: int = 0
			for f in fugas:
				if not f["sellada"]:
					faltan += 1
			if faltan == 0:
				_terminar(1.0)
		"alinear":
			_intento_alinear()
		"secuencia":
			if mostrando:
				return
			for i in 5:
				if _rect_interruptor(i).has_point(pos):
					if i == int(orden[indice]):
						destello[i] = {"t": 0.3, "bien": true}
						indice += 1
						Sonido.efecto("clic")
						if indice >= orden.size():
							_terminar(clampf(1.0 - 0.6 * float(errores), -1.0, 1.0))
					else:
						destello[i] = {"t": 0.3, "bien": false}
						errores += 1
						Sonido.efecto("tic")
					break

# ---------------------------------------------------------------
# Sellar fugas
# ---------------------------------------------------------------
func _preparar_fugas() -> void:
	fugas = []
	var zona: Rect2 = _zona_juego().grow(-70.0)
	var intentos: int = 0
	while fugas.size() < 6 and intentos < 400:
		intentos += 1
		var p: Vector2 = Vector2(_rng.randf_range(zona.position.x, zona.end.x), _rng.randf_range(zona.position.y, zona.end.y))
		var libre: bool = true
		for f in fugas:
			if p.distance_to(f["pos"]) < 120.0:
				libre = false
		if libre:
			fugas.append({"pos": p, "sellada": false, "angulo": _rng.randf_range(-2.4, -0.7), "giro": _rng.randf_range(-0.3, 0.3)})

func _nota_fugas() -> float:
	var selladas: int = 0
	for f in fugas:
		if f["sellada"]:
			selladas += 1
	return clampf((float(selladas) / float(maxi(fugas.size(), 1)) - 0.5) * 2.0, -1.0, 1.0)

# ---------------------------------------------------------------
# Alinear
# ---------------------------------------------------------------
func _ancho_zona() -> float:
	return [0.20, 0.15, 0.11][mini(ronda, 2)]

func _nueva_zona() -> void:
	zona_centro = _rng.randf_range(0.18, 0.82)
	aguja = 0.0 if zona_centro > 0.5 else 1.0
	sentido = 1.0 if aguja <= 0.0 else -1.0

func _intento_alinear() -> void:
	if congelado > 0.0 or not activo:
		return
	var bien: bool = absf(aguja - zona_centro) <= _ancho_zona() * 0.5
	marcas.append(bien)
	if bien:
		aciertos += 1
		Sonido.efecto("clic")
	else:
		Sonido.efecto("tic")
	ronda += 1
	if ronda >= 3:
		_terminar(_nota_alinear())
	else:
		congelado = 0.45
		_nueva_zona.call_deferred()

func _nota_alinear() -> float:
	return [-1.0, -0.34, 0.34, 1.0][clampi(aciertos, 0, 3)]

# ---------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------
func _zona_juego() -> Rect2:
	return Rect2(0.0, 22.0, size.x, size.y - 22.0)

func _rect_interruptor(i: int) -> Rect2:
	var lado: float = 120.0
	var hueco: float = (size.x - 5.0 * lado) / 6.0
	return Rect2(hueco + float(i) * (lado + hueco), size.y * 0.5 - 40.0, lado, lado)

func _texto(pos: Vector2, texto: String, color: Color, tam: int = 24, ancho: float = -1.0, centrado: bool = false) -> void:
	if _fuente == null:
		return
	draw_string(_fuente, pos, texto, HORIZONTAL_ALIGNMENT_CENTER if centrado else HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, color)

func _draw() -> void:
	var zona: Rect2 = _zona_juego()
	# Fondo del panel de trabajo
	draw_rect(zona, Color(0.13, 0.17, 0.27) if tipo == "sellar" else Color(0.06, 0.08, 0.14))
	draw_rect(zona, Estilo.C_BORDE, false, 2.0)
	# Barra de tiempo
	var fraccion: float = clampf(tiempo / maxf(duracion, 0.01), 0.0, 1.0)
	var color_tiempo: Color = Estilo.C_VERDE
	if fraccion < 0.25:
		color_tiempo = Estilo.C_ROJO
	elif fraccion < 0.5:
		color_tiempo = Estilo.C_AMARILLO
	draw_rect(Rect2(0, 0, size.x, 14), Color(0.01, 0.02, 0.05))
	draw_rect(Rect2(0, 0, size.x * fraccion, 14), color_tiempo)

	match tipo:
		"sellar":
			_dibujar_sellar(zona)
		"alinear":
			_dibujar_alinear(zona)
		"secuencia":
			_dibujar_secuencia(zona)
		"valvula":
			_dibujar_valvula(zona)

	if acabado:
		draw_rect(zona, Color(0.02, 0.03, 0.08, 0.82))
		var texto: String = "REPARACIÓN FALLIDA"
		var color: Color = Estilo.C_ROJO
		if habilidad >= 0.6:
			texto = "REPARACIÓN PERFECTA"
			color = Estilo.C_VERDE
		elif habilidad >= 0.0:
			texto = "REPARACIÓN ACEPTABLE"
			color = Estilo.C_AMARILLO
		_texto(Vector2(0, zona.get_center().y + 16.0), texto, color, 48, size.x, true)

func _dibujar_sellar(zona: Rect2) -> void:
	# Placas del casco con remaches
	var x: float = zona.position.x + 125.0
	while x < zona.end.x:
		draw_line(Vector2(x, zona.position.y), Vector2(x, zona.end.y), Color(0.05, 0.07, 0.12), 3.0)
		draw_line(Vector2(x + 3.0, zona.position.y), Vector2(x + 3.0, zona.end.y), Color(0.20, 0.26, 0.38), 2.0)
		x += 125.0
	var y: float = zona.position.y + 100.0
	while y < zona.end.y:
		draw_line(Vector2(zona.position.x, y), Vector2(zona.end.x, y), Color(0.05, 0.07, 0.12), 3.0)
		draw_line(Vector2(zona.position.x, y + 3.0), Vector2(zona.end.x, y + 3.0), Color(0.20, 0.26, 0.38), 2.0)
		y += 100.0
	x = zona.position.x + 12.0
	while x < zona.end.x:
		draw_rect(Rect2(x, zona.position.y + 8.0, 5, 5), Color(0.34, 0.42, 0.56))
		draw_rect(Rect2(x, zona.end.y - 14.0, 5, 5), Color(0.34, 0.42, 0.56))
		x += 62.5
	for f in fugas:
		var p: Vector2 = f["pos"]
		if f["sellada"]:
			# Parche amarillo con cuatro remaches
			draw_set_transform(p, float(f["giro"]), Vector2.ONE)
			draw_rect(Rect2(-34, -26, 68, 52), Color(0.10, 0.09, 0.05))
			draw_rect(Rect2(-31, -23, 62, 46), Color(0.92, 0.76, 0.26))
			draw_rect(Rect2(-31, 13, 62, 10), Color(0.74, 0.58, 0.16))
			for esquina in [Vector2(-26, -18), Vector2(21, -18), Vector2(-26, 13), Vector2(21, 13)]:
				draw_rect(Rect2(esquina, Vector2(5, 5)), Color(0.35, 0.28, 0.10))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		# Grieta
		for i in 5:
			var ang: float = float(f["giro"]) * 3.0 + float(i) * 1.257
			draw_line(p, p + Vector2(cos(ang), sin(ang)) * (14.0 + float(i % 2) * 8.0), Color(0.0, 0.0, 0.02), 3.0)
		# Chorro de gas
		var dir: Vector2 = Vector2(cos(float(f["angulo"])), sin(float(f["angulo"])))
		for i in 5:
			var k: float = fposmod(_t * 1.6 + float(i) * 0.2, 1.0)
			var centro: Vector2 = p + dir * (8.0 + 70.0 * k) + Vector2(sin(_t * 9.0 + float(i)) * 4.0 * k, 0)
			var lado: float = roundf(6.0 + 16.0 * k)
			draw_rect(Rect2(centro - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), Color(0.85, 0.95, 1.0, (1.0 - k) * 0.85))
		# Aro que indica dónde hacer clic
		var r: float = 30.0 + 4.0 * sin(_t * 7.0)
		draw_arc(p, r, 0.0, TAU, 20, Color(1.0, 0.36, 0.36, 0.9), 3.0)

func _dibujar_alinear(zona: Rect2) -> void:
	var x0: float = zona.position.x + 90.0
	var ancho: float = zona.size.x - 180.0
	var cy: float = zona.get_center().y + 10.0
	draw_rect(Rect2(x0 - 6.0, cy - 30.0, ancho + 12.0, 60.0), Color(0.01, 0.02, 0.05))
	draw_rect(Rect2(x0 - 6.0, cy - 30.0, ancho + 12.0, 60.0), Color(0.22, 0.30, 0.44), false, 2.0)
	# Marcas de la regla
	for i in 21:
		var mx: float = x0 + ancho * float(i) / 20.0
		draw_line(Vector2(mx, cy + 18.0), Vector2(mx, cy + 28.0), Color(0.30, 0.38, 0.52), 2.0)
	# Zona verde
	var az: float = _ancho_zona() * ancho
	var color_zona: Color = Estilo.C_VERDE
	if congelado > 0.0 and not marcas.is_empty():
		color_zona = Color(0.7, 1.0, 0.75) if marcas[marcas.size() - 1] else Estilo.C_ROJO
	draw_rect(Rect2(x0 + zona_centro * ancho - az * 0.5, cy - 24.0, az, 48.0), Color(color_zona, 0.75))
	# Aguja
	var ax: float = x0 + aguja * ancho
	draw_rect(Rect2(ax - 4.0, cy - 44.0, 8.0, 88.0), Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(ax - 14.0, cy - 58.0), Vector2(ax + 14.0, cy - 58.0), Vector2(ax, cy - 40.0)]), Estilo.C_AMARILLO)
	# Luces de los 3 intentos
	for i in 3:
		var c: Color = Color(0.20, 0.25, 0.36)
		if i < marcas.size():
			c = Estilo.C_VERDE if marcas[i] else Estilo.C_ROJO
		elif i == ronda:
			c = Estilo.C_AMARILLO
		draw_rect(Rect2(zona.get_center().x - 66.0 + float(i) * 48.0, zona.position.y + 22.0, 36.0, 22.0), c)
	_texto(Vector2(0, zona.end.y - 22.0), "ESPACIO  o  CLIC  =  FIJAR", Estilo.C_TEXTO_SUAVE, 24, size.x, true)

func _dibujar_secuencia(zona: Rect2) -> void:
	var encendido: int = -1
	if mostrando:
		var k: float = _t - 0.5
		if k >= 0.0:
			var paso: int = int(k / 0.55)
			if paso < orden.size() and fposmod(k, 0.55) < 0.42:
				encendido = int(orden[paso])
	for i in 5:
		var r: Rect2 = _rect_interruptor(i)
		var base: Color = COLORES_INTERRUPTOR[i]
		var color: Color = base.darkened(0.72)
		if i == encendido:
			color = base
		if destello.has(i):
			color = Estilo.C_VERDE if destello[i]["bien"] else Estilo.C_ROJO
		draw_rect(r.grow(5.0), Color(0.01, 0.02, 0.05))
		draw_rect(r, color)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 12.0)), color.lightened(0.25))
		draw_rect(Rect2(r.position.x, r.end.y - 14.0, r.size.x, 14.0), color.darkened(0.3))
		_texto(Vector2(r.position.x, r.end.y + 34.0), str(i + 1), base, 24, r.size.x, true)
	var texto: String = "OBSERVA EL ORDEN..." if mostrando else "TU TURNO:  %d / %d" % [indice, orden.size()]
	_texto(Vector2(0, zona.position.y + 46.0), texto, Estilo.C_AMARILLO if mostrando else Estilo.C_VERDE, 24, size.x, true)

func _dibujar_valvula(zona: Rect2) -> void:
	# Manómetro vertical
	var alto: float = zona.size.y - 60.0
	var mx: float = zona.position.x + 150.0
	var my: float = zona.position.y + 30.0
	draw_rect(Rect2(mx - 6.0, my - 6.0, 112.0, alto + 12.0), Color(0.01, 0.02, 0.05))
	draw_rect(Rect2(mx - 6.0, my - 6.0, 112.0, alto + 12.0), Color(0.22, 0.30, 0.44), false, 2.0)
	var centro: float = _centro_valvula()
	var dentro: bool = absf(presion - centro) <= 0.10
	draw_rect(Rect2(mx, my + alto * (1.0 - (centro + 0.10)), 100.0, alto * 0.20), Color(Estilo.C_VERDE, 0.55))
	var color: Color = Estilo.C_CIAN if dentro else Estilo.C_NARANJA
	draw_rect(Rect2(mx + 30.0, my + alto * (1.0 - presion), 40.0, alto * presion), color)
	draw_rect(Rect2(mx - 14.0, my + alto * (1.0 - presion) - 4.0, 128.0, 8.0), Color(1, 1, 1))
	# Progreso de estabilidad
	var bx: float = mx + 190.0
	var bw: float = zona.end.x - bx - 60.0
	_texto(Vector2(bx, zona.position.y + 70.0), "ESTABILIDAD", Estilo.C_TEXTO_SUAVE, 24)
	draw_rect(Rect2(bx, zona.position.y + 90.0, bw, 40.0), Color(0.01, 0.02, 0.05))
	draw_rect(Rect2(bx, zona.position.y + 90.0, bw * clampf(en_zona / 3.0, 0.0, 1.0), 40.0), Estilo.C_VERDE)
	draw_rect(Rect2(bx, zona.position.y + 90.0, bw, 40.0), Color(0.22, 0.30, 0.44), false, 2.0)
	var pista: String = "EN LA ZONA: sigue así" if dentro else ("MANTÉN PULSADO para subir" if presion < centro else "SUELTA para bajar")
	_texto(Vector2(bx, zona.position.y + 180.0), pista, Estilo.C_VERDE if dentro else Estilo.C_AMARILLO, 24)
	_texto(Vector2(bx, zona.position.y + 226.0), "Ratón o ESPACIO", Estilo.C_TEXTO_SUAVE, 16)
