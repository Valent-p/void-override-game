class_name GameHUD
extends CanvasLayer

@export var health_bar: ProgressBar
@export var boost_bar: ProgressBar

func initialize(player: Node) -> void:
	if not is_instance_valid(player): return
	
	# Connect Health
	var health_comp = player.get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.health_changed.connect(_on_health_changed)
		# Init values
		_on_health_changed(health_comp.current_health, health_comp.max_health)
		
	# Connect Boost
	var move_comp = player.get_node_or_null("MovementComponent")
	if move_comp:
		move_comp.boost_changed.connect(_on_boost_changed)
		# Init values - Assuming full start or fetching from comp
		_on_boost_changed(move_comp.current_boost_fuel, move_comp.max_boost_fuel)

func _on_health_changed(current: float, max_val: float) -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_val
		health_bar.value = current

func _on_boost_changed(current: float, max_val: float) -> void:
	if is_instance_valid(boost_bar):
		boost_bar.max_value = max_val
		boost_bar.value = current
