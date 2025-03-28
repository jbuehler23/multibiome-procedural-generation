extends CharacterBody2D


@export var move_speed : float = 100


func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	
	velocity = direction * move_speed
	move_and_slide()
