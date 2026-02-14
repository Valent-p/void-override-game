extends GPUParticles3D

## Simple auto-destroy script for one-shot particles

func _ready() -> void:
	# Ensure they actually start emitting if not set in editor
	emitting = true
	
	# Connect to finished signal if available, or use timer as fallback
	if has_signal("finished"):
		finished.connect(queue_free)
	else:
		# Fallback for older Godot versions or if signal isn't reliable
		get_tree().create_timer(lifetime + randomness + 0.5).timeout.connect(queue_free)
