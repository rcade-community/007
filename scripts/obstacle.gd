extends StaticBody2D

func _ready():
	add_to_group("obstacle")

func set_active(active: bool) -> void:
	visible = active
	var shape = get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = not active
