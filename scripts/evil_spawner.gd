extends Node2D

const EvilCharacterScript = preload("res://scripts/evil_character.gd")
const VictoryMusic = preload("res://sfx/victory.wav")
const GameOverMusic = preload("res://sfx/game_over.wav")

@export var count = 3
@export var sprite_scale = 0.25
@export var min_distance = 60.0
@export var max_level = 6
@export var level_complete_pause = 2.0
@export var level_time_limit = 11.0
@onready var end_screen = get_node("../EndScreen")
@onready var timer_label = get_node("../HUD/TimerLabel")

var evil_variants = [
	{"type": "green", "texture": preload("res://evil/green.svg"), "sound": preload("res://sfx/green.wav")},
	{"type": "horns", "texture": preload("res://evil/horns.svg"), "sound": preload("res://sfx/horns.wav")},
	{"type": "red_nose", "texture": preload("res://evil/red_nose.svg"), "sound": preload("res://sfx/red_nose.wav")},
	{"type": "shadow", "texture": preload("res://evil/shadow.svg"), "sound": preload("res://sfx/shadow.wav")},
]

var current_level = 1
var level_transitioning = false
var game_over = false
var time_remaining = 0.0
var obstacles: Array = []
var kills = 0

func _ready():
	_spawn_level()

func register_kill():
	kills += 1

func _level_obstacle_count() -> int:
	return 2 if current_level >= max_level else 1

func _activate_level_obstacle():
	var obstacle_nodes = get_tree().get_nodes_in_group("obstacle")
	obstacles.clear()
	if obstacle_nodes.is_empty():
		return
	var pool_size = obstacle_nodes.size()
	var active_count = mini(_level_obstacle_count(), pool_size)
	var start_index = (current_level - 1) % pool_size
	var active_indices = {}
	for i in range(active_count):
		active_indices[(start_index + i) % pool_size] = true
	for i in range(pool_size):
		var node = obstacle_nodes[i]
		var active = active_indices.has(i)
		if node.has_method("set_active"):
			node.set_active(active)
		if active:
			var shape_node = node.get_node_or_null("CollisionShape2D")
			if shape_node and shape_node.shape is RectangleShape2D:
				var size = shape_node.shape.size
				obstacles.append(Rect2(node.global_position - size / 2.0, size))

func _process(delta):
	if game_over or level_transitioning:
		return

	time_remaining -= delta
	timer_label.text = "Time: %d" % maxi(ceili(time_remaining), 0)
	if time_remaining <= 0:
		_on_time_up()
		return

	_detect_end()

func _detect_end():
	if get_child_count() == 0:
		_on_level_cleared()

func _on_level_cleared():
	level_transitioning = true
	if current_level >= max_level:
		end_screen.show_victory(kills)
		_play_victory_music()
	else:
		end_screen.show_message("Level %d complete!" % current_level)
		await get_tree().create_timer(level_complete_pause).timeout
		end_screen.hide_message()
		current_level += 1
		level_transitioning = false
		_spawn_level()

func _play_music(stream: AudioStream):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()

func _play_victory_music():
	_play_music(VictoryMusic)

func _on_time_up():
	game_over = true
	for evil in get_children():
		evil.queue_free()
	end_screen.show_message("Time up! Game Over")
	_play_music(GameOverMusic)

func _level_enemy_count() -> int:
	return count + (current_level - 1) * 3

func _spawn_level():
	time_remaining = level_time_limit
	_activate_level_obstacle()

	var level_count = _level_enemy_count()
	var placed_positions = []
	for i in range(level_count):
		var pos = find_free_position(min_distance, placed_positions)
		placed_positions.append(pos)
		var evil = _create_evil_character()
		evil.position = pos
		add_child(evil)

func find_free_position(min_dist: float, avoid_positions: Array) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var margin = 32.0
	var pos = Vector2.ZERO
	var attempts = 0
	while attempts < 100:
		pos = Vector2(
			randf_range(margin, viewport_size.x - margin),
			randf_range(margin, viewport_size.y - margin)
		)
		if not _blocked_by_obstacle(pos) and _far_from_all(pos, avoid_positions, min_dist):
			return pos
		attempts += 1
	return pos

func _blocked_by_obstacle(pos: Vector2) -> bool:
	for rect in obstacles:
		if rect.has_point(pos):
			return true
	return false

func _far_from_all(pos: Vector2, positions: Array, min_dist: float) -> bool:
	for other in positions:
		if pos.distance_to(other) < min_dist:
			return false
	return true

func _create_evil_character(variant_override = null, generation: int = 0, scale_override: float = -1.0) -> Area2D:
	var variant = variant_override
	if variant == null:
		variant = evil_variants[randi() % evil_variants.size()]
	var texture = variant["texture"]
	var scl = scale_override if scale_override > 0.0 else sprite_scale

	var area = Area2D.new()
	area.set_script(EvilCharacterScript)
	area.explosion_sound = variant["sound"]
	area.evil_type = variant["type"]
	area.generation = generation
	area.spawner = self
	area.obstacles = obstacles

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = texture
	sprite.scale = Vector2(scl, scl)
	area.add_child(sprite)

	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = texture.get_width() * scl / 2.0
	collision_shape.shape = circle
	area.add_child(collision_shape)

	return area

func spawn_split(parent_evil: Node) -> void:
	var variant = null
	for v in evil_variants:
		if v["type"] == "green":
			variant = v
			break
	if variant == null:
		return
	var base_pos = parent_evil.global_position
	for i in range(2):
		var angle = randf_range(0, TAU)
		var offset = Vector2(cos(angle), sin(angle)) * 20.0
		var child = _create_evil_character(variant, parent_evil.generation + 1, sprite_scale * 0.6)
		child.position = base_pos + offset
		add_child(child)
