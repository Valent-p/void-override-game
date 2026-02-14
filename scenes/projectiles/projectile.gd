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

func _on_body_entered(body: Node3D) -> void:
	# Ignore checking against the shooter if we set up collision layers correctly, 
	# but for now rely on position spawning outside.
	
	# Check for HealthComponent directly or via method
	# Option 1: Look for component
	var health = body.get_node_or_null("HealthComponent")
	if health and health is HealthComponent:
		health.damage(damage)
		queue_free()
		return
		
	# Option 2: Check for method (duck typing)
	if body.has_method("damage"):
		body.damage(damage)
		queue_free()
		return
		
	# Hit something else (wall, etc)
	queue_free()
