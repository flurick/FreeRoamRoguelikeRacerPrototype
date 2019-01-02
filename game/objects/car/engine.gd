extends KinematicBody

var gravity = Vector3.DOWN * 10
var velocity = Vector3.ZERO

var acceleration_input = 0
var acceleration_multi = 2

var steer = 0
var turning_radius = 3

var engine_power = 3
var forward = Vector3.FORWARD

var friction = 0.8

		
func _process(delta):
	
	if Input.is_action_just_pressed("reset"):
		transform.origin = Vector3.ZERO
	
	if Input.is_action_just_pressed("look back"):
		get_tree().set_input_as_handled() 
		find_node("Driver POV backwards").current = true
	if Input.is_action_just_released("look back"):
		find_node("Driver POV").current = true
	
	forward = global_transform.basis.z.normalized()
	acceleration_input = (Input.get_action_strength("accelerate")-Input.get_action_strength("reverse")) * engine_power
	if acceleration_input and !$AudioStreamPlayer3D.playing:  
		$AudioStreamPlayer3D.play()
	velocity += forward * acceleration_input * acceleration_multi
	
	steer = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	velocity = velocity.rotated( Vector3.UP, deg2rad(steer*turning_radius) )
	if velocity:
		rotate_y(deg2rad(steer*turning_radius))
	
	if velocity.length() >= 0:
		velocity *= friction
	velocity = move_and_slide( velocity, Vector3.UP)
	
	#ui
	find_node("dial").rotation.z = deg2rad(velocity.z*0.1)
	find_node("power").value = velocity.length()
	find_node("power2").value = velocity.length()
	
	
	