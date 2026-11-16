extends Control
# Minijuegos de TAREA MANUAL.
# Aparecen después de elegir un procedimiento válido (no una trampa) en una emergencia de la nave
# o en una decisión de recursos: tú mismo haces el trabajo y qué tan bien te salga cambia el resultado.
#
# Hay 6 minijuegos (todo se dibuja con código en _draw, no usan imágenes):
#   "sellar"     -> haz clic en las fugas para taparlas con parches
#   "alinear"    -> detén la aguja dentro de la zona verde (3 intentos)
#   "secuencia"  -> repite el orden en que se encienden los interruptores
#   "valvula"    -> mantén pulsado para sostener la presión dentro de la franja verde
#   "conectar"   -> une cada conector con el de su mismo color
#   "atrapar"    -> mueve la bandeja para atrapar lo azul y esquivar lo rojo
#
# Cada uno empieza con un mini tutorial: la primera vez hay que pulsar EMPEZAR;
# las siguientes veces solo sale un "¿LISTO?" de un segundo con el recordatorio.
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
	"conectar": "RECONECTA LOS CABLES",
	"atrapar": "ATRAPA LO QUE SIRVE",
}
# Recordatorio de una línea (sale arriba del minijuego)
const INSTRUCCIONES: Dictionary = {
	"sellar": "Haz clic sobre cada fuga para taparla con un parche.",
	"alinear": "Pulsa ESPACIO o haz clic cuando la aguja pase por la zona verde.",
	"secuencia": "Mira el orden de las luces y repítelo con clics.",
	"valvula": "Mantén pulsado para subir la aguja y sostenla en la franja verde.",
	"conectar": "Une cada conector de la izquierda con el de su mismo color.",
	"atrapar": "Mueve la bandeja: atrapa lo azul y esquiva lo rojo.",
}
# Mini tutorial: dos pasos cortos por minijuego
const TUTORIAL: Dictionary = {
	"sellar": ["Las fugas tienen un aro rojo.", "Haz clic en cada una para ponerle un parche."],
	"alinear": ["La aguja se mueve sola de lado a lado.", "Pulsa ESPACIO o haz clic cuando pase por el verde."],
	"secuencia": ["Primero mira en qué orden se encienden las luces.", "Luego haz clic en los interruptores en ese mismo orden."],
	"valvula": ["Mantén pulsado el ratón (o ESPACIO) para subir la aguja.", "Suelta para bajarla. Sostenla dentro de la franja verde."],
	"conectar": ["Haz clic en un conector de la izquierda.", "Después haz clic en el del mismo color a la derecha."],
	"atrapar": ["Mueve el ratón (o las flechas) para mover la bandeja.", "Atrapa lo azul y esquiva lo rojo."],
}
const DURACION: Dictionary = {"sellar": 7.0, "alinear": 12.0, "secuencia": 9.0, "valvula": 8.0, "conectar": 10.0, "atrapar": 11.0}
const COLORES_INTERRUPTOR: Array = [Color(0.35, 0.80, 1.0), Color(1.0, 0.85, 0.30), Color(0.40, 0.90, 0.50), Color(0.72, 0.52, 1.0), Color(1.0, 0.60, 0.25)]
const META_ATRAPAR: int = 8

# Qué minijuegos le quedan bien a cada tema (el primero es el preferido)
const POR_TEMA: Array = [
	[["despresurizaci", "integridad", "emergencias"], ["sellar", "valvula"]],
	[["agua"], ["atrapar", "valvula"]],
	[["nutrici", "metabólic", "reservas de emergencia", "dinámica de vuelo"], ["atrapar", "secuencia"]],
	[["eléctric", "energía", "redundancia"], ["conectar", "secuencia"]],
	[["computadora", "instrumentaci", "monitoreo", "incendio", "carga útil", "datos"], ["secuencia", "conectar"]],
	[["térmic", "co₂", "co2", "aire", "atmósfera", "higiene", "humedad"], ["valvula", "sellar"]],
]
const POR_DEFECTO: Array = ["alinear", "conectar"]

