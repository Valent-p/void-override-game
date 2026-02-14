class_name Projectile
extends Area3D

@export var speed: float = 100.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0

var _timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move forward (local -Z)
	position -= transform.basis.z * speed * delta
	
	_timer += delta
	if _timer >= lifetime:
		queue_free()

@export var impact_effect: PackedScene

func _on_body_entered(body: Node3D) -> void:
	# Spawn impact effect
	if is_instance_valid(impact_effect):
		var impact = impact_effect.instantiate() as Node3D
		get_tree().root.add_child(impact)
		impact.global_position = global_position
		
	# Trigger small shake if close to player
	var cameras = get_tree().get_nodes_in_group("camera_shake")
	for cam in cameras:
		if cam.has_method("add_shake"):
			var dist = global_position.distance_to(get_viewport().get_camera_3d().global_position)
			if dist < 30.0:
				cam.add_shake(remap(dist, 0, 30, 0.3, 0.05))
		
	# Check for HealthComponent directly or via method
	var health = body.get_node_or_null("HealthComponent")
	if health and health is HealthComponent:
		health.damage(damage)
		queue_free()
		return
		
	# Check for method (duck typing)
	if body.has_method("damage"):
		body.damage(damage)
		queue_free()
		return
		
	# Hit something else (wall, etc)
	queue_free()
