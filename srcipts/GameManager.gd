extends Node

const DIAS_TOTALES: int = 14
const NIVEL_BASE: int = 60
const REDUCCION_DANO: float = 0.4

var presupuesto_inicial: int = 100000
var presupuesto: int = 100000
var capacidad_base: float = 226.8

var dia_actual: int = 1
var nave: Dictionary = {}
var extras: Dictionary = {}
var tripulantes: Dictionary = {}
var muestras_recolectadas: bool = false
var mision_abortada: bool = false
var forzar_final: String = ""

# --- TIENDA (números de ejemplo: el ingeniero industrial los ajustará) ---
var suministros: Array = [
	{"id": "agua", "nombre": "Agua potable (+10%, 16,2 L)", "barra": "agua", "costo": 2000, "masa": 16.2, "aporte": 10, "max": 4},
	{"id": "comida", "nombre": "Alimentos liofilizados (+10%)", "barra": "comida", "costo": 2500, "masa": 8.0, "aporte": 10, "max": 4},
	{"id": "oxigeno", "nombre": "Tanque de oxígeno (+10%)", "barra": "oxigeno", "costo": 3000, "masa": 6.0, "aporte": 10, "max": 4},
	{"id": "baterias", "nombre": "Baterías de reserva (+10%)", "barra": "electricidad", "costo": 3500, "masa": 10.0, "aporte": 10, "max": 4},
]

var mejoras: Array = [
	{"id": "modulo_carga", "nombre": "Módulo de carga ampliado", "costo": 12000, "masa": 0.0, "capacidad_extra": 60.0, "protege": "", "efecto": "+60 kg de capacidad de carga"},
	{"id": "blindaje", "nombre": "Blindaje contra radiación", "costo": 10000, "masa": 30.0, "capacidad_extra": 0.0, "protege": "radiacion", "efecto": "Reduce 40% el daño por tormentas solares"},
	{"id": "casco", "nombre": "Casco reforzado anti-micrometeoritos", "costo": 12000, "masa": 40.0, "capacidad_extra": 0.0, "protege": "casco", "efecto": "Reduce 40% el daño por fugas y daño estructural"},
	{"id": "aislamiento", "nombre": "Bus eléctrico redundante", "costo": 8000, "masa": 15.0, "capacidad_extra": 0.0, "protege": "energia", "efecto": "Reduce 40% el daño por fallas eléctricas"},
	{"id": "botiquin", "nombre": "Botiquín médico avanzado", "costo": 6000, "masa": 10.0, "capacidad_extra": 0.0, "protege": "medico", "efecto": "Reduce 40% el daño por lesiones"},
	{"id": "radiadores", "nombre": "Radiadores de alta capacidad", "costo": 7000, "masa": 20.0, "capacidad_extra": 0.0, "protege": "termico", "efecto": "Reduce 40% el daño por sobrecalentamiento"},
	{"id": "reciclador", "nombre": "Reciclador de agua mejorado", "costo": 7000, "masa": 25.0, "capacidad_extra": 0.0, "protege": "agua", "efecto": "Reduce 40% el daño por escasez de agua"},
	{"id": "filtros", "nombre": "Filtros de CO2 de respaldo", "costo": 5000, "masa": 10.0, "capacidad_extra": 0.0, "protege": "co2", "efecto": "Reduce 40% el daño por acumulación de CO2"},
	{"id": "antena", "nombre": "Antena de respaldo", "costo": 5000, "masa": 8.0, "capacidad_extra": 0.0, "protege": "comunicaciones", "efecto": "Reduce 40% el daño por pérdida de comunicación"},
]

var compras_suministros: Dictionary = {}
var mejoras_compradas: Array = []

func nueva_partida() -> void:
	presupuesto = presupuesto_inicial
	compras_suministros = {}
	mejoras_compradas = []
	dia_actual = 1
	nave = {"agua": NIVEL_BASE, "comida": NIVEL_BASE, "oxigeno": NIVEL_BASE, "electricidad": NIVEL_BASE}
	extras = {"salud_sistemas": 100, "ciencia": 0, "riesgo_estructural": 0, "riesgo_aborto": 0, "riesgo_catastrofico": 0}
	tripulantes = {
		"elena": {"nombre": "Elena Marín", "rol": "Comandante y Piloto", "hambre": 0, "estres": 0, "salud": 100},
		"marcus": {"nombre": "Marcus Chen", "rol": "Ingeniero de Sistemas", "hambre": 0, "estres": 0, "salud": 100},
		"sofia": {"nombre": "Dra. Sofía Reyes", "rol": "Médica y Bióloga", "hambre": 0, "estres": 0, "salud": 100},
		"leo": {"nombre": "Leo Okafor", "rol": "Ingeniero mecánico", "hambre": 0, "estres": 0, "salud": 100},
	}
	muestras_recolectadas = false
	mision_abortada = false
	forzar_final = ""

func buscar_en(lista: Array, id: String) -> Dictionary:
	for item in lista:
		if item["id"] == id:
			return item
	return {}

func masa_usada() -> float:
	var total: float = 0.0
	for id in compras_suministros:
		total += buscar_en(suministros, id)["masa"] * compras_suministros[id]
	for id in mejoras_compradas:
		total += buscar_en(mejoras, id)["masa"]
	return total

func capacidad_total() -> float:
	var total: float = capacidad_base
	for id in mejoras_compradas:
		total += buscar_en(mejoras, id)["capacidad_extra"]
	return total

