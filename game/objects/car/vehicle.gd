
extends VehicleBody

# Member variables
#const STEER_LIMIT = 1 #radians
var MAX_SPEED = 55 #m/s = 200 kph
#var steer_inc = 0.02 #radians
var STEER_SPEED = 0.3
var STEER_LIMIT = 0.4 # 23 degrees # usually up to 30 deg

# based on torcs
var SPEED_SENS = 0.7 # speed sensitivity factor
var STEER_SENS = 0.8
var SPEED_FACT = 1.0 #10.0
var FUDGE = 8 # account for TORCS timestep being 0.002 seconds (500Hz) and our physics tick is 60 hz


export var force = 1500
# doing performance upgrades via multiplying makes it easier to balance
var braking_force_mult = 4
var engine_force_mult = 1

var offset
var position_on_line

#steering
var steer_angle = 0
var steer_target = 0
# this is mostly used by the AI but might be a curiosity for the player
var predicted_steer = 0

#speed
var speed = 0
var speed_int = 0
var speed_kph = 0

var forward_vec
var reverse

#lights
var headlight_one
var headlight_two
var taillights
var tail_mat

var sparks
	
func _ready():
	sparks = load("res://objects/Particles_sparks.tscn")
	
	
	#get lights
	headlight_one = get_node("SpotLight")
	headlight_two = get_node("SpotLight1")
	taillights = get_node("taillights")


func process_car_physics(delta, gas, braking, left, right):
	speed = get_linear_velocity().length();
	
	# hack solution to keep car under control
	#vary limit depending on current speed
	if (speed > 35): ##150 kph
		STEER_LIMIT = 0.1
		STEER_SPEED = 0.2
	elif (speed > 28): ##~100 kph
		STEER_LIMIT = 0.1
		STEER_SPEED = 0.3
	elif (speed > 15): #~50 kph
		STEER_LIMIT = 0.3
		STEER_SPEED = 0.4
	elif (speed > 5): #~25 kph
		STEER_LIMIT = 0.5
		STEER_SPEED = 0.4
	elif (speed > 2): #10 kph
		STEER_LIMIT = 0.75
		STEER_SPEED = 0.5
	else:
		STEER_LIMIT = 1
		STEER_SPEED = 1
	
	if (left):
		steer_target = STEER_LIMIT
		
		# TORCS approach:
		# keep previous value, add steering changes as on line 170, clamped to 0-1.0
		
	elif (right): # for usual
	# torcs-style would be if (so that neither key has precedence)
		steer_target = -STEER_LIMIT
		
		# TORCS approach: see line 77, but deduce change instead of adding, clamped to -1.0-0

	else: 
		steer_target = 0
	
	# TORCS approach would sum up here
#	steer_input = left_steer_input + right_steer_input
	#print(steer_input)
	
	
	#gas
	if (gas): #(Input.is_action_pressed("ui_up")):
		#obey max speed setting
		if (speed < MAX_SPEED):
			set_engine_force(force*engine_force_mult)
		else:
			set_engine_force(0)
	else:
		if (speed > 3):
			set_engine_force((-force*engine_force_mult)/4)
		else:
			set_engine_force(0)
	
	#cancel braking visual
	tail_mat = taillights.get_mesh().surface_get_material(0)
	if tail_mat != null:
		tail_mat.set_albedo(Color(0.62,0.62,0.62))
	
	#brake/reverse
	if (braking): #(Input.is_action_pressed("ui_down")):
		if (speed > 5):
			#slows down 1 unit per tick
			# increasing the value seems to do nothing
			set_brake(1)
			# let's make the brake actually brake harder
			set_engine_force(-force*braking_force_mult)
		else:
			#reverse
			set_brake(0.0)
			set_engine_force(-force)
			
		#visual effect
		if tail_mat != null:	
			tail_mat.set_albedo(Color(1,1,1))
		
	else:
		set_brake(0.0)
	
	# original Truck Town logic
	#steering
	if (steer_target < steer_angle):
		# original
		#var steer_change = STEER_SPEED*delta

		# TORCS style
		var press = 2 * 1 - 1
		var steer_change = press * STEER_SENS * delta  / (1.0 + SPEED_SENS * get_linear_velocity().length() / SPEED_FACT) * FUDGE

		steer_angle -= steer_change
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		# original
		#var steer_change = STEER_SPEED*delta
		
		# TORCS style
		var press = 2 * 1 - 1
		var steer_change = press * STEER_SENS * delta  / (1.0 + SPEED_SENS * get_linear_velocity().length() / SPEED_FACT) * FUDGE
		
		steer_angle += steer_change
		
		if (steer_target < steer_angle):
			steer_angle = steer_target
	
	set_steering(steer_angle)
	
	#this one actually reacts to rotations unlike the one using basis.z or linear velocity.z
	var forward_vec = get_global_transform().xform(Vector3(0, 1.5, 2))-get_global_transform().origin
	
	reverse = !get_linear_velocity().dot(forward_vec) > 0