# Minijuegos que el jugador ya vio en esta sesión (para no repetir el tutorial completo)
static var vistos: Dictionary = {}

var tipo: String = "sellar"
var duracion: float = 7.0
var tiempo: float = 0.0
var estado: String = "tutorial"     # tutorial -> (listo) -> jugando -> fin
var habilidad: float = 0.0
var activo: bool:
	get:
		return estado == "jugando"
var _t: float = 0.0
var _cuenta: float = 0.0
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
var _t_muestra: float = 0.0
# valvula
var presion: float = 0.2
var en_zona: float = 0.0
# conectar
var orden_derecha: Array = []
var conexiones: Dictionary = {}     # conector izquierdo -> hueco derecho
var elegido: int = -1
# atrapar
var bandeja_x: float = 0.0
var objetos: Array = []
var atrapados: int = 0
var golpes: int = 0
var _siguiente_objeto: float = 0.0
var _teclas: float = 0.0
var _golpe: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(1000, 330)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fuente = Estilo.fuente(24)
	_rng.randomize()

# Qué minijuego toca según el tema de la decisión. "ultimo" es el anterior, para no repetirlo seguido.
static func elegir(tema: String, ultimo: String = "") -> String:
	var t: String = tema.to_lower()
	var candidatos: Array = POR_DEFECTO
	for par in POR_TEMA:
		var coincide: bool = false
		for clave in par[0]:
			if t.contains(String(clave)):
				coincide = true
		if coincide:
			candidatos = par[1]
			break
	if String(candidatos[0]) == ultimo and candidatos.size() > 1:
		return String(candidatos[1])
	return String(candidatos[0])

func iniciar(tipo_juego: String, factor_tiempo: float = 1.0) -> void:
	tipo = tipo_juego if DURACION.has(tipo_juego) else "alinear"
	duracion = float(DURACION[tipo]) * factor_tiempo
	tiempo = duracion
	_pulsado = false
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
		"valvula":
			presion = 0.2
			en_zona = 0.0
		"conectar":
			orden_derecha = [0, 1, 2, 3]
			orden_derecha.shuffle()
			conexiones = {}
			elegido = -1
			errores = 0
		"atrapar":
			objetos = []
			atrapados = 0
			golpes = 0
			_siguiente_objeto = 0.2
			bandeja_x = size.x * 0.5
	if vistos.has(tipo):
		estado = "listo"
		_cuenta = 1.3
	else:
		estado = "tutorial"
	queue_redraw()

func _empezar() -> void:
	vistos[tipo] = true
	estado = "jugando"
	_t_muestra = 0.0
	Sonido.efecto("clic")

# ---------------------------------------------------------------
# Lógica por cuadro
# ---------------------------------------------------------------
func _process(delta: float) -> void:
	_t += delta
	if estado == "listo":
		_cuenta -= delta
		if _cuenta <= 0.0:
			estado = "jugando"
			_t_muestra = 0.0
	elif estado == "jugando":
		_logica(delta)
	queue_redraw()

func _logica(delta: float) -> void:
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
			_t_muestra += delta
			if mostrando:
				corre_reloj = false
				if _t_muestra > 0.5 + orden.size() * 0.55:
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
		"conectar":
			for k in destello.keys():
				destello[k]["t"] = float(destello[k]["t"]) - delta
				if float(destello[k]["t"]) <= 0.0:
					destello.erase(k)
		"atrapar":
			_logica_atrapar(delta)
			if acabado():
				return
	if corre_reloj:
		tiempo -= delta
		if tiempo <= 0.0:
			_por_tiempo()

func acabado() -> bool:
	return estado == "fin"

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
		"conectar":
			_terminar(clampf(float(conexiones.size()) / 4.0 * 2.0 - 1.0 - 0.5 * float(errores), -1.0, 1.0))
		"atrapar":
			_terminar(clampf(float(atrapados - golpes) / float(META_ATRAPAR), 0.0, 1.0) * 2.0 - 1.0)

