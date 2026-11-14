extends Node
# Datos de los 14 días de la misión (documentación de LAST SIGNAL).
# La comunicadora puede editar los textos (situacion, texto, descripcion, evidencia)
# y el ingeniero industrial los números dentro de "efecto".
#
# Formato de "efecto":
#   "nave": barras de la nave (agua, comida, oxigeno, electricidad) y extras
#           (salud_sistemas, ciencia, riesgo_estructural, riesgo_aborto, riesgo_catastrofico)
#   "tripulacion": un tripulante (elena, marcus, sofia, leo) o "todos", con hambre, estres, salud
#   "muestras", "abortar", "forzar_final": banderas especiales
# "categoria": tipo de emergencia; si Orion tiene la mejora que la protege, el daño baja 40%.

var dias: Array = [
 {
  "dia": 1,
  "titulo": "Inserción Orbital (El Despegue)",
  "categoria": "energia",
  "protagonistas": [
   "leo",
   "marcus"
  ],
  "situacion": "La cápsula Orion alcanza la órbita terrestre baja. Leo Okafor quiere encender de inmediato los espectrómetros para calibrar datos antes de la inyección translunar; Marcus Chen advierte que el consumo de batería inicial es riesgoso.",
  "opcion_buena": {
   "texto": "Priorizar sistemas de soporte vital y navegación",
   "descripcion": "Esperar a estabilizar los paneles solares antes de encender instrumentos científicos.",
   "efecto": {
	"nave": {
	 "electricidad": -5
	},
	"tripulacion": {
	 "leo": {
	  "estres": 10
	 }
	}
   },
   "impacto_texto": "Electricidad -5%, Estrés de Leo +10%",
   "evidencia": "Protocolo correcto: La estabilización térmica y energética tras el lanzamiento es crítica antes de activar cargas útiles (NASA Artemis Flight Rules).",
   "fuente": ""
  },
  "opcion_mala": {
   "texto": "Encender todos los sensores a máxima potencia",
   "descripcion": "Darle gusto a Leo para empezar la ciencia desde el primer minuto.",
   "efecto": {
	"nave": {
	 "electricidad": -25,
	 "salud_sistemas": -10
	}
   },
   "impacto_texto": "Electricidad -25%, Salud de sistemas -10%",
   "evidencia": "Error de gestión: El pico de demanda energético sobrecarga las celdas de combustible antes del despliegue total de paneles.",
   "fuente": ""
  }
 },
 {
  "dia": 2,
  "titulo": "La Sombra del Hambre (Escasez de Comida)",
  "categoria": "comida",
  "protagonistas": [
   "sofia"
  ],
  "situacion": "La Dra. Sofía Reyes nota que el estrés del lanzamiento provocó un consumo calórico 15% superior al previsto en las raciones liofilizadas.",
  "opcion_buena": {
   "texto": "Racionamiento estricto",
   "descripcion": "Ajustar las porciones al mínimo técnico recomendado y modificar la dieta para bajar el cociente respiratorio.",
   "efecto": {
	"nave": {
	 "comida": -5
	},
	"tripulacion": {
	 "todos": {
	  "hambre": 15,
	  "estres": 10
	 }
	}
   },
   "impacto_texto": "Comida -5%, Hambre +15%, Estrés +10%",
   "evidencia": "La reducción controlada de calorías estabiliza el consumo metabólico en misiones de larga duración sin comprometer funciones vitales.",
   "fuente": "https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf"
  },
  "opcion_mala": {
   "texto": "Mantener porciones normales",
   "descripcion": "Permitir que coman a voluntad para mantener alta la moral.",
   "efecto": {
	"nave": {
	 "comida": -25
	}
   },
   "impacto_texto": "Comida -25%, Hambre 0%",
   "evidencia": "Agotamiento prematuro de las despensas antes de alcanzar la órbita lunar.",
   "fuente": ""
  }
 },
 {
  "dia": 3,
  "titulo": "El Aliento Falso (Fuga de Oxígeno)",
  "categoria": "casco",
  "protagonistas": [],
  "situacion": "Una microfisura en una válvula del módulo de servicio provoca una caída constante en la presión parcial de oxígeno (ppO2).",
  "opcion_buena": {
   "texto": "Protocolo de aislamiento y cascos",
   "descripcion": "Ordenar a la tripulación ponerse los cascos de emergencia, aislar el sector y usar sellador interno.",
   "efecto": {
	"nave": {
	 "oxigeno": -10
	},
	"tripulacion": {
	 "todos": {
	  "estres": 15
	 }
	}
   },
   "impacto_texto": "Oxígeno -10%, Estrés +15%",
   "evidencia": "El uso inmediato de máscaras de respiración y aislamiento de módulos preserva el tiempo de reserva ante caídas de presión.",
   "fuente": "https://ntrs.nasa.gov/api/citations/20200011599/downloads/20200011599.pdf"
  },
  "opcion_mala": {
   "texto": "Buscar la fuga sin protección",
   "descripcion": "Intentar tapar la válvula manualmente sin ponerse los cascos.",
   "efecto": {
	"nave": {
	 "oxigeno": -35
	},
	"tripulacion": {
	 "todos": {
	  "salud": -20
	 }
	}
   },
   "impacto_texto": "Oxígeno -35%, Salud de todos -20%",
   "evidencia": "La exposición a baja presión parcial de oxígeno induce hipoxia aguda y pérdida de consciencia en minutos.",
   "fuente": ""
  }
 },
 {
  "dia": 4,
  "titulo": "Corrección de Trayectoria (Cruce Lunar)",
  "categoria": "trayectoria",
  "protagonistas": [
   "elena"
  ],
  "situacion": "La nave entra en la esfera de influencia gravitacional de la Luna. Elena Marín debe ejecutar un encendido de motores para alinear la órbita.",
  "opcion_buena": {
   "texto": "Encendido calculado por computadora",
   "descripcion": "Confiar en la telemetría automatizada aunque tome 2 horas más de ajuste.",
   "efecto": {
	"nave": {
	 "agua": -5,
	 "electricidad": -5
	}
   },
   "impacto_texto": "Agua -5% (refrigeración), Electricidad -5%",
   "evidencia": "Las maniobras automatizadas de baja aceleración optimizan el propelente y reducen la fatiga estructural del casco.",
   "fuente": ""
  },
  "opcion_mala": {
   "texto": "Maniobra manual agresiva",
   "descripcion": "Forzar los propulsores principales para ganar tiempo.",
   "efecto": {
	"nave": {
	 "electricidad": -20,
	 "riesgo_estructural": 25
	}
   },
   "impacto_texto": "Electricidad -20%, Riesgo de daño estructural +25%",
   "evidencia": "El empuje manual excesivo genera vibraciones innecesarias y desperdicia reservas críticas de retorno.",
   "fuente": ""
  }
 },
 {
  "dia": 5,
  "titulo": "Furia en el Sol (Tormenta Solar)",
  "categoria": "radiacion",
  "protagonistas": [],
  "situacion": "Una eyección de masa coronal libera radiación ionizante directa hacia la trayectoria de la Orion.",
  "opcion_buena": {
   "texto": "Refugio en el núcleo de agua y apagón parcial",
   "descripcion": "Reubicar a los 4 tripulantes tras los tanques de agua potable y apagar sistemas no esenciales.",
   "efecto": {
	"nave": {
	 "electricidad": -10
	},
	"tripulacion": {
	 "todos": {
	  "estres": 15
	 }
	}
   },
   "impacto_texto": "Electricidad -10%, Estrés +15%",
   "evidencia": "El agua y los materiales ricos en hidrógeno son el escudo más eficaz contra protones solares en espacio profundo.",
   "fuente": "https://www.nasa.gov/reference/3-0-health-and-medical-care/"
  },
  "opcion_mala": {
   "texto": "Seguir operando a plena potencia",
   "descripcion": "Ignorar la alerta para no interrumpir la transmisión de datos.",
   "efecto": {
	"tripulacion": {
	 "todos": {
	  "salud": -35
	 }
	}
   },
   "impacto_texto": "Salud de todos -35%",
   "evidencia": "La exposición sin blindaje provoca síndrome de radiación aguda y daños celulares irreversibles.",
   "fuente": ""
  }
 },
 {
  "dia": 6,
  "titulo": "Apagón en la Consola (Falla Eléctrica)",
  "categoria": "energia",
  "protagonistas": [],
  "situacion": "Un cortocircuito en el bus principal deja fuera de servicio los paneles secundarios de la cabina.",
  "opcion_buena": {
   "texto": "Aislamiento y reinicio por módulos",
   "descripcion": "Desconectar cargas no esenciales y redirigir energía desde las celdas de combustible auxiliares.",
   "efecto": {
	"nave": {
	 "electricidad": -10
	},
	"tripulacion": {
	 "todos": {
	  "estres": 10
	 }
	}
   },
   "impacto_texto": "Electricidad -10%, Estrés +10%",
   "evidencia": "Aislar los buses defectuosos evita fallos en cascada en el sistema de soporte vital.",
   "fuente": "https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf"
  },
  "opcion_mala": {
   "texto": "Puentear el circuito a la fuerza",
   "descripcion": "Forzar el paso de corriente con todos los equipos encendidos.",
   "efecto": {
	"nave": {
	 "electricidad": -40,
	 "oxigeno": -15
	}
   },
   "impacto_texto": "Electricidad -40%, Oxígeno -15% (por humo/conato)",
   "evidencia": "Sobrecargar un bus en cortocircuito provoca incendios eléctricos en microgravedad.",
   "fuente": ""
  }
 },
 {
  "dia": 7,
  "titulo": "Impacto en Gravedad Cero (Astronauta Lesionado)",
  "categoria": "medico",
  "protagonistas": [
   "marcus",
   "sofia"
  ],
  "situacion": "Al asegurar las muestras lunares recién recolectadas, Marcus Chen sufre un golpe fuerte contra un mamparo, fracturándose una costilla.",
  "opcion_buena": {
   "texto": "Inmovilización y uso de kit médico",
   "descripcion": "La Dra. Sofía Reyes aplica férula de vacío, analgésicos y ordena reposo absoluto de 48 horas.",
   "efecto": {
	"tripulacion": {
	 "marcus": {
	  "salud": -10
	 }
	}
   },
   "impacto_texto": "Salud de Marcus -10% (estabilizada), Eficiencia de reparaciones -20% por 2 días",
   "evidencia": "La estabilización temprana evita complicaciones internas en entornos sin gravedad.",
   "fuente": "https://www.nasa.gov/reference/3-0-health-and-medical-care/"
  },
  "opcion_mala": {
   "texto": "Obligarlo a seguir trabajando",
   "descripcion": "Exigir que Marcus continúe operando los paneles de control sin descanso.",
   "efecto": {
	"tripulacion": {
	 "marcus": {
	  "salud": -45
	 },
	 "sofia": {
	  "estres": 25
	 }
	}
   },
   "impacto_texto": "Salud de Marcus -45%, Estrés de Sofía +25%",
   "evidencia": "El esfuerzo físico con traumatismo torácico en microgravedad compromete la capacidad respiratoria.",
   "fuente": ""
  }
 },
 {
  "dia": 8,
  "titulo": "Muestreo en Órbita Baja (Dilema Científico)",
  "categoria": "ciencia",
  "protagonistas": [
   "leo"
  ],
  "situacion": "Sobrevuelan el polo sur lunar. Leo pide extender 3 horas la recolección espectral y de regolito; el oxígeno de cabina está justo en el margen.",
  "opcion_buena": {
   "texto": "Recolección dentro de ventana segura",
   "descripcion": "Tomar únicamente las muestras prioritarias y cerrar compuertas a tiempo.",
   "efecto": {
	"nave": {
	 "oxigeno": -10,
	 "ciencia": 35
	},
	"muestras": true
   },
   "impacto_texto": "Oxígeno -10%, Progreso científico +35%",
   "evidencia": "Cumplir los tiempos límite de actividad garantiza el margen de reserva para el encendido de retorno.",
   "fuente": ""
  },
  "opcion_mala": {
   "texto": "Extender la operación al límite",
   "descripcion": "Quedarse hasta agotar las baterías de los sensores.",
   "efecto": {
	"nave": {
	 "oxigeno": -30,
	 "electricidad": -25
	},
	"muestras": true
   },
   "impacto_texto": "Oxígeno -30%, Electricidad -25%",
   "evidencia": "Exceder las ventanas operativas deja a la tripulación sin margen ante emergencias de regreso.",
   "fuente": ""
  }
 },
 {
  "dia": 9,
  "titulo": "Silencio en la Radio (Pérdida de Comunicación)",
  "categoria": "comunicaciones",
  "protagonistas": [
   "leo"
  ],
  "situacion": "La antena de alta ganancia se desalinea por vibración orbital, cortando el enlace de voz y telemetría con Houston.",
  "opcion_buena": {
   "texto": "Navegación autónoma y antena omnidireccional",
   "descripcion": "Confiar en las estrellas guía de a bordo y enviar pulsos básicos de estado.",
   "efecto": {
	"tripulacion": {
	 "leo": {
	  "estres": 20
	 }
	}
   },
   "impacto_texto": "Estrés de Leo +20%, Recursos intactos",
   "evidencia": "Las naves de espacio profundo están diseñadas para operar de forma autónoma sin contacto continuo con Tierra.",
   "fuente": "https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf"
  },
  "opcion_mala": {
   "texto": "Gastar propulsión girando la nave a ciegas",
   "descripcion": "Realizar maniobras bruscas buscando recuperar señal rápida.",
   "efecto": {
	"nave": {
	 "electricidad": -15,
	 "riesgo_aborto": 30
	}
   },
   "impacto_texto": "Electricidad -15%, Riesgo de aborto de misión +30%",
   "evidencia": "Gastar control de actitud sin vectores confirmados desorienta los sensores ópticos.",
   "fuente": ""
  }
 },
 {
  "dia": 10,
  "titulo": "Encendido de Retorno (El Punto de No Retorno)",
  "categoria": "retorno",
  "protagonistas": [
   "elena"
  ],
  "situacion": "Es hora de abandonar la órbita lunar.",
  "opcion_buena": {
   "texto": "Ejecutar encendido nominal de regreso",
   "descripcion": "Encender el motor principal siguiendo la ventana orbital exacta.",
   "efecto": {
	"nave": {
	 "electricidad": -10,
	 "agua": -5
	}
   },
   "impacto_texto": "Electricidad -10%, Agua -5%",
   "evidencia": "La trayectoria de retorno libre aprovecha la gravedad terrestre para minimizar el gasto de recursos.",
   "fuente": ""
  },
  "opcion_mala": {
   "texto": "Acelerar consumo para llegar antes",
   "descripcion": "Forzar sistemas de soporte vital al máximo para acortar tiempos de revisión.",
   "efecto": {
	"nave": {
	 "agua": -20,
	 "oxigeno": -20
	}
   },
   "impacto_texto": "Agua -20%, Oxígeno -20%",
   "evidencia": "No es posible acortar mecánicamente el tránsito translunar sin comprometer la integridad del escudo térmico.",
   "fuente": ""
  },
  "opcion_abortar": {
   "texto": "Abortar la carga científica",
   "descripcion": "Soltar la carga científica para aligerar peso y priorizar la supervivencia de la tripulación.",
   "efecto": {
	"abortar": true,
	"muestras": false
   },
   "impacto_texto": "Misión abortada: ruta hacia el Final Intermedio",
   "evidencia": "",
   "fuente": "",
   "solo_si_alguna_barra_menor_que": 25,
   "barras": [
	"agua",
	"comida",
    "oxigeno"
   ]
  }
 },
 {
  "dia": 11,
  "titulo": "Calor Sofocante (Sobrecalentamiento)",
  "categoria": "termico",
  "protagonistas": [],
  "situacion": "Un fallo en los radiadores externos impide disipar el calor de la aviónica; la cabina sube a 34 °C.",
  "opcion_buena": {
   "texto": "Apagar computadoras secundarias y purgar refrigerante",
   "descripcion": "Reducir consumo electrónico y aumentar flujo en los intercambiadores de agua.",
   "efecto": {
	"nave": {
	 "agua": -10
	},
	"tripulacion": {
	 "todos": {
	  "estres": 10
	 }
	}
   },
   "impacto_texto": "Agua -10%, Estrés +10%",
   "evidencia": "Reducir la carga térmica interna evita el colapso de los procesadores de vuelo.",
   "fuente": "https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf"
  },
  "opcion_mala": {
   "texto": "Mantener todos los equipos encendidos",
   "descripcion": "Confiar en que la ventilación interna estabilizará el ambiente sola.",
   "efecto": {
	"nave": {
	 "electricidad": -25
	},
	"tripulacion": {
	 "todos": {
	  "salud": -20
	 }
	}
   },
   "impacto_texto": "Salud de todos -20%, Electricidad -25%",
   "evidencia": "El estrés térmico elevado reduce drásticamente la capacidad cognitiva de la tripulación.",
   "fuente": ""
  }
 },
 {
  "dia": 12,
  "titulo": "Gotas Contadas (Escasez de Agua)",
  "categoria": "agua",
  "protagonistas": [],
  "situacion": "Una obstrucción en el sistema de reciclaje de agua (WRS) reduce la recuperación diaria a la mitad.",
  "opcion_buena": {
   "texto": "Suspender higiene y usar reservas de hidratación",
   "descripcion": "Destinar el agua exclusivamente a beber y rehidratar comida.",
   "efecto": {
	"nave": {
	 "agua": -5
	},
	"tripulacion": {
	 "todos": {
	  "estres": 15
	 }
	}
   },
   "impacto_texto": "Agua -5%, Estrés +15%",
   "evidencia": "El mínimo vital de supervivencia es de 2.5 litros diarios por astronauta; la higiene es prescindible en contingencia.",
   "fuente": "https://www.nasa.gov/wp-content/uploads/2023/12/ochmo-tb-027-water.pdf"
  },
  "opcion_mala": {
   "texto": "Mantener consumo normal sin reparar el filtro",
   "descripcion": "Seguir gastando agua en limpieza personal.",
   "efecto": {
	"nave": {
	 "agua": -30
	},
	"tripulacion": {
	 "todos": {
	  "salud": -15
	 }
	}
   },
   "impacto_texto": "Agua -30%, Salud de todos -15%",
   "evidencia": "La deshidratación severa altera el volumen sanguíneo y provoca síncopes durante la reentrada.",
   "fuente": ""
  }
 },
 {
  "dia": 13,
  "titulo": "Cicatrices en el Casco (Daño Estructural)",
  "categoria": "casco",
  "protagonistas": [],
  "situacion": "Un micrometeorito golpea cerca del anillo de unión del escudo térmico, activando una alarma de integridad estructural.",
  "opcion_buena": {
   "texto": "Inspección con ultrasonido y sellado de polímero",
   "descripcion": "Revisar desde el interior, aplicar resina de refuerzo y limitar movimientos bruscos.",
   "efecto": {
	"nave": {
	 "electricidad": -10
	},
	"tripulacion": {
	 "todos": {
	  "estres": 10
	 }
	}
   },
   "impacto_texto": "Electricidad -10%, Estrés +10%",
   "evidencia": "Verificar la integridad del escudo térmico antes de tocar atmósfera es obligatorio para evitar desintegración.",
   "fuente": "https://ntrs.nasa.gov/api/citations/20200011599/downloads/20200011599.pdf"
  },
  "opcion_mala": {
   "texto": "Ignorar la alarma por considerarla menor",
   "descripcion": "No revisar el mamparo para ahorrar energía.",
   "efecto": {
	"nave": {
	 "riesgo_catastrofico": 60
	}
   },
   "impacto_texto": "Probabilidad de fracaso catastrófico en Día 14 +60%",
   "evidencia": "Cualquier brecha sin sellar en el escudo térmico permite la entrada de plasma a 2.700 °C durante el descenso.",
   "fuente": ""
  }
 },
 {
  "dia": 14,
  "titulo": "El Aire Pesado y la Reentrada (Acumulación de CO2 + Desenlace)",
  "categoria": "co2",
  "protagonistas": [],
  "situacion": "A horas de entrar en la atmósfera terrestre, los filtros de hidróxido de litio (scrubbers) que limpian el dióxido de carbono se saturan por completo.",
  "opcion_buena": {
   "texto": "Rotar cartuchos de respaldo y reposo absoluto",
   "descripcion": "Instalar los últimos filtros de emergencia y ordenar respiración calmada sin actividad física.",
   "efecto": {
	"nave": {
	 "oxigeno": -5
	}
   },
   "impacto_texto": "Oxígeno -5%, Fin de misión alcanzado",
   "evidencia": "Reducir la tasa metabólica disminuye la exhalación de CO2 mientras los filtros de reserva estabilizan la cabina.",
   "fuente": "https://www.nasa.gov/wp-content/uploads/2023/07/eclss-technical-brief-ochmo.pdf"
  },
  "opcion_mala": {
   "texto": "Mantener actividad física y maniobras intensas sin cambiar filtros",
   "descripcion": "Seguir operando a máximo ritmo respiratorio.",
   "efecto": {
	"tripulacion": {
	 "todos": {
	  "salud": -50
	 }
	},
	"forzar_final": "malo"
   },
   "impacto_texto": "Salud de todos -50% (hipercapnia), disparando el Final Malo justo antes del amerizaje",
   "evidencia": "La acumulación de CO2 provoca intoxicación aguda, pérdida de visión y muerte por asfixia.",
   "fuente": ""
  }
 }
]

func obtener(dia: int) -> Dictionary:
	return dias[dia - 1]

func _ready():
	print("Eventos cargados: ", dias.size())
