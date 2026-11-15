extends Control
# Pantalla de la misión. Ciclo de cada día:
# 1) configurar la nave (ración, instrumentos, higiene)  2) consumo automático y eventos por estrés
# 3) decisión 1 (hito o emergencia de nave) con temporizador  4) decisión 2 (recursos) con temporizador
# 5) resumen del día.  Después de cada decisión se muestra la explicación en tres capas.

const BARRAS_NAVE: Array = [
	["agua", "Agua"], ["comida", "Comida"], ["oxigeno", "Oxígeno"], ["electricidad", "Electricidad"],
	["combustible", "Combustible"], ["integridad", "Integridad"], ["datos", "Datos"], ["ciencia", "Ciencia"],
]
const RACIONES: Array = ["completa", "reducida", "minima"]
const NOMBRES_RACION: Array = ["Completa", "Reducida", "Mínima"]
const INSTRUMENTOS: Array = ["apagados", "basicos", "todos"]
const NOMBRES_INSTRUMENTOS: Array = ["Apagados", "Básicos", "Todos"]
const NOMBRES_HIGIENE: Array = ["Normal", "Suspendida"]
const TIER_TEXTO: Dictionary = {"bueno": "BUENO", "intermedio": "INTERMEDIO", "malo": "MALO"}
const ROJO: Color = Color(1.0, 0.4, 0.4)
const BLANCO: Color = Color(1.0, 1.0, 1.0)

const TITULOS_FINAL: Dictionary = {
	"bueno": "FINAL BUENO: MISIÓN CUMPLIDA",
	"intermedio": "FINAL INTERMEDIO: MISIÓN ABORTADA",
	"malo": "FINAL MALO: SILENCIO TOTAL",
}
const NARRATIVA_FINAL: Dictionary = {
	"bueno": "Los paracaídas de la Orión se despliegan sobre el océano Pacífico. Elena, Marcus, Sofía y Leo regresan como héroes.",
	"intermedio": "La cápsula ameriza entre silencio radiofónico. Están vivos, pero la ciencia fracasó y el costo humano los acompañará siempre.",
	"malo": "La Orión queda a la deriva en órbita silenciosa. En Houston, la línea de telemetría se vuelve plana bajo un último registro: MYG-351: Last Signal.",
}

var barras: Dictionary = {}
var nombres_barra: Dictionary = {}
var paneles_tripulante: Dictionary = {}
var etiqueta_ambiente: Label
var etiqueta_alarma: Label

var titulo_dia: Label
var etiqueta_registro: Label
var panel_config: VBoxContainer
var sel_racion: OptionButton
var sel_instrumentos: OptionButton
var sel_higiene: OptionButton

var panel_decision: VBoxContainer
var etiqueta_tema: Label
var texto_situacion: Label
var barra_tiempo: ProgressBar
var etiqueta_tiempo: Label
var zona_opciones: VBoxContainer

var panel_feedback: VBoxContainer
var texto_feedback: Label
var boton_continuar: Button

var panel_final: VBoxContainer
var texto_final: Label

var fase: String = "config"
var numero_decision: int = 1
var decision_actual: Dictionary = {}
var tiempo_total: float = 0.0
var tiempo_restante: float = 0.0
var snap_dia: Dictionary = {}
var siguiente: String = ""

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var raiz = HBoxContainer.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 12)
	add_child(raiz)
	raiz.add_child(_construir_hud())
	raiz.add_child(_construir_principal())
	_mostrar_config()

# ---------------------------------------------------------------
# Construcción de la interfaz
# ---------------------------------------------------------------
func _texto(padre: Control, texto: String) -> Label:
	var l = Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(l)
	return l

func _scroll(ratio: float) -> ScrollContainer:
	var s = ScrollContainer.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_stretch_ratio = ratio
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return s

