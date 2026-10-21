extends Area2D

var explosion_sound: AudioStream
var exploding = false
var evil_type: String = "green"
var generation: int = 0

var spawner: Node = null
var obstacles: Array = []

var move_speed = 90.0
var flee_radius = 70.0
var teleport_interval = 1.6
var teleport_timer = 0.0

func _ready():
	add_to_group("evil")
	teleport_timer = teleport_interval

func player_overlapping() -> bool:
	if exploding:
		return false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _process(delta):
	if exploding:
		return
	match evil_type:
		"horns":
			_charge_player(delta)
		"red_nose":
			_flee_player(delta)
		"shadow":
			_teleport_tick(delta)

func _player_node() -> Node:
	return get_tree().get_first_node_in_group("player")

func _charge_player(delta):
	var player = _player_node()
	if not player:
		return
	var to_player = player.global_position - global_position
	if to_player.length() > 2.0:
		_try_move(to_player.normalized() * move_speed * delta)

func _flee_player(delta):
	var player = _player_node()
	if not player:
		return
	var away = global_position - player.global_position
	var dist = away.length()
	if dist < flee_radius and dist > 0.1:
		_try_move(away.normalized() * move_speed * delta)

func _teleport_tick(delta):
	teleport_timer -= delta
	if teleport_timer <= 0.0:
		teleport_timer = teleport_interval
		if spawner and spawner.has_method("find_free_position"):
			global_position = spawner.find_free_position(40.0, [])

func _try_move(offset: Vector2):
	var target = _clamp_to_viewport(global_position + offset)
	if _blocked(target):
		return
	global_position = target

func _clamp_to_viewport(pos: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var margin = 16.0
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		margin = shape_node.shape.radius
	pos.x = clampf(pos.x, margin, viewport_size.x - margin)
	pos.y = clampf(pos.y, margin, viewport_size.y - margin)
	return pos

func _blocked(pos: Vector2) -> bool:
	for rect in obstacles:
		if rect.has_point(pos):
			return true
	return false

func explode():
	if exploding:
		return
	exploding = true
	monitoring = false
	_play_explosion_sound()
	if evil_type == "green" and generation < 1 and spawner and spawner.has_method("spawn_split"):
		spawner.spawn_split(self)
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 2.5, 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)

func _play_explosion_sound():
	if not explosion_sound:
		return
	var player = AudioStreamPlayer.new()
	player.stream = explosion_sound
	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