func _terminar(valor: float) -> void:
	if estado == "fin":
		return
	estado = "fin"
	habilidad = clampf(valor, -1.0, 1.0)
	Sonido.efecto("exito" if habilidad >= 0.6 else ("aviso" if habilidad >= 0.0 else "fallo"), -4.0)
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	terminado.emit(habilidad)

# Para las pruebas automáticas: termina ya con una nota dada
func forzar(valor: float) -> void:
	vistos[tipo] = true
	_terminar(valor)

# ---------------------------------------------------------------
# Entradas
# ---------------------------------------------------------------
func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_pulsado = evento.pressed
		if not evento.pressed:
			return
		if estado == "tutorial":
			if _rect_boton_empezar().has_point(evento.position):
				_pulsado = false
				_empezar()
		elif estado == "jugando":
			_clic(evento.position)

func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
		_pulsado = false
	elif evento is InputEventKey and not evento.echo and is_visible_in_tree():
		if evento.keycode == KEY_SPACE or evento.keycode == KEY_ENTER or evento.keycode == KEY_KP_ENTER:
			if estado == "tutorial":
				if evento.pressed:
					_empezar()
			elif evento.keycode == KEY_SPACE:
				_pulsado = evento.pressed
				if evento.pressed and estado == "jugando" and tipo == "alinear":
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
		"conectar":
			for i in 4:
				if _rect_conector(0, i).grow(10.0).has_point(pos) and not conexiones.has(i):
					elegido = i
					Sonido.efecto("clic")
					return
			if elegido == -1:
				return
			for j in 4:
				if _rect_conector(1, j).grow(10.0).has_point(pos):
					if int(orden_derecha[j]) == elegido:
						conexiones[elegido] = j
						Sonido.efecto("clic")
						if conexiones.size() >= 4:
							_terminar(clampf(1.0 - 0.5 * float(errores), -1.0, 1.0))
					else:
						errores += 1
						destello[j] = {"t": 0.35, "bien": false}
						Sonido.efecto("tic")
					elegido = -1
					return

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
	if congelado > 0.0 or estado != "jugando":
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
# Atrapar
# ---------------------------------------------------------------
func _logica_atrapar(delta: float) -> void:
	var zona: Rect2 = _zona_juego()
	# La bandeja sigue al ratón; con las flechas (o A y D) también se mueve
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		bandeja_x -= 640.0 * delta
		_teclas = 0.6
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		bandeja_x += 640.0 * delta
		_teclas = 0.6
	_teclas -= delta
	var raton: Vector2 = get_local_mouse_position()
	if _teclas <= 0.0 and Rect2(Vector2.ZERO, size).grow(60.0).has_point(raton):
		bandeja_x = raton.x
	bandeja_x = clampf(bandeja_x, zona.position.x + 74.0, zona.end.x - 74.0)
	_golpe = maxf(0.0, _golpe - delta)

	_siguiente_objeto -= delta
	if _siguiente_objeto <= 0.0:
		_siguiente_objeto = 0.40
		objetos.append({
			"pos": Vector2(_rng.randf_range(zona.position.x + 50.0, zona.end.x - 50.0), zona.position.y + 6.0),
			"vel": _rng.randf_range(230.0, 330.0),
			"bueno": _rng.randf() < 0.7,
		})
	var y_bandeja: float = zona.end.y - 36.0
	var quedan: Array = []
	for o in objetos:
		var p: Vector2 = o["pos"]
		p.y += float(o["vel"]) * delta
		o["pos"] = p
		if p.y >= y_bandeja - 12.0 and p.y <= y_bandeja + 16.0 and absf(p.x - bandeja_x) <= 82.0:
			if o["bueno"]:
				atrapados += 1
				Sonido.efecto("clic")
			else:
				golpes += 1
				_golpe = 0.3
				Sonido.efecto("tic")
			continue
		if p.y < zona.end.y + 20.0:
			quedan.append(o)
	objetos = quedan
	if atrapados - golpes >= META_ATRAPAR:
		_terminar(1.0)

# ---------------------------------------------------------------
# Rectángulos de las piezas
# ---------------------------------------------------------------
func _zona_juego() -> Rect2:
	return Rect2(0.0, 22.0, size.x, size.y - 22.0)

