extends Node
# MYG-351 LAST SIGNAL - motor de reglas (Autoload "GameManager").
# Aquí vive todo el estado de la partida y las reglas del documento "Diseño del sistema de juego".
# Las cifras marcadas como "propuesta" salen del documento de diseño o son supuestos que
# el ingeniero industrial debe calibrar (por eso están todas juntas arriba, como constantes).

const DIAS_TOTALES: int = 14
const TRIPULANTES: Array = ["elena", "marcus", "sofia", "leo"]

# --- Umbrales unificados (sección 9 del documento) ---
const UMBRAL_ALARMA: float = 20.0
const UMBRAL_ABORTO: float = 25.0
const UMBRAL_FINAL_BUENO: float = 15.0
const CIENCIA_FINAL_BUENO: float = 70.0
const INTEGRIDAD_REENTRADA: float = 25.0   # supuesto: por debajo, el escudo térmico no resiste la reentrada

# --- Resolución de una decisión: P = v + b_especialista - p_estres + ruido (sección 5) ---
const V_NORMAL: float = 0.3                 # supuesto: el banco no trae valor base por opción
const V_TRAMPA: float = -1.0
const BONO_ESPECIALISTA: float = 0.2
const PENAL_ESTRES: float = 0.2
const RUIDO: float = 0.2
const P_BUENO: float = 0.5
const P_MALO: float = -0.1

# --- Consumo diario y efectos del día (sección 3 y 4; propuestas) ---
const ESTRES_AISLAMIENTO_HIGIENE: float = 3.0
const CIENCIA_DIA: Dictionary = {"apagados": 0.0, "basicos": 2.5, "todos": 5.0}
const DATOS_DIA: Dictionary = {"apagados": 0.0, "basicos": 4.0, "todos": 8.0}
const ELEC_INSTRUMENTOS: Dictionary = {"apagados": 0.0, "basicos": 1.0, "todos": 2.0}
const HAMBRE_RACION: Dictionary = {"completa": -5.0, "reducida": 5.0, "minima": 12.0}
const COMIDA_RACION: Dictionary = {"completa": 1.0, "reducida": 0.8, "minima": 0.6}
const TRANSMISION_DATOS: float = 10.0

# --- Fase 0: presupuesto (10.000 CM; 4.000 fijos y 6.000 para configurar) ---
const PRESUPUESTO_TOTAL: int = 10000
const COSTO_OBLIGATORIO: int = 4000
const PRESUPUESTO_LIBRE: int = 6000

# Los 4 controles de la configuración "Personalizada". El Paquete A y el B son atajos que fijan estos niveles.
var controles: Array = [
	{"id": "soporte", "nombre": "Reservas de soporte vital", "max": 4, "costo": 750,
	 "efecto": "Cada nivel baja el consumo diario de agua, comida y oxígeno (-0,43 puntos) y el estrés base (-0,25)."},
	{"id": "celdas", "nombre": "Combustible y celdas extra", "max": 4, "costo": 375,
	 "efecto": "Cada nivel baja el consumo eléctrico (-0,38 puntos) y el costo de las maniobras (-5 %)."},
	{"id": "filtros", "nombre": "Filtros de CO2 adicionales", "max": 2, "costo": 750,
	 "efecto": "Cada nivel suma un cartucho de reserva (la referencia trae 2)."},
	{"id": "instrumentos", "nombre": "Instrumentos científicos", "max": 3, "costo": 1500,
	 "efecto": "Cada nivel sube el tope de progreso científico (+20 puntos sobre 40)."},
]

var paquetes: Dictionary = {
	"A": {"nombre": "Paquete A: Supervivencia (Marcus y Sofía)",
		"niveles": {"soporte": 4, "celdas": 0, "filtros": 2, "instrumentos": 1},
		"descripcion": "Reservas +20 %, 4 filtros de CO2 y raciones de alta moral. Poco espacio para instrumentos."},
	"B": {"nombre": "Paquete B: Ciencia y propulsión (Leo y Elena)",
		"niveles": {"soporte": 0, "celdas": 4, "filtros": 0, "instrumentos": 3},
		"descripcion": "Espectrómetros, taladro lunar y celdas extra. Agua y comida justo en el límite."},
}

# --- Nombres para mostrar ---
const ETIQUETAS: Dictionary = {
	"oxigeno": "Oxígeno", "agua": "Agua", "comida": "Comida", "electricidad": "Electricidad",
	"combustible": "Combustible", "temperatura": "Temperatura (°C)", "integridad": "Integridad",
	"datos": "Datos", "ciencia": "Ciencia", "filtros": "Filtros de CO2",
	"estres_todos": "Estrés (todos)", "salud_todos": "Salud (todos)", "hambre_todos": "Hambre (todos)",
	"reparaciones_dias": "Reparaciones lentas (días)", "modulo_dias": "Módulo bloqueado (días)",
	"enlace_dias": "Enlace perdido (días)",
}
const NOMBRES_TRIPULANTE: Dictionary = {"elena": "Elena", "marcus": "Marcus", "sofia": "Sofía", "leo": "Leo"}
const ETIQUETA_STAT: Dictionary = {"estres": "Estrés", "salud": "Salud", "hambre": "Hambre", "confianza": "Confianza"}
const NOMBRE_VAR: Dictionary = {
	"electricidad": "Electricidad", "combustible": "Combustible", "agua": "Agua", "oxigeno": "Oxígeno",
	"comida": "Comida", "temperatura": "Temperatura", "integridad": "Integridad", "datos": "Datos",
	"ciencia": "Progreso científico", "filtros": "Filtros de CO2", "estres_prom": "Estrés promedio",
	"salud_prom": "Salud promedio", "estres_leo": "Estrés de Leo", "estres_marcus": "Estrés de Marcus",
	"dias_restantes": "Días restantes", "dia": "Día", "enlace_perdido": "Enlace con la Tierra perdido",
	"enlace_necesario": "Datos por transmitir",
}
const NOMBRE_OP: Dictionary = {"<": "por debajo de", ">": "por encima de", "<=": "como máximo", ">=": "como mínimo"}

