class_name WeaponComponent
extends Node

@export var projectile_scene: PackedScene
@export var fire_rate: float = 5.0 # Shots per second
@export var muzzle: Node3D

var _cooldown_time: float = 0.0
var _timer: float = 0.0

func _ready() -> void:
	if fire_rate > 0:
		_cooldown_time = 1.0 / fire_rate

func _process(delta: float) -> void:
	if _timer > 0:
		_timer -= delta

func fire() -> void:
	if _timer > 0:
		return
		
	if not is_instance_valid(projectile_scene):
		push_warning("WeaponComponent: No projectile scene defined.")
		return
		
	if not is_instance_valid(muzzle):
		push_warning("WeaponComponent: No muzzle defined.")
		return

	# Spawn projectile
	var projectile = projectile_scene.instantiate() as Node3D
	get_tree().root.add_child(projectile)
	
	# Align to muzzle
	projectile.global_transform = muzzle.global_transform
	
	# Reset timer
	_timer = _cooldown_time
