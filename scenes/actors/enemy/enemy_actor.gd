extends CharacterBody3D

@export_group("References")
@export var movement_component: Node
@export var weapon_component: Node
@export var health_component: Node

@onready var detection_area: Area3D = $DetectionArea if has_node("DetectionArea") else null

func _ready() -> void:
	if not movement_component: movement_component = get_node_or_null("MovementComponent")
	if not weapon_component: weapon_component = get_node_or_null("WeaponComponent")
	if not health_component: health_component = get_node_or_null("HealthComponent")
	
	if health_component: health_component.died.connect(_on_died)
	add_to_group("enemies")
	print("[EnemyAI] Ready. MovementComponent: ", movement_component != null)

func _on_died() -> void:
	var explosion_scene = load("res://scenes/effects/asteroid_explosion.tscn")
	if explosion_scene:
		var explosion = explosion_scene.instantiate() as Node3D
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position
	queue_free()

# Interface for BT nodes
func move_towards(pos: Vector3, stop_distance: float = 10.0) -> void:
	if movement_component:
		var to_target = pos - global_position
		var dist = to_target.length()
		
		if dist < stop_distance:
			movement_component.move_direction = Vector3.ZERO
		elif dist < stop_distance * 3.0:
			var forward_vec = -global_transform.basis.z
			var speed_scale = remap(dist, stop_distance, stop_distance * 3.0, 0.1, 1.0)
			movement_component.move_direction = forward_vec * speed_scale
		else:
			# FULL THRUST FORWARD
			movement_component.move_direction = -global_transform.basis.z
		
		# Debug: Only print occasionally to avoid spam
		if Engine.get_physics_frames() % 60 == 0:
			print("[EnemyAI] Moving. Dist: %.1f, Direction: %s" % [dist, movement_component.move_direction])

func face_target(pos: Vector3) -> void:
	if movement_component:
		movement_component.steer_towards(pos)
		if Engine.get_physics_frames() % 60 == 0:
			print("[EnemyAI] Steering towards %s" % pos)

func is_facing(pos: Vector3, angle_deg: float = 20.0) -> bool:
	var to_target = (pos - global_position).normalized()
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_target))
	return angle < angle_deg

func fire_weapon() -> void:
	if weapon_component:
		weapon_component.fire()