func _construir_hud() -> ScrollContainer:
	var scroll = _scroll(1.0)
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	_texto(col, "NAVE ORION")
	for b in BARRAS_NAVE:
		var fila = HBoxContainer.new()
		col.add_child(fila)
		var nombre = Label.new()
		nombre.text = b[1]
		nombre.custom_minimum_size = Vector2(130, 0)
		fila.add_child(nombre)
		var pb = ProgressBar.new()
		pb.max_value = 100.0
		pb.custom_minimum_size = Vector2(0, 20)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(pb)
		barras[b[0]] = pb
		nombres_barra[b[0]] = nombre
	etiqueta_ambiente = _texto(col, "")
	etiqueta_alarma = _texto(col, "")
	etiqueta_alarma.modulate = ROJO

	col.add_child(HSeparator.new())
	_texto(col, "TRIPULACIÓN")
	for id in GameManager.TRIPULANTES:
		var caja = VBoxContainer.new()
		col.add_child(caja)
		var titulo = _texto(caja, "")
		var salud = ProgressBar.new()
		salud.max_value = 100.0
		salud.custom_minimum_size = Vector2(0, 16)
		caja.add_child(salud)
		var stats = _texto(caja, "")
		paneles_tripulante[id] = {"titulo": titulo, "salud": salud, "stats": stats}
		col.add_child(HSeparator.new())
	return scroll

func _selector(padre: Control, nombre: String, opciones: Array) -> OptionButton:
	var fila = HBoxContainer.new()
	padre.add_child(fila)
	var l = Label.new()
	l.text = nombre
	l.custom_minimum_size = Vector2(150, 0)
	fila.add_child(l)
	var ob = OptionButton.new()
	for o in opciones:
		ob.add_item(String(o))
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(ob)
	return ob

func _construir_principal() -> ScrollContainer:
	var scroll = _scroll(1.7)
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	titulo_dia = _texto(col, "")
	etiqueta_registro = _texto(col, "")

	# Configuración diaria
	panel_config = VBoxContainer.new()
	col.add_child(panel_config)
	_texto(panel_config, "CONFIGURA LA NAVE PARA HOY")
	sel_racion = _selector(panel_config, "Ración de comida", NOMBRES_RACION)
	sel_instrumentos = _selector(panel_config, "Instrumentos científicos", NOMBRES_INSTRUMENTOS)
	sel_higiene = _selector(panel_config, "Higiene", NOMBRES_HIGIENE)
	var ayuda = _texto(panel_config, "Ración reducida: comida x0,8 y hambre +5 por día; mínima: x0,6 y +12 (completa: hambre -5). Instrumentos básicos: +1 % de electricidad, +2,5 de ciencia y +4 de datos por día; todos: +2, +5 y +8. Los datos solo se vacían (-10 por día) si hay enlace con la Tierra. Suspender la higiene ahorra agua pero sube el estrés 3 puntos por día.")
	ayuda.modulate = Color(0.75, 0.75, 0.75)
	var iniciar = Button.new()
	iniciar.text = "INICIAR EL DÍA"
	iniciar.custom_minimum_size = Vector2(0, 44)
	iniciar.pressed.connect(_on_iniciar_dia)
	panel_config.add_child(iniciar)

	# Decisión
	panel_decision = VBoxContainer.new()
	panel_decision.add_theme_constant_override("separation", 8)
	col.add_child(panel_decision)
	etiqueta_tema = _texto(panel_decision, "")
	texto_situacion = _texto(panel_decision, "")
	var fila_tiempo = HBoxContainer.new()
	panel_decision.add_child(fila_tiempo)
	barra_tiempo = ProgressBar.new()
	barra_tiempo.show_percentage = false
	barra_tiempo.custom_minimum_size = Vector2(0, 18)
	barra_tiempo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_tiempo.add_child(barra_tiempo)
	etiqueta_tiempo = Label.new()
	etiqueta_tiempo.custom_minimum_size = Vector2(90, 0)
	fila_tiempo.add_child(etiqueta_tiempo)
	zona_opciones = VBoxContainer.new()
	zona_opciones.add_theme_constant_override("separation", 6)
	panel_decision.add_child(zona_opciones)

	# Retroalimentación
	panel_feedback = VBoxContainer.new()
	panel_feedback.add_theme_constant_override("separation", 8)
	col.add_child(panel_feedback)
	texto_feedback = _texto(panel_feedback, "")
	boton_continuar = Button.new()
	boton_continuar.custom_minimum_size = Vector2(0, 44)
	boton_continuar.pressed.connect(_on_continuar)
	panel_feedback.add_child(boton_continuar)

	# Final
	panel_final = VBoxContainer.new()
	panel_final.add_theme_constant_override("separation", 8)
	col.add_child(panel_final)
	texto_final = _texto(panel_final, "")
	var de_nuevo = Button.new()
	de_nuevo.text = "Jugar de nuevo"
	de_nuevo.custom_minimum_size = Vector2(0, 44)
	de_nuevo.pressed.connect(_on_jugar_de_nuevo)
	panel_final.add_child(de_nuevo)
	return scroll