#func _physics_process(delta):
	#just to have something here
#	var basis = get_transform().basis.y
	
	#kill_debugs()


func _integrate_forces(state):
	if state.get_contact_count() > 0:
		#kill_debugs()
		
		var c_pos = state.get_contact_collider_position(0)
		var l_pos = state.get_contact_local_position(0)
		
		var normal = state.get_contact_local_normal(0)
		#var tr = Transform(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1), c_pos)
		#print("Local pos of contact: " + str(l_pos) + " collider " + str(c_pos))
		
		var local
		
		# bug! sometimes there are weird "collisions" far away, ignore them
		if l_pos == c_pos:
			local = get_global_transform().xform(l_pos)
		
		if local:
			var x_gr = 9.8
			if local.x < 0:  x_gr = -9.8
			
			var y_gr = -4.5
			if local.z > 0:  y_gr = -9.8
			
			normal = Vector3(x_gr, 0, y_gr)
			
			spawn_sparks(local, normal)


func kill_debugs():
	# kill old cubes
	for c in get_children():
		if c.get_name().find("Spark") != -1:
	#if get_node("Debug") != null:
			c.queue_free()


func reset_car():
	print("Reset!")
	var axis = Vector3(0,1,0)
	var forward_vec = get_global_transform().xform(Vector3.FORWARD)
	# we don't have scaling so this gets the job done
	look_at(forward_vec, axis)


# basically copy-pasta from the car physics function, to predict steer the NEXT physics tick
func predict_steer(delta, left, right):
	
	if left:
		steer_target = STEER_LIMIT
	elif right:
		steer_target = -STEER_LIMIT
	else: #if (not left and not right):
		steer_target = 0
	
	var t = steer_target
	var a = steer_angle
	if t<a: #overshot
		steer_angle -= STEER_SPEED*delta
		if t>a: #undershot
			steer_angle = steer_target
	
	elif t > a: #undershot
		steer_angle += STEER_SPEED*delta
		if t < a: #overshot
			steer_angle = steer_target
			
	return steer_angle


func offset_dist(start, end, point):
	# this works in 2d (disregards the height)
	#print("Cross dist: " + str(start) + " " + str(end) + " " + str(point))
	# 2d
	#x1, y1 = start.x, start.y
	#x2, y2 = end.x, end.y
	#x3, y3 = point.x, point.y
	
	var px = end.x-start.x
	var py = end.z-start.z
	
	var something = px*px + py*py
	
	#assert
	if something==0: return [0, Vector3(0, start.y, 0)]
	
	var u = ((point.x-start.x)*px + (point.z-start.z)*py) / float(something)
	
	if u > 1:
		u = 1
	elif u < 0:
		u = 0
	
	var x = start.x + u * px
	var y = start.z + u * py
	
	var dx = x - point.x
	var dy = y - point.z
	
	var dist = sqrt(dx*dx + dy*dy) 
	
	return [dist, Vector3(x, start.y, y)]


func position_line(start_i, end_i, point, path):
	
	var start = path[start_i]
	var end = path[end_i]
	
	# get the point on line closest to the point
	var px = end.x-start.x
	var py = end.z-start.z
	
	var something = px*px + py*py
	
	#assert
	if something==0: return [0, Vector3(0, start.y, 0)]
	
	var u =  ((point.x - start.x) * px + (point.z - start.z) * py) / float(something)
	
	if u > 1:
		u = 1
	elif u < 0:
		u = 0
	
	var x = start.x + u * px
	var y = start.z + u * py
	
	return [Vector3(x, start.y, y), start_i, end_i]	


func setHeadlights(arg):
	headlight_one.set_visible(arg)
	headlight_two.set_visible(arg)


# debug
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3.ONE*0.5)
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	node.set_name("Debug")
	add_child(node)
	node.set_translation(loc)


func spawn_sparks(loc, normal):
	var spark = sparks.instance()
	add_child(spark)
	spark.set_name("Spark")
	spark.set_translation(loc)
	spark.set_emitting(true)
	spark.get_process_material().set_gravity(normal)