func _rect_interruptor(i: int) -> Rect2:
	var lado: float = 120.0
	var hueco: float = (size.x - 5.0 * lado) / 6.0
	return Rect2(hueco + float(i) * (lado + hueco), size.y * 0.5 - 40.0, lado, lado)

# lado 0 = izquierda, lado 1 = derecha
func _rect_conector(lado: int, i: int) -> Rect2:
	var zona: Rect2 = _zona_juego()
	var alto: float = 46.0
	var hueco: float = (zona.size.y - 4.0 * alto) / 5.0
	var x: float = zona.position.x + 110.0 if lado == 0 else zona.end.x - 110.0 - 100.0
	return Rect2(x, zona.position.y + hueco + float(i) * (alto + hueco), 100.0, alto)

func _rect_boton_empezar() -> Rect2:
	var zona: Rect2 = _zona_juego()
	return Rect2(zona.get_center().x - 150.0, zona.end.y - 78.0, 300.0, 52.0)

# ---------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------
func _texto(pos: Vector2, texto: String, color: Color, tam: int = 24, ancho: float = -1.0, centrado: bool = false) -> void:
	if _fuente == null:
		return
	draw_string(_fuente, pos, texto, HORIZONTAL_ALIGNMENT_CENTER if centrado else HORIZONTAL_ALIGNMENT_LEFT, ancho, tam, color)

func _draw() -> void:
	var zona: Rect2 = _zona_juego()
	# Fondo del panel de trabajo
	draw_rect(zona, Color(0.13, 0.17, 0.27) if tipo == "sellar" else Color(0.06, 0.08, 0.14))
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
		"conectar":
			_dibujar_conectar(zona)
		"atrapar":
			_dibujar_atrapar(zona)
	draw_rect(zona, Estilo.C_BORDE, false, 2.0)

	if estado == "tutorial":
		_dibujar_tutorial(zona)
	elif estado == "listo":
		draw_rect(zona, Color(0.02, 0.03, 0.08, 0.72))
		_texto(Vector2(0, zona.get_center().y - 6.0), Idioma.t("¿LISTO?"), Estilo.C_AMARILLO, 48, size.x, true)
		_texto(Vector2(0, zona.get_center().y + 44.0), Idioma.t(String(INSTRUCCIONES[tipo])), Estilo.C_TEXTO, 16, size.x, true)
	elif estado == "fin":
		draw_rect(zona, Color(0.02, 0.03, 0.08, 0.82))
		var texto: String = "FALLASTE"
		var color: Color = Estilo.C_ROJO
		if habilidad >= 0.6:
			texto = "¡PERFECTO!"
			color = Estilo.C_VERDE
		elif habilidad >= 0.0:
			texto = "ACEPTABLE"
			color = Estilo.C_AMARILLO
		_texto(Vector2(0, zona.get_center().y + 16.0), Idioma.t(texto), color, 48, size.x, true)