# --- Estado de la partida ---
var rng := RandomNumberGenerator.new()
var semilla: int = 0
var modo_sin_temporizador: bool = false

var plan_nombre: String = "Sin plan"
var plan_niveles: Dictionary = {"soporte": 0, "celdas": 0, "filtros": 0, "instrumentos": 0}
var consumo_basico: float = 7.1
var consumo_elec: float = 6.5
var estres_base: float = 3.0
var ciencia_max: float = 40.0
var mult_combustible: float = 1.0

var dia_actual: int = 1
var nave: Dictionary = {}
var temperatura: float = 22.0
var integridad: float = 100.0
var filtros: int = 2
var datos: float = 0.0
var ciencia: float = 0.0
var enlace_dias: int = 0
var modulo_dias: int = 0
var reparaciones_dias: int = 0
var tripulantes: Dictionary = {}

# Perillas persistentes
var racion: String = "completa"
var instrumentos: String = "basicos"
var higiene_suspendida: bool = false
var instrumentos_bloqueados: bool = false

var mision_abortada: bool = false
var forzar_final: String = ""
var penal_tiempo: float = 0.0
# Minijuego de reparación: si la pantalla pone aquí un valor entre -1 (falló) y 1 (perfecto), ese valor
# reemplaza al azar ("ruido") de la próxima decisión. NAN = no hubo minijuego y se tira el dado normal.
var habilidad_manual: float = NAN
var decisiones_totales: int = 0
var decisiones_buenas: int = 0

# Control de la selección de decisiones
var veces: Dictionary = {}
var ayer_ids: Array = []
var hoy_ids: Array = []
var gravedad_dias: Array = []
var gravedad_hoy: int = 0
var muertes_avisadas: Array = []

func _ready():
	nueva_partida()

func nueva_partida() -> void:
	rng.randomize()
	semilla = rng.randi() % 1000000
	rng.seed = semilla
	dia_actual = 1
	nave = {"agua": 100.0, "comida": 100.0, "oxigeno": 100.0, "electricidad": 100.0, "combustible": 100.0}
	temperatura = 22.0
	integridad = 100.0
	datos = 0.0
	ciencia = 0.0
	enlace_dias = 0
	modulo_dias = 0
	reparaciones_dias = 0
	racion = "completa"
	instrumentos = "basicos"
	higiene_suspendida = false
	instrumentos_bloqueados = false
	mision_abortada = false
	forzar_final = ""
	penal_tiempo = 0.0
	habilidad_manual = NAN
	decisiones_totales = 0
	decisiones_buenas = 0
	veces = {}
	ayer_ids = []
	hoy_ids = []
	gravedad_dias = []
	gravedad_hoy = 0
	muertes_avisadas = []
	tripulantes = {
		"elena": {"nombre": "Elena Marín", "rol": "Comandante y Piloto", "salud": 100.0, "hambre": 0.0, "estres": 0.0, "confianza": 70.0},
		"marcus": {"nombre": "Marcus Chen", "rol": "Ingeniero de Sistemas", "salud": 100.0, "hambre": 0.0, "estres": 0.0, "confianza": 70.0},
		"sofia": {"nombre": "Dra. Sofía Reyes", "rol": "Médica y Bióloga", "salud": 100.0, "hambre": 0.0, "estres": 0.0, "confianza": 70.0},
		"leo": {"nombre": "Leo Okafor", "rol": "Ingeniero mecánico", "salud": 100.0, "hambre": 0.0, "estres": 0.0, "confianza": 70.0},
	}
	aplicar_plan({"soporte": 0, "celdas": 0, "filtros": 0, "instrumentos": 0}, "Sin plan")

# ---------------------------------------------------------------
# Fase 0
# ---------------------------------------------------------------
func costo_plan(niveles: Dictionary) -> int:
	var total: int = 0
	for c in controles:
		total += int(niveles.get(c["id"], 0)) * int(c["costo"])
	return total

# Parámetros que resultan de una configuración (A y B son combinaciones de estos mismos niveles)
func parametros_plan(niveles: Dictionary) -> Dictionary:
	var s: int = int(niveles.get("soporte", 0))
	var c: int = int(niveles.get("celdas", 0))
	var f: int = int(niveles.get("filtros", 0))
	var i: int = int(niveles.get("instrumentos", 0))
	return {
		"consumo_basico": 7.1 - 0.425 * s,      # A (s=4): 5,4 | B (s=0): 7,1
		"consumo_elec": 6.5 - 0.375 * c,        # A (c=0): 6,5 | B (c=4): 5,0
		"estres_base": 3.0 - 0.25 * s,          # A: +2 | B: +3
		"ciencia_max": 40.0 + 20.0 * i,         # A (i=1): 60 | B (i=3): 100
		"mult_combustible": 1.0 - 0.05 * c,     # A: x1,0 | B: x0,8
		"filtros": 2 + f,                       # A: 4 | B: 2
	}

