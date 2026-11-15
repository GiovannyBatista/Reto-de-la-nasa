
extends Node2D

@export var star_count: int = 100
@export var travel_speed: float = 65.0
@export var speed_factor: float = 1.0
@export var screen_size: Vector2 = Vector2(1280, 720)

var positions: Array[Vector2] = []
var speeds: Array[float] = []
var sizes: Array[int] = []
var phases: Array[float] = []

var elapsed: float = 0.0

var star_colors = [
	Color("#FFFFFF"),
	Color("#AFC7FF"),
	Color("#E6BFD7"),
	Color("#FFE5B0")
]


func _ready():
	randomize()

	for i in range(star_count):
		positions.append(Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		))

		speeds.append(randf_range(0.3, 1.5))
		sizes.append(randi_range(1, 3))
		phases.append(randf_range(0.0, TAU))


func _process(delta):
	elapsed += delta

	for i in range(positions.size()):
		positions[i].x -= (
			travel_speed * speeds[i] * speed_factor * delta
		)

		if positions[i].x < -4:
			positions[i].x = screen_size.x + 4
			positions[i].y = randf_range(0, screen_size.y)

	queue_redraw()


func _draw():
	for i in range(positions.size()):
		var brightness = 0.7 + 0.3 * sin(
			elapsed * 2.0 + phases[i]
		)

		var color = star_colors[i % star_colors.size()]
		color.a = brightness

		var size = sizes[i]
		var streak = 1.0 + speeds[i] * speed_factor * 2.0

		draw_rect(
			Rect2(
				positions[i],
				Vector2(size * streak, size)
			),
			color
		)
