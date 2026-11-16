extends Node
# Sonido del juego (Autoload "Sonido"): música, zumbido de la nave y efectos.
# Los archivos están en assets/audio/ y se generan con tools/generar_audio.py.
# Para cambiar un sonido, reemplaza el .wav por otro con el MISMO nombre.
#
# Uso desde cualquier script:
#     Sonido.efecto("alarma")              # reproduce assets/audio/alarma.wav una vez
#     Sonido.musica("musica_tension")      # música de fondo en bucle (cambia con fundido)
#     Sonido.zumbido(true)                 # zumbido del soporte vital
#     Sonido.alternar_silencio()           # botón de silenciar

const RUTA: String = "res://assets/audio/"
const VOLUMEN_MUSICA: float = -13.0
const VOLUMEN_ZUMBIDO: float = -24.0
const VOLUMEN_EFECTOS: float = -6.0

var silenciado: bool = false

var _musica: AudioStreamPlayer
var _zumbido: AudioStreamPlayer
var _efectos: Array = []
var _cache: Dictionary = {}
var _pista: String = ""
var _fundido: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = _nuevo_reproductor(VOLUMEN_MUSICA)
	_zumbido = _nuevo_reproductor(VOLUMEN_ZUMBIDO)
	for i in 6:
		_efectos.append(_nuevo_reproductor(VOLUMEN_EFECTOS))
	# Todos los botones del juego suenan al pulsarlos, sin tener que conectarlos uno por uno
	get_tree().node_added.connect(_on_nodo_nuevo)

func _nuevo_reproductor(volumen: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.volume_db = volumen
	add_child(p)
	return p

func _on_nodo_nuevo(nodo: Node) -> void:
	if nodo is BaseButton and not nodo.pressed.is_connected(clic):
		nodo.pressed.connect(clic)

func _cargar(nombre: String, bucle: bool = false) -> AudioStream:
	if _cache.has(nombre):
		return _cache[nombre]
	var ruta: String = RUTA + nombre + ".wav"
	var s: AudioStream = null
	if ResourceLoader.exists(ruta):
		s = load(ruta)
		if bucle and s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
	_cache[nombre] = s
	return s

func clic() -> void:
	efecto("clic", -4.0)

# Reproduce un efecto una vez. "volumen" se suma al volumen general de los efectos (en decibelios).
func efecto(nombre: String, volumen: float = 0.0) -> void:
	var s: AudioStream = _cargar(nombre)
	if s == null:
		return
	var libre: AudioStreamPlayer = _efectos[0]
	for p in _efectos:
		if not p.playing:
			libre = p
			break
	libre.stream = s
	libre.volume_db = VOLUMEN_EFECTOS + volumen
	libre.play()

# Cambia la música de fondo con un fundido suave. Pasa "" para quitarla.
func musica(nombre: String) -> void:
	if nombre == _pista:
		return
	_pista = nombre
	if _fundido != null and _fundido.is_valid():
		_fundido.kill()
	_fundido = create_tween()
	if _musica.playing:
		_fundido.tween_property(_musica, "volume_db", -50.0, 0.6)
	_fundido.tween_callback(_poner_pista.bind(nombre))
	if nombre != "":
		_fundido.tween_property(_musica, "volume_db", VOLUMEN_MUSICA, 1.2)

func _poner_pista(nombre: String) -> void:
	_musica.stop()
	if nombre == "":
		return
	var s: AudioStream = _cargar(nombre, true)
	if s == null:
		return
	_musica.stream = s
	_musica.volume_db = -50.0
	_musica.play()

func zumbido(activo: bool) -> void:
	if not activo:
		_zumbido.stop()
		return
	if _zumbido.playing:
		return
	var s: AudioStream = _cargar("zumbido", true)
	if s == null:
		return
	_zumbido.stream = s
	_zumbido.play()

func alternar_silencio() -> bool:
	silenciado = not silenciado
	AudioServer.set_bus_mute(0, silenciado)
	return silenciado
