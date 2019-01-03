extends KinematicBody

var gravity = Vector3.DOWN * 10
var velocity = Vector3.ZERO
var driver_face = Vector3.ZERO

var acceleration_input = 0
var acceleration_multi = 2

var steer = 0
var turning_angle = 3

var engine_power = 3
var forward = Vector3.FORWARD

var friction = 0.8


func _ready():
	driver_face = find_node("Driver POV").rotation


func _process(delta):
	
	if Input.is_action_just_pressed("reset"):
		transform.origin = Vector3.ZERO
	
	if Input.is_action_just_pressed("look back"):
		get_tree().set_input_as_handled() 
		find_node("Driver POV backwards").current = true
	if Input.is_action_just_released("look back"):
		find_node("Driver POV").current = true
	
	forward = global_transform.basis.z.normalized()
	acceleration_input = (Input.get_action_strength("accelerate")-Input.get_action_strength("reverse"))
	if acceleration_input and !$AudioStreamPlayer3D.playing:  
		$AudioStreamPlayer3D.play()
	velocity += forward * acceleration_input * engine_power * acceleration_multi 
	
	steer = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	find_node("steering wheel").rotation = Vector3(0,0,-steer)
	if steer == 0:
		find_node("Driver POV").rotation.y = lerp(find_node("Driver POV").rotation.y, driver_face.y+steer*0.5, 0.1)
	else:
		find_node("Driver POV").rotation.y = lerp(find_node("Driver POV").rotation.y, driver_face.y+steer*0.5, 0.01)
	
	velocity = velocity.rotated( Vector3.UP, deg2rad(steer*turning_angle) )
	if velocity.length() > 1:
		rotate_y( deg2rad(steer*turning_angle*acceleration_input) )
	
	if velocity.length() > 0:
		velocity *= friction
	velocity = move_and_slide( velocity, Vector3.UP)
	
	#ui
	find_node("dial").rotation.z = deg2rad(velocity.z*0.1)
	find_node("power").value = velocity.length()
	find_node("power2").value = velocity.length()
	
	
	