# Mini tutorial: tarjeta con dos pasos y el botón EMPEZAR
func _dibujar_tutorial(zona: Rect2) -> void:
	draw_rect(zona, Color(0.02, 0.03, 0.08, 0.86))
	var tarjeta: Rect2 = Rect2(zona.get_center().x - 400.0, zona.position.y + 14.0, 800.0, zona.size.y - 28.0)
	draw_rect(tarjeta, Color(0.05, 0.08, 0.16))
	draw_rect(tarjeta, Estilo.C_AMARILLO, false, 2.0)
	_texto(Vector2(tarjeta.position.x, tarjeta.position.y + 40.0), Idioma.t("CÓMO SE JUEGA"), Estilo.C_AMARILLO, 24, tarjeta.size.x, true)
	var pasos: Array = TUTORIAL[tipo]
	for i in pasos.size():
		var y: float = tarjeta.position.y + 84.0 + float(i) * 44.0
		# Número del paso dentro de un cuadrito
		draw_rect(Rect2(tarjeta.position.x + 40.0, y - 26.0, 34.0, 34.0), Color(0.16, 0.38, 0.72))
		_texto(Vector2(tarjeta.position.x + 40.0, y), str(i + 1), Color(1, 1, 1), 24, 34.0, true)
		_texto(Vector2(tarjeta.position.x + 88.0, y - 2.0), Idioma.t(String(pasos[i])), Estilo.C_TEXTO, 16)
	var boton: Rect2 = _rect_boton_empezar()
	var encima: bool = boton.has_point(get_local_mouse_position())
	draw_rect(boton.grow(3.0), Color(0.08, 0.10, 0.16))
	draw_rect(boton, Color(1.0, 0.93, 0.70) if encima else Color(1.0, 0.99, 0.94))
	draw_rect(Rect2(boton.position.x, boton.end.y - 8.0, boton.size.x, 8.0), Color(1.0, 0.75, 0.45))
	_texto(Vector2(boton.position.x, boton.position.y + 36.0), Idioma.t("EMPEZAR"), Estilo.C_OSCURO, 24, boton.size.x, true)
	_texto(Vector2(tarjeta.position.x, boton.position.y - 14.0), Idioma.t("Haz clic en el botón o pulsa ESPACIO"), Estilo.C_TEXTO_SUAVE, 16, tarjeta.size.x, true)

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
	_texto(Vector2(0, zona.end.y - 22.0), Idioma.t("ESPACIO  o  CLIC  =  FIJAR"), Estilo.C_TEXTO_SUAVE, 24, size.x, true)

func _dibujar_secuencia(zona: Rect2) -> void:
	var encendido: int = -1
	if mostrando and estado == "jugando":
		var k: float = _t_muestra - 0.5
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
	var texto: String = Idioma.t("OBSERVA EL ORDEN...") if mostrando else Idioma.t("TU TURNO:  %d / %d") % [indice, orden.size()]
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
	_texto(Vector2(bx, zona.position.y + 70.0), Idioma.t("ESTABILIDAD"), Estilo.C_TEXTO_SUAVE, 24)
	draw_rect(Rect2(bx, zona.position.y + 90.0, bw, 40.0), Color(0.01, 0.02, 0.05))
	draw_rect(Rect2(bx, zona.position.y + 90.0, bw * clampf(en_zona / 3.0, 0.0, 1.0), 40.0), Estilo.C_VERDE)
	draw_rect(Rect2(bx, zona.position.y + 90.0, bw, 40.0), Color(0.22, 0.30, 0.44), false, 2.0)
	var pista: String = "EN LA ZONA: sigue así" if dentro else ("MANTÉN PULSADO para subir" if presion < centro else "SUELTA para bajar")
	_texto(Vector2(bx, zona.position.y + 180.0), Idioma.t(pista), Estilo.C_VERDE if dentro else Estilo.C_AMARILLO, 24)
	_texto(Vector2(bx, zona.position.y + 226.0), Idioma.t("Ratón o ESPACIO"), Estilo.C_TEXTO_SUAVE, 16)

# Figura distinta en cada conector (además del color), para que no dependa solo del color
func _figura(centro: Vector2, cual: int, color: Color) -> void:
	match cual:
		0:
			draw_rect(Rect2(centro - Vector2(9, 9), Vector2(18, 18)), color)
		1:
			draw_colored_polygon(PackedVector2Array([centro + Vector2(0, -11), centro + Vector2(11, 9), centro + Vector2(-11, 9)]), color)
		2:
			draw_circle(centro, 10.0, color)
		_:
			draw_colored_polygon(PackedVector2Array([centro + Vector2(0, -12), centro + Vector2(12, 0), centro + Vector2(0, 12), centro + Vector2(-12, 0)]), color)

func _cable(desde: Vector2, hasta: Vector2, color: Color) -> void:
	var puntos = PackedVector2Array([desde, desde + Vector2(60, 0), hasta - Vector2(60, 0), hasta])
	draw_polyline(puntos, Color(0.01, 0.02, 0.05), 12.0)
	draw_polyline(puntos, color, 7.0)

