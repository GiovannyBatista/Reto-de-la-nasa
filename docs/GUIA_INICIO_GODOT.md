# Guía de inicio en Godot — MYG-351: Last Signal

Guía para empezar desde cero con Godot y encargarte de **tu parte del juego: el menú principal y las pantallas de los 3 finales**.

---

## 0. Qué hay ya hecho en el proyecto (para que no lo repitas)

| Archivo | Qué hace | Quién |
|---|---|---|
| `srcipts/GameManager.gd` | El "cerebro": recursos de la nave, tripulantes, días, cálculo del final (`evaluar_final()`) y puntaje (`puntaje()`). Es un **Autoload** (se puede usar desde cualquier escena escribiendo `GameManager.algo`). | Giovanny |
| `srcipts/Eventos.gd` | Banco de 60 decisiones + 5 hitos fijos (días 1, 4, 8, 10, 14). También Autoload. | Giovanny |
| `scenes/shop.tscn` + `Shop.gd` | Fase 0: presupuesto de 10.000 CM. **Hoy es la escena con la que arranca el juego.** | Giovanny |
| `scenes/mission.tscn` + `Mission.gd` | Los 14 días: HUD, decisiones, temporizador y el final (solo en texto). | Giovanny |
| `scenes/main_menu.tscn` | **Vacía.** Aquí empieza tu trabajo. | Tú |

> ⚠️ La carpeta se llama `srcipts` (con el error de letra). **No la renombres**: Godot guarda las rutas y se romperían las escenas.

Lo que el documento del juego (GDD) pide y **todavía no existe**:
- Menú principal.
- "Pantallas dedicadas para los 3 finales" (hoy el final es un bloque de texto dentro de la misión).
- Retratos de personajes, fondo de cabina, audio.

---

## 1. Instalar Godot (10 minutos)

1. Pregúntale a Giovanny qué versión exacta usa: en Godot, menú **Ayuda → Acerca de Godot**. El proyecto está hecho en **Godot 4.7** (lo dice `project.godot`). Usa **la misma versión** que él, si no, los archivos se modifican solos y habrá conflictos en git.
2. Entra a **https://godotengine.org/download/windows/**
3. Descarga **Godot Engine** (la versión normal, **NO** la que dice ".NET" o "C#"; nosotros usamos GDScript).
   - Si tu versión no es la última, búscala en **https://godotengine.org/download/archive/**
