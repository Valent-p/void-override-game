class_name ArenaGenerator
extends Node3D

@export_group("Generation Settings")
@export var arena_seed: int = 12345
@export var generation_radius: float = 500.0
@export var grid_size: float = 50.0 # Size of each spawning cell
@export var density: float = 0.5 # Chance (0-1) to spawn in a cell

@export_group("Assets")
@export var asteroid_scenes: Array[PackedScene]

# Store generated objects to clean up if needed
var _spawned_objects: Array[Node] = []

func _ready() -> void:
	generate_arena()

func generate_arena() -> void:
	# Clear previous generation
	for obj in _spawned_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_spawned_objects.clear()
	
	if asteroid_scenes.is_empty():
		push_warning("ArenaGenerator: No asteroid scenes assigned.")
		return

	print("ArenaGenerator: Generating with seed %d..." % arena_seed)
	
	# Seed the RNG
	var rng = RandomNumberGenerator.new()
	rng.seed = arena_seed
	
	# Calculate grid bounds
	var cells_count = ceil(generation_radius / grid_size)
	var start = -cells_count
	var end = cells_count
	
	for x in range(start, end + 1):
		for y in range(start, end + 1):
			for z in range(start, end + 1):
				_process_cell(Vector3(x, y, z), rng)
				
	print("ArenaGenerator: Generation complete. Spawned %d objects." % _spawned_objects.size())

func _process_cell(cell_coord: Vector3, rng: RandomNumberGenerator) -> void:
	# Calculate cell center in world space
	var cell_center = cell_coord * grid_size
	
	# Check if within generation radius (circular arena)
	if cell_center.length() > generation_radius:
		return
	
	# Deterministic random for this cell
	# We combine the seed with the coordinates to get a unique hash for this cell
	# Note: We rely on the passed 'rng' state if we iterate sequentially, 
	# OR we can re-seed based on coordinates for parallel-friendliness.
	# For simplicity, sequential RNG usage is fine as long as order is deterministic.
	
	# Roll for spawn
	if rng.randf() > density:
		return
		
	# Pick a random asset
	var scene_to_spawn = asteroid_scenes[rng.randi() % asteroid_scenes.size()]
	var instance = scene_to_spawn.instantiate() as Node3D
	
	# 1. Position Jitter: Random spot within the cell
	var random_offset = Vector3(
		rng.randf_range(-grid_size / 2.0, grid_size / 2.0),
		rng.randf_range(-grid_size / 2.0, grid_size / 2.0),
		rng.randf_range(-grid_size / 2.0, grid_size / 2.0)
	)
	instance.position = cell_center + random_offset
	
	# 2. Random Rotation
	instance.rotation = Vector3(
		rng.randf_range(0, TAU),
		rng.randf_range(0, TAU),
		rng.randf_range(0, TAU)
	)
	
	# 3. Random Scale (0.8 to 2.5) for variety
	var scale_val = rng.randf_range(0.8, 2.5)
	instance.scale = Vector3.ONE * scale_val
	
	add_child(instance)
	_spawned_objects.append(instance)