func nombre_plan(niveles: Dictionary) -> String:
	for clave in paquetes:
		if paquetes[clave]["niveles"] == niveles:
			return String(paquetes[clave]["nombre"]).split(":")[0]
	return "Personalizada"

func aplicar_plan(niveles: Dictionary, nombre: String) -> void:
	plan_niveles = niveles.duplicate()
	plan_nombre = nombre
	var p: Dictionary = parametros_plan(niveles)
	consumo_basico = float(p["consumo_basico"])
	consumo_elec = float(p["consumo_elec"])
	estres_base = float(p["estres_base"])
	ciencia_max = float(p["ciencia_max"])
	mult_combustible = float(p["mult_combustible"])
	filtros = int(p["filtros"])

# ---------------------------------------------------------------
# Consultas de estado
# ---------------------------------------------------------------
func esta_vivo(id: String) -> bool:
	return float(tripulantes[id]["salud"]) > 0.0

func vivos() -> Array:
	var lista: Array = []
	for id in TRIPULANTES:
		if esta_vivo(id):
			lista.append(id)
	return lista

func estado(id: String) -> String:
	var s: float = float(tripulantes[id]["salud"])
	if s <= 0.0:
		return "muerto"
	if s < 25.0:
		return "crítico"
	if s < 50.0:
		return "herido"
	return "activo"

func promedio_vivos(stat: String) -> float:
	var v: Array = vivos()
	if v.is_empty():
		return 0.0
	var suma: float = 0.0
	for id in v:
		suma += float(tripulantes[id][stat])
	return suma / float(v.size())

func valor_estado(nombre: String) -> float:
	match nombre:
		"agua", "comida", "oxigeno", "electricidad", "combustible":
			return float(nave[nombre])
		"temperatura":
			return temperatura
		"integridad":
			return integridad
		"datos":
			return datos
		"ciencia":
			return ciencia
		"filtros":
			return float(filtros)
		"estres_prom":
			return promedio_vivos("estres")
		"salud_prom":
			return promedio_vivos("salud")
		"estres_leo":
			return float(tripulantes["leo"]["estres"])
		"estres_marcus":
			return float(tripulantes["marcus"]["estres"])
		"dia":
			return float(dia_actual)
		"dias_restantes":
			return float(DIAS_TOTALES - dia_actual)
		"enlace_perdido":
			return 1.0 if enlace_dias > 0 else 0.0
		"enlace_necesario":
			return 1.0 if datos >= 60.0 else 0.0   # supuesto: hay que transmitir cuando la memoria pasa de 60 %
	return 0.0

func barra_en_cero() -> bool:
	for b in ["agua", "oxigeno", "electricidad", "combustible"]:
		if float(nave[b]) <= 0.0:
			return true
	return integridad <= 0.0

func alarmas() -> Array:
	var lista: Array = []
	for b in ["agua", "comida", "oxigeno", "electricidad", "combustible"]:
		if float(nave[b]) < UMBRAL_ALARMA:
			lista.append("%s por debajo de %d %%" % [ETIQUETAS[b], int(UMBRAL_ALARMA)])
	return lista

func aborto_disponible() -> bool:
	for b in ["agua", "comida", "oxigeno"]:
		if float(nave[b]) < UMBRAL_ABORTO:
			return true
	return estado("marcus") == "crítico"

# ---------------------------------------------------------------
# Aplicar efectos
# ---------------------------------------------------------------
func aplicar_efecto(efecto: Dictionary) -> void:
	for clave in efecto:
		var v = efecto[clave]
		match clave:
			"oxigeno", "agua", "comida", "electricidad", "combustible":
				_cambiar_recurso(clave, float(v))
			"temperatura":
				temperatura = clampf(temperatura + float(v), 0.0, 60.0)
			"integridad":
				integridad = clampf(integridad + float(v), 0.0, 100.0)
			"datos":
				datos = clampf(datos + float(v), 0.0, 100.0)
			"ciencia":
				ciencia = clampf(ciencia + float(v), 0.0, ciencia_max)
			"filtros":
				filtros = maxi(0, filtros + int(v))
			"reparaciones_dias":
				reparaciones_dias = clampi(reparaciones_dias + int(v), 0, 10)
			"modulo_dias":
				modulo_dias = clampi(modulo_dias + int(v), 0, 10)
			"enlace_dias":
				enlace_dias = maxi(0, int(v))
			"abortar":
				if v:
					mision_abortada = true
					ciencia = 0.0
					instrumentos = "apagados"
					instrumentos_bloqueados = true
			"forzar_final":
				forzar_final = str(v)
			_:
				_efecto_tripulacion(String(clave), float(v))

