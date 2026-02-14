extends StaticBody3D

@export var explosion_effect: PackedScene

func _ready() -> void:
	var health = get_node_or_null("HealthComponent")
	if health:
		health.died.connect(_on_died)

func _on_died() -> void:
	if is_instance_valid(explosion_effect):
		var explosion = explosion_effect.instantiate() as Node3D
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position
		
	# Trigger camera shake
	var cameras = get_tree().get_nodes_in_group("camera_shake")
	for cam in cameras:
		if cam.has_method("add_shake"):
			# Shake based on distance? For now just a flat amount if within range
			var dist = global_position.distance_to(get_viewport().get_camera_3d().global_position)
			if dist < 100.0:
				cam.add_shake(remap(dist, 0, 100, 1.5, 0.2))
		
	queue_free()