# ---------------------------------------------------------------
# Configuración del día
# ---------------------------------------------------------------
func _mostrar_config():
	fase = "config"
	titulo_dia.text = "DÍA %d / %d" % [GameManager.dia_actual, GameManager.DIAS_TOTALES]
	etiqueta_registro.text = ""
	sel_racion.select(RACIONES.find(GameManager.racion))
	sel_instrumentos.select(INSTRUMENTOS.find(GameManager.instrumentos))
	sel_instrumentos.disabled = GameManager.instrumentos_bloqueados
	sel_higiene.select(1 if GameManager.higiene_suspendida else 0)
	panel_config.visible = true
	panel_decision.visible = false
	panel_feedback.visible = false
	panel_final.visible = false
	actualizar_hud()

func _on_iniciar_dia():
	GameManager.racion = String(RACIONES[sel_racion.selected])
	if not GameManager.instrumentos_bloqueados:
		GameManager.instrumentos = String(INSTRUMENTOS[sel_instrumentos.selected])
	GameManager.higiene_suspendida = (sel_higiene.selected == 1)
	snap_dia = GameManager.instantanea()
	var lineas: Array = GameManager.procesar_inicio_dia()
	etiqueta_registro.text = "REGISTRO DEL DÍA\n- " + "\n- ".join(lineas)
	panel_config.visible = false
	actualizar_hud()
	if GameManager.hay_final_inmediato():
		_ir_al_final()
		return
	numero_decision = 1
	_mostrar_decision()

# ---------------------------------------------------------------
# Decisiones
# ---------------------------------------------------------------
func _mostrar_decision():
	decision_actual = GameManager.elegir_decision(numero_decision)
	if decision_actual.is_empty():
		_cerrar_dia()
		return
	var d: Dictionary = decision_actual
	if d.has("al_iniciar"):
		GameManager.aplicar_efecto(d["al_iniciar"])
	fase = "decision"

	var tipo: String = "Gestión de recursos"
	if d["categoria"] == "nave":
		tipo = "Emergencia de la nave (gravedad %d)" % int(d["gravedad"])
	elif d["categoria"] == "hito":
		tipo = "Hito de la misión"
	var resp: String = String(d.get("responsable", ""))
	etiqueta_tema.text = "DECISIÓN %d: %s\n%s | Responsable: %s" % [numero_decision, d["tema"], tipo, GameManager.NOMBRES_TRIPULANTE.get(resp, resp)]
	var situacion: String = String(d["texto"])
	if d.get("ruta_aborto", false) and GameManager.aborto_disponible():
		situacion += "\n\n¡ATENCIÓN! Tus reservas están en rojo: puedes soltar la carga científica para aligerar la nave."
	texto_situacion.text = situacion

	for hijo in zona_opciones.get_children():
		hijo.queue_free()
	var indices: Array = []
	var extra: Array = []
	var aborto: bool = GameManager.aborto_disponible()
	for i in d["opciones"].size():
		var o: Dictionary = d["opciones"][i]
		if o.get("requiere_aborto", false):
			if aborto:
				extra.append(i)
			continue
		indices.append(i)
	indices.shuffle()   # la opción buena no siempre está en el mismo lugar
	var orden: Array = indices + extra
	var letras: Array = ["A", "B", "C"]
	for pos in orden.size():
		var o2: Dictionary = d["opciones"][orden[pos]]
		var b = Button.new()
		var detalle: String = String(o2.get("descripcion", ""))
		b.text = "%s) %s" % [letras[pos], o2["texto"]]
		if detalle != "":
			b.text += "\n" + detalle
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 52)
		b.pressed.connect(_on_opcion.bind(int(orden[pos])))
		zona_opciones.add_child(b)

	# Temporizador (el estrés de Elena puede recortarlo)
	tiempo_total = maxf(5.0, float(d["tiempo_s"]) - GameManager.penal_tiempo)
	GameManager.penal_tiempo = 0.0
	tiempo_restante = tiempo_total
	var con_tiempo: bool = not GameManager.modo_sin_temporizador
	barra_tiempo.visible = con_tiempo
	etiqueta_tiempo.visible = con_tiempo
	barra_tiempo.max_value = tiempo_total
	barra_tiempo.value = tiempo_restante
	etiqueta_tiempo.text = "Tiempo: %d s" % ceili(tiempo_restante)

	panel_decision.visible = true
	panel_feedback.visible = false
	actualizar_hud()