func _cambiar_recurso(nombre: String, delta: float) -> void:
	if delta > 0.0 and reparaciones_dias > 0:
		delta *= 0.8   # con las reparaciones lentas, las recuperaciones rinden 20 % menos
	elif delta < 0.0 and nombre == "combustible":
		delta *= mult_combustible   # el costo de las maniobras depende del plan
	nave[nombre] = clampf(float(nave[nombre]) + delta, 0.0, 100.0)

# Claves como "estres_todos", "salud_leo" o "confianza_leo"
func _efecto_tripulacion(clave: String, v: float) -> void:
	var partes: PackedStringArray = clave.split("_")
	if partes.size() != 2:
		return
	var stat: String = partes[0]
	var quien: String = partes[1]
	var ids: Array = []
	if quien == "todos":
		ids = vivos()
	elif tripulantes.has(quien):
		ids = [quien]
	for id in ids:
		if not esta_vivo(id):
			continue
		if not tripulantes[id].has(stat):
			continue
		tripulantes[id][stat] = clampf(float(tripulantes[id][stat]) + v, 0.0, 100.0)

# Devuelve avisos de los tripulantes que murieron desde la última vez que se llamó
func nuevas_muertes() -> Array:
	var lista: Array = []
	for id in TRIPULANTES:
		if not esta_vivo(id) and not muertes_avisadas.has(id):
			muertes_avisadas.append(id)
			lista.append("¡%s ha muerto!" % tripulantes[id]["nombre"])
	return lista

# ---------------------------------------------------------------
# Inicio de día: consumo automático y eventos por estrés
# ---------------------------------------------------------------
func procesar_inicio_dia() -> Array:
	var lineas: Array = []
	var estres_prom: float = promedio_vivos("estres")
	var factor_estres: float = 1.0 + 0.5 * maxf(0.0, (estres_prom - 40.0) / 60.0)

	# 1. Consumo de recursos: base x paquete x (1 + estrés) x (1 + daños)
	var c_agua: float = consumo_basico * factor_estres
	var c_comida: float = consumo_basico * factor_estres * float(COMIDA_RACION[racion])
	var c_oxigeno: float = consumo_basico * factor_estres
	var c_elec: float = consumo_elec * factor_estres
	if temperatura > 28.0:
		c_agua *= 1.10                                 # daño activo: refrigeración extra con calor
		c_elec *= 1.0 + 0.04 * (temperatura - 28.0)    # daño activo: radiador roto sube la electricidad
	if integridad < 60.0:
		c_oxigeno *= 1.15                              # daño activo: microfugas del casco
	if higiene_suspendida:
		c_agua *= 0.85
	c_elec += float(ELEC_INSTRUMENTOS[instrumentos])
	if modulo_dias > 0:
		c_agua += 1.5
		c_elec += 1.5                                  # sin acceso al módulo de servicio
	nave["agua"] = maxf(0.0, float(nave["agua"]) - c_agua)
	nave["comida"] = maxf(0.0, float(nave["comida"]) - c_comida)
	nave["oxigeno"] = maxf(0.0, float(nave["oxigeno"]) - c_oxigeno)
	nave["electricidad"] = maxf(0.0, float(nave["electricidad"]) - c_elec)
	lineas.append("Consumo diario: Agua -%.1f %%, Comida -%.1f %%, Oxígeno -%.1f %%, Electricidad -%.1f %%." % [c_agua, c_comida, c_oxigeno, c_elec])
	if factor_estres > 1.0:
		lineas.append("El estrés de la tripulación subió el consumo un %d %%." % roundi((factor_estres - 1.0) * 100.0))
	if modulo_dias > 0:
		lineas.append("El módulo de servicio sigue bloqueado: gastas reservas extra.")
	if reparaciones_dias > 0:
		lineas.append("Reparaciones lentas: las recuperaciones rinden 20 % menos.")

	# 2. Temperatura: vuelve despacio hacia 22 °C
	if temperatura > 22.0:
		temperatura = maxf(22.0, temperatura - 1.0)
	elif temperatura < 22.0:
		temperatura = minf(22.0, temperatura + 1.0)
	var fuera_de_zona: bool = temperatura > 28.0 or temperatura < 18.0
	if fuera_de_zona:
		lineas.append("La cabina está a %d °C, fuera de la zona segura (18-28 °C): sube el estrés y baja la salud." % roundi(temperatura))

	# 3. Instrumentos, datos y enlace con la Tierra
	if instrumentos != "apagados":
		ciencia = minf(ciencia + float(CIENCIA_DIA[instrumentos]), ciencia_max)
		datos += float(DATOS_DIA[instrumentos])
	if enlace_dias <= 0:
		datos = maxf(0.0, datos - TRANSMISION_DATOS)
	else:
		lineas.append("Sin enlace con la Tierra (%d día(s) más): la memoria de datos no se vacía." % enlace_dias)
	if datos >= 100.0:
		datos = 100.0
		if instrumentos != "apagados":
			instrumentos = "apagados"
			lineas.append("Memoria de datos llena: los instrumentos se apagaron solos.")

	# 4. Cambios diarios de cada tripulante
	var avisos_hambre: Array = []
	for id in vivos():
		var t: Dictionary = tripulantes[id]
		t["estres"] = float(t["estres"]) + estres_base
		if higiene_suspendida:
			t["estres"] = float(t["estres"]) + ESTRES_AISLAMIENTO_HIGIENE
		t["hambre"] = clampf(float(t["hambre"]) + float(HAMBRE_RACION[racion]), 0.0, 100.0)
		if float(nave["comida"]) <= 0.0:
			t["hambre"] = clampf(float(t["hambre"]) + 15.0, 0.0, 100.0)
			t["salud"] = float(t["salud"]) - 15.0
		if float(t["hambre"]) > 70.0:
			t["salud"] = float(t["salud"]) - 2.0
			avisos_hambre.append(NOMBRES_TRIPULANTE[id])
		if float(t["estres"]) > 80.0:
			t["salud"] = float(t["salud"]) - 2.0
		if fuera_de_zona:
			t["estres"] = float(t["estres"]) + 3.0
			t["salud"] = float(t["salud"]) - 2.0
		if filtros <= 0:
			t["salud"] = float(t["salud"]) - 3.0
		t["estres"] = clampf(float(t["estres"]), 0.0, 100.0)
		t["salud"] = clampf(float(t["salud"]), 0.0, 100.0)
	if float(nave["comida"]) <= 0.0:
		lineas.append("Sin comida: la tripulación pierde 15 puntos de salud por día.")
	elif not avisos_hambre.is_empty():
		lineas.append("El hambre pasa de 70 %% y resta salud a: %s." % ", ".join(avisos_hambre))
	if filtros <= 0:
		lineas.append("Sin cartuchos de CO2 de reserva: el aire empeora y baja la salud de todos.")

	# 5. Eventos por estrés (cada tripulante tira un dado según su nivel)
	for id in vivos():
		var texto: String = _evento_estres(id)
		if texto != "":
			lineas.append(texto)

	for aviso in nuevas_muertes():
		lineas.append(aviso)
	return lineas