# Devuelve "" si salió bien, o el motivo del error
func comprar_suministro(id: String) -> String:
	var s: Dictionary = buscar_en(suministros, id)
	if s.is_empty():
		return "Suministro no encontrado."
	var cantidad: int = compras_suministros.get(id, 0)
	if cantidad >= s["max"]:
		return "Ya compraste el máximo de este suministro."
	if presupuesto < s["costo"]:
		return "No tienes presupuesto suficiente."
	if masa_usada() + s["masa"] > capacidad_total():
		return "Orion no tiene capacidad de carga para esto."
	presupuesto -= s["costo"]
	compras_suministros[id] = cantidad + 1
	return ""

func quitar_suministro(id: String) -> void:
	var cantidad: int = compras_suministros.get(id, 0)
	if cantidad <= 0:
		return
	presupuesto += buscar_en(suministros, id)["costo"]
	compras_suministros[id] = cantidad - 1

func comprar_mejora(id: String) -> String:
	var m: Dictionary = buscar_en(mejoras, id)
	if m.is_empty():
		return "Mejora no encontrada."
	if id in mejoras_compradas:
		return "Ya tienes esta mejora."
	if presupuesto < m["costo"]:
		return "No tienes presupuesto suficiente."
	if masa_usada() + m["masa"] > capacidad_total() + m["capacidad_extra"]:
		return "Orion no tiene capacidad de carga para esto."
	presupuesto -= m["costo"]
	mejoras_compradas.append(id)
	return ""

func vender_mejora(id: String) -> String:
	if not (id in mejoras_compradas):
		return ""
	var m: Dictionary = buscar_en(mejoras, id)
	if masa_usada() - m["masa"] > capacidad_total() - m["capacidad_extra"]:
		return "Si quitas esto, la carga excedería la capacidad. Quita antes otros elementos."
	presupuesto += m["costo"]
	mejoras_compradas.erase(id)
	return ""

func nivel_inicial(barra: String) -> int:
	var nivel: int = NIVEL_BASE
	for s in suministros:
		if s["barra"] == barra:
			nivel += s["aporte"] * compras_suministros.get(s["id"], 0)
	return mini(nivel, 100)

# Se llama al terminar la tienda: las compras definen el nivel con que despega la nave
func iniciar_mision() -> void:
	for barra in nave:
		nave[barra] = nivel_inicial(barra)
	dia_actual = 1

func esta_protegido(categoria: String) -> bool:
	if categoria == "":
		return false
	for id in mejoras_compradas:
		if buscar_en(mejoras, id)["protege"] == categoria:
			return true
	return false

# --- MISIÓN ---

# Reduce el daño si la nave tiene la mejora que protege esa categoría de emergencia
func _proteger(clave: String, valor: int, categoria: String) -> int:
	var es_dano: bool = (valor > 0) if clave.begins_with("riesgo") else (valor < 0)
	if es_dano and esta_protegido(categoria):
		return roundi(valor * (1.0 - REDUCCION_DANO))
	return valor

# Ejemplo de efecto:
# {"nave": {"electricidad": -25}, "tripulacion": {"leo": {"estres": 10}, "todos": {"salud": -20}}}
func aplicar_efecto(efecto: Dictionary, categoria: String = "") -> void:
	var cambios_nave: Dictionary = efecto.get("nave", {})
	for clave in cambios_nave:
		var cambio: int = _proteger(clave, cambios_nave[clave], categoria)
		if nave.has(clave):
			nave[clave] = clampi(nave[clave] + cambio, 0, 100)
		elif extras.has(clave):
			extras[clave] = clampi(extras[clave] + cambio, 0, 100)

	var cambios_tripulacion: Dictionary = efecto.get("tripulacion", {})
	for quien in cambios_tripulacion:
		var ids: Array = tripulantes.keys() if quien == "todos" else [quien]
		for id in ids:
			for stat in cambios_tripulacion[quien]:
				var cambio: int = cambios_tripulacion[quien][stat]
				if stat == "salud":
					cambio = _proteger("salud", cambio, categoria)
				tripulantes[id][stat] = clampi(tripulantes[id][stat] + cambio, 0, 100)

	if efecto.has("muestras"):
		muestras_recolectadas = efecto["muestras"]
	if efecto.has("abortar"):
		mision_abortada = efecto["abortar"]
	if efecto.has("forzar_final"):
		forzar_final = efecto["forzar_final"]

func esta_vivo(id: String) -> bool:
	return tripulantes[id]["salud"] > 0

func tripulantes_vivos() -> int:
	var total: int = 0
	for id in tripulantes:
		if esta_vivo(id):
			total += 1
	return total

func barra_en_cero() -> bool:
	for b in nave:
		if nave[b] <= 0:
			return true
	return false

func hay_final_inmediato() -> bool:
	return forzar_final != "" or barra_en_cero() or tripulantes_vivos() == 0

# Devuelve "bueno", "intermedio" o "malo"
func evaluar_final() -> String:
	if forzar_final != "":
		return forzar_final
	if barra_en_cero() or tripulantes_vivos() == 0:
		return "malo"
	if mision_abortada or tripulantes_vivos() < 4 or not muestras_recolectadas:
		return "intermedio"
	for b in nave:
		if nave[b] <= 15:
			return "intermedio"
	return "bueno"

func _ready():
	nueva_partida()