func _process(delta: float) -> void:
	if fase != "decision" or GameManager.modo_sin_temporizador:
		return
	tiempo_restante -= delta
	barra_tiempo.value = maxf(tiempo_restante, 0.0)
	etiqueta_tiempo.text = "Tiempo: %d s" % ceili(maxf(tiempo_restante, 0.0))
	barra_tiempo.modulate = ROJO if tiempo_restante < 4.0 else BLANCO
	if tiempo_restante <= 0.0:
		_resolver(0, true)

func _on_opcion(indice: int):
	if fase != "decision":
		return
	_resolver(indice, false)

func _resolver(indice: int, por_tiempo: bool):
	fase = "feedback"
	var res: Dictionary = GameManager.resolver(decision_actual, indice, por_tiempo)
	panel_decision.visible = false
	texto_feedback.text = _armar_feedback(res)
	if GameManager.hay_final_inmediato():
		siguiente = "final"
		boton_continuar.text = "Ver el desenlace de la misión"
	elif numero_decision == 1:
		siguiente = "decision2"
		boton_continuar.text = "Continuar"
	else:
		siguiente = "cerrar"
		boton_continuar.text = "Ver el resumen del día"
	panel_feedback.visible = true
	actualizar_hud()

# Explicación en tres capas: qué pasó, por qué pasó y qué habría pasado
func _armar_feedback(res: Dictionary) -> String:
	var opcion: Dictionary = res["opcion"]
	var l: Array = []
	l.append("RESULTADO: %s" % TIER_TEXTO[String(res["tier"])])
	l.append("Decisión: " + String(opcion["texto"]))
	if String(res["nota"]) != "":
		l.append("")
		l.append(String(res["nota"]))
	l.append("")
	l.append("QUÉ PASÓ")
	if res["cambios"].is_empty():
		l.append("- Las barras no cambiaron.")
	for c in res["cambios"]:
		l.append("- " + String(c))
	for m in res["muertes"]:
		l.append("- " + String(m))
	l.append("")
	l.append("POR QUÉ PASÓ")
	for f in res["factores"]:
		l.append("- " + String(f))
	var por_que: String = String(opcion.get("por_que", ""))
	if por_que != "":
		l.append("- " + por_que)
	var fuente: String = String(opcion.get("fuente", ""))
	if fuente != "":
		l.append("Fuente: " + fuente)
	if not res["alternativas"].is_empty():
		l.append("")
		l.append("QUÉ HABRÍA PASADO CON LAS OTRAS OPCIONES (según el estado de la nave en ese momento)")
		for a in res["alternativas"]:
			l.append("- " + String(a))
	return "\n".join(l)