# Reacciones por carácter y nivel de estrés (propuestas del documento: sección 4)
# nivel 1 = tenso (40-69, 25 %), nivel 2 = quebrado (70-89, 35 %), nivel 3 = crítico (90-100, 50 %)
const REACCIONES: Dictionary = {
	"marcus": [
		{"texto": "Marcus calibra mal un sensor y hay que repetir mediciones.", "efecto": {"datos": -4, "electricidad": -2}},
		{"texto": "Marcus, rígido, recorta energía sin avisar y baja la moral de los demás.", "efecto": {"electricidad": 3, "estres_todos": 4}},
		{"texto": "Marcus apaga un sistema por su cuenta y se lesiona al forzar un panel.", "efecto": {"electricidad": -6, "salud_marcus": -8, "estres_todos": 4}},
	],
	"sofia": [
		{"texto": "Sofía cierra mal una válvula de agua.", "efecto": {"agua": -3}},
		{"texto": "Sofía se sobrecarga y comete un error de dosificación.", "efecto": {"salud_todos": -3}},
		{"texto": "Sofía, agotada, comete un error médico grave.", "efecto": {"salud_todos": -6, "estres_sofia": 5}},
	],
	"leo": [
		{"texto": "Leo calibra mal un instrumento.", "efecto": {"ciencia": -2, "datos": 3}},
		{"texto": "Leo enciende instrumentos por su cuenta y gasta electricidad y memoria.", "efecto": {"electricidad": -4, "datos": 8}},
		{"texto": "Leo enciende todo y fuerza el equipo; se lesiona por descuido.", "efecto": {"electricidad": -7, "datos": 12, "salud_leo": -6}},
	],
	"elena": [
		{"texto": "Elena duda y retrasa una decisión: tendrás 3 segundos menos mañana.", "efecto": {}},
		{"texto": "Elena retrasa decisiones y la tripulación lo nota.", "efecto": {"estres_todos": 3}},
		{"texto": "Elena toma decisiones por su cuenta y deja a todos nerviosos.", "efecto": {"estres_todos": 5}},
	],
}

func _evento_estres(id: String) -> String:
	var e: float = float(tripulantes[id]["estres"])
	var nivel: int = 0
	var prob: float = 0.0
	if e >= 90.0:
		nivel = 3
		prob = 0.5
	elif e >= 70.0:
		nivel = 2
		prob = 0.35
	elif e >= 40.0:
		nivel = 1
		prob = 0.25
	if nivel == 0 or rng.randf() >= prob:
		return ""
	var r: Dictionary = REACCIONES[id][nivel - 1]
	var efecto: Dictionary = r["efecto"].duplicate()
	if id == "sofia":
		for otro in vivos():
			if otro != "sofia" and estado(otro) != "activo":
				for k in efecto:
					efecto[k] = efecto[k] * 2   # Sofía se sobrecarga cuando hay heridos
				break
	aplicar_efecto(efecto)
	if id == "elena":
		penal_tiempo += 3.0
	if nivel >= 2 and id != "elena":
		tripulantes[id]["confianza"] = maxf(0.0, float(tripulantes[id]["confianza"]) - 8.0)
	var etiqueta: String = ["tenso", "quebrado", "crítico"][nivel - 1]
	return "Estrés %s: %s" % [etiqueta, r["texto"]]