func _dibujar_conectar(zona: Rect2) -> void:
	# Cables ya conectados
	for i in conexiones:
		var a: Rect2 = _rect_conector(0, int(i))
		var b: Rect2 = _rect_conector(1, int(conexiones[i]))
		_cable(Vector2(a.end.x, a.get_center().y), Vector2(b.position.x, b.get_center().y), COLORES_INTERRUPTOR[int(i)])
	# Cable que sigue al ratón
	if elegido != -1 and estado == "jugando":
		var origen: Rect2 = _rect_conector(0, elegido)
		var raton: Vector2 = get_local_mouse_position()
		draw_line(Vector2(origen.end.x, origen.get_center().y), raton, COLORES_INTERRUPTOR[elegido], 6.0)
	for lado in 2:
		for i in 4:
			var r: Rect2 = _rect_conector(lado, i)
			var cual: int = i if lado == 0 else int(orden_derecha[i])
			var color: Color = COLORES_INTERRUPTOR[cual]
			var hecho: bool = conexiones.has(cual)
			draw_rect(r.grow(4.0), Color(0.01, 0.02, 0.05))
			draw_rect(r, color if not hecho else color.darkened(0.35))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 8.0)), color.lightened(0.3))
			_figura(r.get_center() + Vector2(0, 3), cual, Color(0.03, 0.04, 0.09))
			if lado == 0 and i == elegido:
				draw_rect(r.grow(7.0), Color(1, 1, 1), false, 3.0)
			if lado == 1 and destello.has(i):
				draw_rect(r.grow(7.0), Estilo.C_ROJO, false, 4.0)
	_texto(Vector2(0, zona.end.y - 14.0), Idioma.t("CONECTADOS:  %d / 4") % conexiones.size(), Estilo.C_VERDE, 16, size.x, true)

func _dibujar_atrapar(zona: Rect2) -> void:
	# Rieles de fondo
	var x: float = zona.position.x + 100.0
	while x < zona.end.x:
		draw_line(Vector2(x, zona.position.y), Vector2(x, zona.end.y), Color(0.09, 0.12, 0.20), 2.0)
		x += 100.0
	for o in objetos:
		var p: Vector2 = o["pos"]
		if o["bueno"]:
			# Gota azul
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -16), p + Vector2(10, 0), p + Vector2(-10, 0)]), Estilo.C_CIAN)
			draw_rect(Rect2(p + Vector2(-10, -2), Vector2(20, 14)), Estilo.C_CIAN)
			draw_rect(Rect2(p + Vector2(-6, 2), Vector2(5, 5)), Color(0.85, 0.97, 1.0))
		else:
			# Escombro rojo con una equis
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -15), p + Vector2(15, 0), p + Vector2(0, 15), p + Vector2(-15, 0)]), Estilo.C_ROJO)
			draw_line(p + Vector2(-6, -6), p + Vector2(6, 6), Color(0.25, 0.03, 0.03), 3.0)
			draw_line(p + Vector2(6, -6), p + Vector2(-6, 6), Color(0.25, 0.03, 0.03), 3.0)
	# Bandeja
	var y_bandeja: float = zona.end.y - 36.0
	var color_bandeja: Color = Estilo.C_ROJO if _golpe > 0.0 else Color(0.85, 0.89, 0.96)
	draw_rect(Rect2(bandeja_x - 74.0, y_bandeja - 4.0, 148.0, 24.0), Color(0.01, 0.02, 0.05))
	draw_rect(Rect2(bandeja_x - 70.0, y_bandeja, 140.0, 16.0), color_bandeja)
	draw_rect(Rect2(bandeja_x - 70.0, y_bandeja - 12.0, 10.0, 16.0), color_bandeja)
	draw_rect(Rect2(bandeja_x + 60.0, y_bandeja - 12.0, 10.0, 16.0), color_bandeja)
	var llevas: int = maxi(atrapados - golpes, 0)
	_texto(Vector2(zona.position.x + 16.0, zona.position.y + 34.0), Idioma.t("LLEVAS:  %d / %d") % [llevas, META_ATRAPAR], Estilo.C_VERDE, 24)