func _on_continuar():
	match siguiente:
		"decision2":
			numero_decision = 2
			panel_feedback.visible = false
			_mostrar_decision()
		"cerrar":
			panel_feedback.visible = false
			_cerrar_dia()
		"dia":
			GameManager.dia_actual += 1
			panel_feedback.visible = false
			_mostrar_config()
		"final":
			_ir_al_final()

func _cerrar_dia():
	fase = "feedback"
	panel_decision.visible = false
	var cambios: Array = GameManager.describir_cambios(snap_dia, GameManager.instantanea())
	var l: Array = ["RESUMEN DEL DÍA %d" % GameManager.dia_actual, ""]
	if cambios.is_empty():
		l.append("- Sin cambios.")
	for c in cambios:
		l.append("- " + String(c))
	for a in GameManager.alarmas():
		l.append("ALARMA: " + String(a))
	texto_feedback.text = "\n".join(l)
	GameManager.cerrar_dia()
	if GameManager.hay_final_inmediato() or GameManager.dia_actual >= GameManager.DIAS_TOTALES:
		siguiente = "final"
		boton_continuar.text = "Ver el desenlace de la misión"
	else:
		siguiente = "dia"
		boton_continuar.text = "Continuar al día %d" % (GameManager.dia_actual + 1)
	panel_feedback.visible = true
	actualizar_hud()

# ---------------------------------------------------------------
# Final
# ---------------------------------------------------------------
func _motivos(tipo: String) -> Array:
	var m: Array = []
	var vitales: Array = ["agua", "comida", "oxigeno", "electricidad", "combustible"]
	if tipo == "malo":
		if GameManager.forzar_final != "":
			m.append("La acumulación de CO2 dejó inconsciente a la tripulación antes del amerizaje.")
		if GameManager.vivos().is_empty():
			m.append("Todos los tripulantes murieron antes del amerizaje.")
		for b in ["agua", "oxigeno", "electricidad", "combustible"]:
			if float(GameManager.nave[b]) <= 0.0:
				m.append("%s llegó a 0 %%." % GameManager.ETIQUETAS[b])
		if GameManager.integridad <= GameManager.INTEGRIDAD_REENTRADA:
			m.append("El escudo térmico no resistió la reentrada (integridad %d %%)." % roundi(GameManager.integridad))
	elif tipo == "intermedio":
		if GameManager.mision_abortada:
			m.append("Se soltó la carga científica en el Día 10.")
		var muertos: int = GameManager.TRIPULANTES.size() - GameManager.vivos().size()
		if muertos > 0:
			m.append("Murieron %d tripulante(s)." % muertos)
		if not GameManager.mision_abortada and GameManager.ciencia < GameManager.CIENCIA_FINAL_BUENO:
			m.append("El progreso científico fue de %d %% (el final bueno exige %d %%)." % [roundi(GameManager.ciencia), int(GameManager.CIENCIA_FINAL_BUENO)])
		for b in vitales:
			if float(GameManager.nave[b]) <= GameManager.UMBRAL_FINAL_BUENO:
				m.append("%s terminó en %d %% (el final bueno exige más de %d %%)." % [GameManager.ETIQUETAS[b], roundi(GameManager.nave[b]), int(GameManager.UMBRAL_FINAL_BUENO)])
	else:
		m.append("Los cuatro astronautas sobreviven, todas las barras superan %d %% y el progreso científico llegó a %d %%." % [int(GameManager.UMBRAL_FINAL_BUENO), roundi(GameManager.ciencia)])
	return m