# ---------------------------------------------------------------
# Elegir la decisión del día
# ---------------------------------------------------------------
# numero 1: hito del día o evento de nave | numero 2: obtener o ahorrar un recurso
func elegir_decision(numero: int) -> Dictionary:
	var d: Dictionary = {}
	if numero == 1:
		d = Eventos.hito_del_dia(dia_actual)
		if d.is_empty():
			d = _sortear("nave")
	else:
		d = _sortear("recursos")
	if not d.is_empty():
		var id: String = d["id"]
		veces[id] = int(veces.get(id, 0)) + 1
		hoy_ids.append(id)
		gravedad_hoy = maxi(gravedad_hoy, int(d["gravedad"]))
	return d

func _sin_gravedad_3() -> bool:
	var n: int = gravedad_dias.size()
	return n >= 2 and int(gravedad_dias[n - 1]) >= 3 and int(gravedad_dias[n - 2]) >= 3

func _sortear(categoria: String) -> Dictionary:
	var candidatas: Array = []
	var pesos: Array = []
	var total: float = 0.0
	var prohibir_g3: bool = _sin_gravedad_3()
	for d in Eventos.banco:
		if d["categoria"] != categoria:
			continue
		if dia_actual < int(d["dia_min"]) or dia_actual > int(d["dia_max"]):
			continue
		var id: String = d["id"]
		if ayer_ids.has(id) or hoy_ids.has(id):
			continue
		var usos: int = int(veces.get(id, 0))
		if usos >= 2:
			continue
		if prohibir_g3 and int(d["gravedad"]) >= 3:
			continue
		var w: float = 1.0
		var foco: String = String(d["foco"])
		if foco != "" and float(nave[foco]) < 40.0:
			w *= 2.0 if categoria == "recursos" else 1.5   # el estado hace la decisión más lógica
		if usos >= 1:
			w *= 0.3
		candidatas.append(d)
		pesos.append(w)
		total += w
	if candidatas.is_empty():
		return {}
	var r: float = rng.randf() * total
	for i in candidatas.size():
		r -= float(pesos[i])
		if r <= 0.0:
			return candidatas[i]
	return candidatas[candidatas.size() - 1]

# ---------------------------------------------------------------
# Resolver una decisión
# ---------------------------------------------------------------
func tier_de_p(p: float) -> String:
	if p >= P_BUENO:
		return "bueno"
	if p >= P_MALO:
		return "intermedio"
	return "malo"

func _cumple(m: Dictionary) -> bool:
	var a: float = valor_estado(String(m["v"]))
	var x: float = float(m["x"])
	match String(m["op"]):
		"<":
			return a < x
		">":
			return a > x
		"<=":
			return a <= x
		">=":
			return a >= x
	return is_equal_approx(a, x)

func _texto_mod(m: Dictionary) -> String:
	var nombre: String = String(NOMBRE_VAR.get(m["v"], m["v"]))
	var peso: float = float(m["m"])
	var signo: String = ("+" if peso > 0.0 else "") + str(peso)
	if String(m["op"]) == "==":
		return "%s (%s)" % [nombre, signo]
	return "%s %s %d (%s)" % [nombre, NOMBRE_OP[String(m["op"])], int(m["x"]), signo]

# Puntaje de una opción. "detalle" recibe los factores del estado que pesaron.
func calcular_p(decision: Dictionary, opcion: Dictionary, con_ruido: bool, detalle: Array) -> float:
	var p: float = V_TRAMPA if opcion.get("trampa", false) else V_NORMAL
	for m in opcion.get("mods", []):
		if _cumple(m):
			p += float(m["m"])
			detalle.append("Estado de la nave: " + _texto_mod(m))
	var resp: String = String(decision.get("responsable", ""))
	if tripulantes.has(resp) and esta_vivo(resp):
		var nombre: String = String(NOMBRES_TRIPULANTE[resp])
		if estado(resp) == "activo":
			p += BONO_ESPECIALISTA
			detalle.append("%s, el especialista del tema, está en condiciones de actuar (+0.2)." % nombre)
		else:
			detalle.append("%s, el especialista del tema, está %s y no puede ayudar." % [nombre, estado(resp)])
		if float(tripulantes[resp]["estres"]) > 70.0:
			p -= PENAL_ESTRES
			detalle.append("%s está muy estresado (-0.2)." % nombre)
	elif tripulantes.has(resp):
		detalle.append("El especialista del tema ya no está vivo.")
	if con_ruido:
		if is_nan(habilidad_manual):
			p += rng.randf_range(-RUIDO, RUIDO)
		else:
			# La habilidad del jugador en el minijuego ocupa el lugar del azar (mismo rango: -RUIDO a +RUIDO)
			p += habilidad_manual * RUIDO
			detalle.append("Tu reparación manual pesó %s en el resultado." % signo(habilidad_manual * RUIDO))
	return p

func _valor_fijo(tier: String) -> float:
	if tier == "bueno":
		return 1.0
	if tier == "intermedio":
		return 0.0
	return -1.0

func texto_efecto(efecto: Dictionary) -> String:
	var partes: Array = []
	for k in efecto:
		if k == "abortar":
			partes.append("se suelta la carga científica")
		elif k == "forzar_final":
			partes.append("final forzado")
		else:
			partes.append("%s %s" % [_etiqueta_efecto(String(k)), signo(float(efecto[k]))])
	if partes.is_empty():
		return "sin cambios"
	return ", ".join(partes)

