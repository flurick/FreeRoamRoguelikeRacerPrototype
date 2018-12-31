extends KinematicBody

var gravity = Vector3.DOWN * 10
var velocity = Vector3.ZERO
var accelerate = 0
var steer = 0
var turning_radius = 3
var engine_power = 10
var forward = Vector3.FORWARD	
		
				
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
	accelerate = (Input.get_action_strength("accelerate")-Input.get_action_strength("reverse")) * engine_power
	velocity = move_and_slide( forward*accelerate, Vector3.UP)
	
	
	