func _ir_al_final():
	fase = "final"
	panel_decision.visible = false
	panel_feedback.visible = false
	panel_config.visible = false
	var tipo: String = GameManager.evaluar_final()
	var pt: Dictionary = GameManager.puntaje()
	var l: Array = []
	l.append(String(TITULOS_FINAL[tipo]))
	l.append("")
	l.append(String(NARRATIVA_FINAL[tipo]))
	l.append("")
	l.append("POR QUÉ ESTE FINAL")
	for motivo in _motivos(tipo):
		l.append("- " + String(motivo))
	l.append("")
	l.append("INFORME DE LA MISIÓN")
	l.append("- Configuración de la Fase 0: " + GameManager.plan_nombre)
	l.append("- Día alcanzado: %d / %d" % [GameManager.dia_actual, GameManager.DIAS_TOTALES])
	l.append("- Tripulantes vivos: %d / 4" % GameManager.vivos().size())
	l.append("- Decisiones con resultado bueno: %d de %d" % [GameManager.decisiones_buenas, GameManager.decisiones_totales])
	l.append("- Progreso científico: %d %% (tope de tu plan: %d %%)" % [roundi(GameManager.ciencia), roundi(GameManager.ciencia_max)])
	l.append("")
	l.append("PUNTUACIÓN (0 a 1000)")
	l.append("- Supervivencia: %d / 400" % roundi(pt["supervivencia"]))
	l.append("- Ciencia: %d / 250" % roundi(pt["ciencia"]))
	l.append("- Recursos: %d / 150" % roundi(pt["recursos"]))
	l.append("- Buenas decisiones: %d / 150" % roundi(pt["decisiones"]))
	l.append("- Cohesión (confianza en Elena): %d / 50" % roundi(pt["cohesion"]))
	l.append("TOTAL: %d / 1000" % roundi(pt["total"]))
	l.append("")
	l.append("Semilla de esta partida: %d (sirve para repetirla y depurar errores)" % GameManager.semilla)
	texto_final.text = "\n".join(l)
	panel_final.visible = true
	actualizar_hud()

func _on_jugar_de_nuevo():
	GameManager.nueva_partida()
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

# ---------------------------------------------------------------
# HUD
# ---------------------------------------------------------------
func actualizar_hud():
	for b in BARRAS_NAVE:
		var clave: String = b[0]
		var v: float = GameManager.valor_estado(clave)
		barras[clave].value = v
		var rojo: bool = false
		if clave == "datos":
			rojo = v > 85.0
		elif clave != "ciencia":
			rojo = v < GameManager.UMBRAL_ABORTO
		barras[clave].modulate = ROJO if rojo else BLANCO
	nombres_barra["ciencia"].text = "Ciencia (tope %d)" % roundi(GameManager.ciencia_max)

	var enlace: String = "activo"
	if GameManager.enlace_dias > 0:
		enlace = "PERDIDO (%d día(s))" % GameManager.enlace_dias
	var ambiente: String = "Temperatura: %d °C (zona segura 18-28) | Filtros de CO2: %d | Enlace con la Tierra: %s" % [
		roundi(GameManager.temperatura), GameManager.filtros, enlace]
	ambiente += "\nRación: %s | Instrumentos: %s | Higiene: %s" % [
		NOMBRES_RACION[RACIONES.find(GameManager.racion)], NOMBRES_INSTRUMENTOS[INSTRUMENTOS.find(GameManager.instrumentos)],
		"Suspendida" if GameManager.higiene_suspendida else "Normal"]
	if GameManager.modulo_dias > 0:
		ambiente += "\nMódulo de servicio bloqueado: %d día(s)" % GameManager.modulo_dias
	if GameManager.reparaciones_dias > 0:
		ambiente += "\nReparaciones lentas: %d día(s)" % GameManager.reparaciones_dias
	etiqueta_ambiente.text = ambiente

	var alarmas: Array = GameManager.alarmas()
	if alarmas.is_empty():
		etiqueta_alarma.text = ""
	else:
		etiqueta_alarma.text = "¡ALARMA! " + ", ".join(alarmas)

	for id in GameManager.TRIPULANTES:
		var t: Dictionary = GameManager.tripulantes[id]
		var p: Dictionary = paneles_tripulante[id]
		p["titulo"].text = "%s (%s): %s" % [t["nombre"], t["rol"], GameManager.estado(id).to_upper()]
		p["salud"].value = float(t["salud"])
		p["salud"].modulate = ROJO if float(t["salud"]) < 25.0 else BLANCO
		p["stats"].text = "Salud %d | Estrés %d | Hambre %d | Confianza %d" % [
			roundi(t["salud"]), roundi(t["estres"]), roundi(t["hambre"]), roundi(t["confianza"])]