func _etiqueta_efecto(clave: String) -> String:
	if ETIQUETAS.has(clave):
		return String(ETIQUETAS[clave])
	var partes: PackedStringArray = clave.split("_")
	if partes.size() == 2 and ETIQUETA_STAT.has(partes[0]) and NOMBRES_TRIPULANTE.has(partes[1]):
		return "%s de %s" % [ETIQUETA_STAT[partes[0]], NOMBRES_TRIPULANTE[partes[1]]]
	return clave

func signo(v: float) -> String:
	var r: float = snappedf(v, 0.1)
	if absf(r - roundf(r)) < 0.05:
		var n: int = int(roundf(r))
		return ("+" if n > 0 else "") + str(n)
	return ("+" if r > 0.0 else "") + ("%.1f" % r)

# El responsable actúa por protocolo cuando se acaba el tiempo: la opción de mayor puntaje esperado
func _mejor_opcion(decision: Dictionary) -> int:
	var mejor: int = 0
	var mejor_p: float = -99.0
	var opciones: Array = decision["opciones"]
	var disponible: bool = aborto_disponible()
	for i in opciones.size():
		var o: Dictionary = opciones[i]
		if o.get("requiere_aborto", false) and not disponible:
			continue
		var p: float = 0.0
		if o.has("tier_fijo"):
			p = _valor_fijo(String(o["tier_fijo"]))
		else:
			p = calcular_p(decision, o, false, [])
		if p > mejor_p:
			mejor_p = p
			mejor = i
	return mejor

# Devuelve: opcion, tier, p, cambios, factores, alternativas, nota, muertes
func resolver(decision: Dictionary, indice: int, por_tiempo: bool) -> Dictionary:
	var opciones: Array = decision["opciones"]
	var resp: String = String(decision.get("responsable", ""))
	var idx: int = indice
	var tier: String = ""
	var nota: String = ""
	var disponible_aborto: bool = aborto_disponible()

	if por_tiempo:
		nota = "Se agotó el tiempo: la tripulación actuó por su cuenta (lo hizo %s). La confianza en Elena baja." % NOMBRES_TRIPULANTE.get(resp, "el equipo")
		if String(decision.get("categoria", "")) == "hito":
			# Decisión de la historia (resultado fijo): la tripulación elige una opción normal al azar
			var normales: Array = []
			for i in opciones.size():
				if not opciones[i].get("requiere_aborto", false):
					normales.append(i)
			idx = int(normales[rng.randi_range(0, normales.size() - 1)])
		else:
			# El responsable actúa por protocolo, pero casi siempre con resultado intermedio o malo
			idx = _mejor_opcion(decision)
			tier = "intermedio" if rng.randf() < 0.65 else "malo"
	elif tripulantes.has(resp) and esta_vivo(resp) and float(tripulantes[resp]["confianza"]) < 30.0 and rng.randf() < 0.4:
		var otras: Array = []
		for i in opciones.size():
			var o2: Dictionary = opciones[i]
			if i != idx and not (o2.get("requiere_aborto", false) and not disponible_aborto):
				otras.append(i)
		if not otras.is_empty():
			idx = int(otras[rng.randi_range(0, otras.size() - 1)])
			nota = "%s ya no confía en tu mando (confianza menor a 30 %%) e ignoró tu orden: actuó por su cuenta." % NOMBRES_TRIPULANTE[resp]

	var opcion: Dictionary = opciones[idx]
	var factores: Array = []
	var p: float = 0.0
	if opcion.has("tier_fijo"):
		tier = String(opcion["tier_fijo"])
		p = _valor_fijo(tier)
		factores.append("En esta decisión de la historia el resultado depende solo de la opción elegida.")
	elif tier == "":
		p = calcular_p(decision, opcion, true, factores)
		tier = tier_de_p(p)
	else:
		p = calcular_p(decision, opcion, false, factores)

	# Si la opción elegida no tiene ese nivel de resultado (hitos), se usa el que tenga
	var resultados: Dictionary = opcion["resultados"]
	if not resultados.has(tier):
		tier = String(resultados.keys()[0])

	# Qué habría pasado con las otras opciones (sin tirar un dado nuevo)
	var alternativas: Array = []
	for i in opciones.size():
		if i == idx:
			continue
		var o: Dictionary = opciones[i]
		if o.get("requiere_aborto", false) and not disponible_aborto:
			continue
		var t: String = ""
		if o.has("tier_fijo"):
			t = String(o["tier_fijo"])
		else:
			t = tier_de_p(calcular_p(decision, o, false, []))
		var efecto_alt: Dictionary = o["resultados"].get(t, {})
		alternativas.append("%s: %s (%s)" % [o["texto"], t.to_upper(), texto_efecto(efecto_alt)])

	var antes: Dictionary = instantanea()
	if por_tiempo:
		for id in vivos():
			tripulantes[id]["confianza"] = maxf(0.0, float(tripulantes[id]["confianza"]) - 8.0)
	aplicar_efecto(resultados[tier])
	if decision.get("ruta_aborto", false) and disponible_aborto and not opcion.get("requiere_aborto", false):
		aplicar_efecto(decision["penal_ruta_aborto"])
		factores.append("Con las reservas en rojo no soltaste la carga: el combustible y la energía no alcanzan en el tránsito de vuelta.")

	if tripulantes.has(resp) and esta_vivo(resp):
		if tier == "bueno":
			tripulantes[resp]["confianza"] = minf(100.0, float(tripulantes[resp]["confianza"]) + 3.0)
		elif tier == "malo":
			tripulantes[resp]["confianza"] = maxf(0.0, float(tripulantes[resp]["confianza"]) - 5.0)
	decisiones_totales += 1
	if tier == "bueno":
		decisiones_buenas += 1
	habilidad_manual = NAN
	var despues: Dictionary = instantanea()

	return {
		"opcion": opcion, "tier": tier, "p": p,
		"cambios": describir_cambios(antes, despues),
		"factores": factores, "alternativas": alternativas,
		"nota": nota, "muertes": nuevas_muertes(),
	}