4. Es un `.zip`, **no tiene instalador**. Descomprímelo en una carpeta fija, por ejemplo `C:\Godot\`.
5. Dentro hay un `.exe` (ej. `Godot_v4.7-stable_win64.exe`). Haz clic derecho → **Anclar a inicio** o crea un acceso directo en el escritorio.
6. Ábrelo. La primera vez muestra el **Administrador de proyectos**.

## 2. Abrir nuestro proyecto

1. En el Administrador de proyectos: **Importar** → busca la carpeta
   `C:\Users\camil\OneDrive\Desktop\Reto-de-la-nasa` → elige el archivo `project.godot` → **Abrir/Editar**.
2. La primera vez tarda un poco: crea la carpeta oculta `.godot/` (es caché, está en `.gitignore`, no se sube).
3. Pulsa **F5** (o el botón ▶ arriba a la derecha) para jugar. Debe abrir la tienda de la Fase 0. Juega una partida completa para entender el juego.

> 💡 Consejo: OneDrive a veces bloquea archivos mientras sincroniza. Si Godot da errores raros al guardar, pausa la sincronización de OneDrive mientras trabajas.

## 3. Tour del editor (lo mínimo que necesitas)

```
┌───────────────┬──────────────────────────────┬───────────────┐
│ ESCENA        │                              │ INSPECTOR     │
│ (árbol de     │       VISTA 2D / SCRIPT      │ (propiedades  │
│  nodos)       │   (pestañas arriba: 2D,      │  del nodo     │
│               │    3D, Script, AssetLib)     │  seleccionado)│
├───────────────┤                              ├───────────────┤
│ SISTEMA DE    │                              │ NODO          │
│ ARCHIVOS      ├──────────────────────────────┤ (señales:     │
│ (res://)      │ SALIDA (aquí salen print())  │  conectar     │
│               │                              │  botones)     │
└───────────────┴──────────────────────────────┴───────────────┘
```

Conceptos clave (en 1 línea cada uno):
- **Nodo**: una pieza (un botón, un texto, una imagen). Todo en Godot son nodos.
- **Escena** (`.tscn`): un árbol de nodos guardado. Menú, tienda, misión… cada una es una escena.
- **Script** (`.gd`): código GDScript pegado a un nodo para darle comportamiento.
- **Señal**: un aviso que lanza un nodo ("me presionaron"). Se conecta a una función.
- **Autoload**: script que está siempre vivo, en todas las escenas (`GameManager`, `Eventos`).
- `res://` = la carpeta del proyecto.

Atajos útiles: **F5** jugar el juego · **F6** jugar solo la escena abierta · **Ctrl+S** guardar · **Ctrl+A** añadir nodo.

## 4. GDScript en 5 minutos (se parece a Python)

```gdscript
extends Control                 # este script va en un nodo de tipo Control

var vidas: int = 3              # variable con tipo
const MAX: int = 10             # constante

func _ready():                  # se ejecuta 1 vez cuando la escena aparece
	print("Hola NASA")          # sale en el panel Salida

func _on_boton_pressed():       # función que conectamos a la señal de un botón
	vidas -= 1
	if vidas <= 0:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

⚠️ La **indentación es con TAB** (como Python pero con tabulador). Si mezclas espacios y tabs, da error.

Para leer datos del juego desde tu escena:
```gdscript
GameManager.evaluar_final()   # "bueno", "intermedio" o "malo"
GameManager.puntaje()["total"] # puntuación de 0 a 1000
GameManager.vivos().size()     # cuántos tripulantes siguen vivos
GameManager.estado("marcus")   # "activo", "herido", "crítico" o "muerto"
```

Ruta de aprendizaje recomendada (1–2 tardes):
1. Documentación oficial en español: https://docs.godotengine.org/es/stable/ → **Introducción** → "Tu primer juego 2D". Haz al menos hasta la parte de la interfaz (HUD).
2. Lee `Shop.gd` (es corto, 159 líneas) para ver cómo Giovanny crea botones y cambia de escena.

## 5. Trabajar con git sin romper nada

Tú estás en la rama `camilo_rama`. Flujo de cada día:

```bash
git pull origin main
```
(trae lo último de Giovanny a tu rama antes de empezar)

```bash
git add scenes/main_menu.tscn srcipts/MainMenu.gd
```
```bash
git commit -m "Menu principal"
```
```bash
git push origin camilo_rama
```

Reglas para no pisarse:
- **No edites** `GameManager.gd`, `Eventos.gd`, `Mission.gd` ni `Shop.gd` sin avisarle a Giovanny. Si necesitas algo de ahí, pídeselo o hazlo en un cambio pequeño y acordado.
- Tus archivos nuevos: `scenes/main_menu.tscn`, `scenes/final.tscn`, `srcipts/MainMenu.gd`, `srcipts/Final.gd`, y la carpeta `assets/` para imágenes y sonidos.

---

## 6. TU PARTE: Menú principal + Pantallas de final

### Por qué esta parte
- Es la **primera y la última impresión** del jurado.
- Casi no depende del código de Giovanny: solo **lee** `GameManager`, no lo cambia.
- Se hace mucho en el **editor visual**, ideal para aprender Godot.

### Paso 1 — Menú principal (tu primer ejercicio)

1. En *Sistema de archivos*, doble clic en `scenes/main_menu.tscn`. Ya tiene un nodo raíz `MainMenu` (Control).
2. Selecciona `MainMenu` → **Ctrl+A** → añade un `ColorRect`. En la barra de arriba de la vista 2D: **Anclaje → Rect completo**. En el Inspector pon `Color` casi negro (espacio).
3. Añade (hijo de `MainMenu`) un `VBoxContainer` → anclaje **Centro**.
4. Dentro del `VBoxContainer` añade:
   - `Label` → Text: `MYG-351: LAST SIGNAL`
   - `Label` → Text: `Misión Artemis-MYG · 14 días · 4 astronautas`
   - `Button` → renómbralo `BotonIniciar` (doble clic al nombre), Text: `Iniciar misión`
   - `Button` → `BotonReferencias`, Text: `Referencias NASA`
   - `Button` → `BotonSalir`, Text: `Salir`
5. Clic derecho en `MainMenu` → **Añadir script** → ruta `res://srcipts/MainMenu.gd` → Crear.
6. Conecta las señales: selecciona `BotonIniciar` → pestaña **Nodo** (a la derecha) → doble clic en `pressed()` → Conectar. Repite con los otros dos botones. Godot te crea las funciones.
7. Escribe el código:

```gdscript
extends Control

func _on_boton_iniciar_pressed():
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_boton_referencias_pressed():
	OS.shell_open("https://www.nasa.gov/reference/crew-systems/")

func _on_boton_salir_pressed():
	get_tree().quit()
```

8. Con la escena abierta, pulsa **F6** para probarla sola.
9. Cuando funcione, hazla la escena inicial: **Proyecto → Configuración del proyecto → Aplicación → Ejecutar → Escena principal** → `main_menu.tscn`. *(Avísale a Giovanny, porque hoy arranca en la tienda.)*

Extras cuando ya funcione: añadir un `TextureRect` con un fondo de la Luna/Tierra (imágenes de dominio público de NASA en https://images.nasa.gov — revisa que no tengan logos), un `AudioStreamPlayer` con zumbido ambiental, y una animación de título que parpadee como señal de radio.

### Paso 2 — Escena de finales (`scenes/final.tscn`)

Una escena que **lee** el resultado y muestra una pantalla distinta para cada final:

| Final | Condición (ya calculada por `GameManager.evaluar_final()`) | Ambiente sugerido |
|---|---|---|
| **Bueno — Misión cumplida** | 4 vivos, barras > 15 %, ciencia ≥ 70 % | Paracaídas sobre el Pacífico, colores cálidos, música triunfal |
| **Intermedio — Misión abortada** | Abortaron, murió alguien o poca ciencia | Cápsula en el mar, tonos grises, silencio de radio |
| **Malo — Silencio total** | Una barra en 0, CO₂ o integridad | Pantalla negra, línea de telemetría plana, texto tipo terminal "LAST SIGNAL" |

Estructura sugerida de nodos:
```
Final (Control)  ← script Final.gd
├── Fondo (TextureRect)
├── Panel (VBoxContainer)
│   ├── Titulo (Label)
│   ├── Narrativa (Label)
│   ├── Tripulacion (HBoxContainer)  ← 4 tarjetas: nombre + estado (vivo/herido/muerto)
│   ├── Puntaje (Label)
│   ├── MemoNasa (Label)              ← dato educativo con fuente NASA
│   └── BotonMenu (Button)
└── Musica (AudioStreamPlayer)
```

Esqueleto de `Final.gd`:
```gdscript
extends Control

@onready var titulo: Label = $Panel/Titulo
@onready var narrativa: Label = $Panel/Narrativa
@onready var puntaje: Label = $Panel/Puntaje

const TITULOS = {
	"bueno": "MISIÓN CUMPLIDA",
	"intermedio": "MISIÓN ABORTADA",
	"malo": "SILENCIO TOTAL",
}

func _ready():
	var tipo: String = GameManager.evaluar_final()
	titulo.text = TITULOS[tipo]
	puntaje.text = "Puntuación: %d / 1000" % roundi(GameManager.puntaje()["total"])
	for id in GameManager.TRIPULANTES:
		print(GameManager.NOMBRES_TRIPULANTE[id], ": ", GameManager.estado(id))
	# TODO: cambiar fondo, colores y música según 'tipo'

func _on_boton_menu_pressed():
	GameManager.nueva_partida()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

**Truco para probar sin jugar 14 días:** en `_ready()`, temporalmente, fuerza el final:
```gdscript
GameManager.forzar_final = "malo"   # bórralo antes de hacer commit
```

### Paso 3 — Conectarlo con la misión (coordinar con Giovanny)
Hoy `Mission.gd` muestra el final en su función `_ir_al_final()`. Cuando tu escena esté lista, el cambio es una línea en esa función:
```gdscript
get_tree().change_scene_to_file("res://scenes/final.tscn")
```
Acuérdalo con él antes de tocar su archivo.

---

## 7. Cómo usar los datos de la NASA en tu parte

Las referencias del reto:
- **Crew Systems**: https://www.nasa.gov/reference/crew-systems/
- **Habitability Functions Vol. 2 (cap. 7)**: https://www.nasa.gov/reference/7-0-habit-ability-functions-vol-2/

Idea: en cada pantalla de final, un **"Memo NASA"** que explique la ciencia detrás de lo que pasó, por ejemplo:
- Final bueno → por qué el retorno libre ahorra propelente / cuánta agua y comida necesita un astronauta (2,5 L de hidratación y ~3.035 kcal al día, los datos que ya usa el GDD).
- Final malo por CO₂ → qué es la hipercapnia y por qué el reposo reduce el CO₂ exhalado.
- Final intermedio → por qué la NASA exige redundancia en soporte vital (ECLSS) antes que carga científica.

Lee la página, escribe el memo **con tus palabras** y pon el enlace. Eso suma mucho con el jurado porque demuestra que el juego enseña.

---

## 8. Checklist de tu parte

- [ ] Godot instalado (misma versión que Giovanny) y proyecto abierto y jugado una vez
- [ ] Tutorial "Tu primer juego 2D" (hasta HUD)
- [ ] Menú principal funcionando (Iniciar / Referencias / Salir)
- [ ] Menú como escena principal (avisado a Giovanny)
- [ ] Escena `final.tscn` mostrando los 3 finales distintos
- [ ] Memo NASA en cada final con fuente
- [ ] Conectada desde `Mission.gd` (acordado con Giovanny)
- [ ] Fondo, música y efectos (extra)
