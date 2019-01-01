extends KinematicBody

var gravity = Vector3.DOWN * 10
var velocity = Vector3.ZERO
var acceleration_input = 0
var acceleration_multi = 2
var steer = 0
var turning_radius = 3
var engine_power = 10
var forward = Vector3.FORWARD	
var friction = 0.1

		
func _process(delta):
	
	if Input.is_action_just_pressed("reset"):
		transform.origin = Vector3.ZERO
	
	if Input.is_action_just_pressed("look back"):
		get_tree().set_input_as_handled() 
		find_node("Driver POV backwards").current = true
	if Input.is_action_just_released("look back"):
		find_node("Driver POV").current = true
	
	steer = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	rotate_y(deg2rad(steer*turning_radius))
	
	forward = transform.basis.z.normalized()
	acceleration_input = (Input.get_action_strength("accelerate")-Input.get_action_strength("reverse")) * engine_power
	if acceleration_input and !$AudioStreamPlayer3D.playing:  $AudioStreamPlayer3D.play()
	velocity += forward * acceleration_input * acceleration_multi
	
	if velocity.length() != 0:
		velocity -= Vector3.ONE * friction
	velocity = move_and_slide( velocity, Vector3.UP)
	
	find_node("dial").rotation.z = deg2rad(velocity.z*0.1)
	
	
	