# ---------------------------------------------------------------
# Instantáneas y resumen de cambios
# ---------------------------------------------------------------
func instantanea() -> Dictionary:
	var s: Dictionary = {}
	for k in nave:
		s[k] = float(nave[k])
	s["temperatura"] = temperatura
	s["integridad"] = integridad
	s["datos"] = datos
	s["ciencia"] = ciencia
	s["filtros"] = float(filtros)
	for id in TRIPULANTES:
		for stat in ["salud", "estres", "hambre", "confianza"]:
			s[stat + "_" + id] = float(tripulantes[id][stat])
	return s

func describir_cambios(antes: Dictionary, despues: Dictionary) -> Array:
	var lineas: Array = []
	var orden: Array = [["agua", "Agua", " %"], ["comida", "Comida", " %"], ["oxigeno", "Oxígeno", " %"],
		["electricidad", "Electricidad", " %"], ["combustible", "Combustible", " %"], ["integridad", "Integridad", " %"],
		["datos", "Datos", " %"], ["ciencia", "Progreso científico", " %"], ["temperatura", "Temperatura", " °C"],
		["filtros", "Filtros de CO2", ""]]
	for o in orden:
		var d: float = float(despues[o[0]]) - float(antes[o[0]])
		if absf(d) >= 0.5:
			lineas.append("%s %s%s" % [o[1], signo(d), o[2]])
	for stat in ["salud", "estres", "hambre", "confianza"]:
		var no_cero: Array = []
		var valores: Array = []
		for id in TRIPULANTES:
			var d2: float = roundf(float(despues[stat + "_" + id]) - float(antes[stat + "_" + id]))
			if d2 != 0.0:
				no_cero.append(id)
				valores.append(d2)
		if no_cero.is_empty():
			continue
		var todos_iguales: bool = true
		for v in valores:
			if v != valores[0]:
				todos_iguales = false
		if todos_iguales and no_cero.size() >= 2 and no_cero.size() == vivos().size():
			lineas.append("%s (todos) %s" % [ETIQUETA_STAT[stat], signo(float(valores[0]))])
		else:
			var partes: Array = []
			for i in no_cero.size():
				partes.append("%s %s" % [NOMBRES_TRIPULANTE[no_cero[i]], signo(float(valores[i]))])
			lineas.append("%s: %s" % [ETIQUETA_STAT[stat], ", ".join(partes)])
	return lineas

func cerrar_dia() -> void:
	gravedad_dias.append(gravedad_hoy)
	gravedad_hoy = 0
	ayer_ids = hoy_ids.duplicate()
	hoy_ids = []
	reparaciones_dias = maxi(0, reparaciones_dias - 1)
	modulo_dias = maxi(0, modulo_dias - 1)
	enlace_dias = maxi(0, enlace_dias - 1)

# ---------------------------------------------------------------
# Finales y puntuación
# ---------------------------------------------------------------
func hay_final_inmediato() -> bool:
	return forzar_final != "" or barra_en_cero() or vivos().is_empty()

# Devuelve "bueno", "intermedio" o "malo"
func evaluar_final() -> String:
	if forzar_final != "":
		return forzar_final
	if barra_en_cero() or vivos().is_empty():
		return "malo"
	if integridad <= INTEGRIDAD_REENTRADA:
		return "malo"
	if mision_abortada or vivos().size() < TRIPULANTES.size() or ciencia < CIENCIA_FINAL_BUENO:
		return "intermedio"
	for b in nave:
		if float(nave[b]) <= UMBRAL_FINAL_BUENO:
			return "intermedio"
	return "bueno"

# Puntuación de 0 a 1000
func puntaje() -> Dictionary:
	var sup: float = 0.0
	for id in TRIPULANTES:
		if esta_vivo(id):
			sup += float(tripulantes[id]["salud"])
	var rec: float = (float(nave["agua"]) + float(nave["comida"]) + float(nave["oxigeno"]) + float(nave["electricidad"])) / 4.0
	var dec: float = 150.0 * float(decisiones_buenas) / float(maxi(decisiones_totales, 1))
	var coh: float = promedio_vivos("confianza") * 0.5
	var r: Dictionary = {
		"supervivencia": sup,
		"ciencia": ciencia * 2.5,
		"recursos": rec * 1.5,
		"decisiones": dec,
		"cohesion": coh,
	}
	r["total"] = r["supervivencia"] + r["ciencia"] + r["recursos"] + r["decisiones"] + r["cohesion"]
	return r
