tool
extends Spatial

# class member variables go here, for example:
var draw
var road_straight
var road

var positions = []

var points_arc = []

var first_turn
var last_turn

func _ready():
	draw = get_node("draw")
	road_straight = preload("res://roads/road_segment_straight.tscn")
	road = preload("res://roads/road_segment.tscn")
	
func connect_intersections(one, two):
	if one > get_child_count() -1 or two > get_child_count() -1:
		print("Wrong indices given")
		return
	
	if not "point_one" in get_child(one) or not "point_one" in get_child(two):
		print("Targets are not intersections?")
		return
	
	
	var src_exit = get_src_exit(get_child(one), get_child(two))
	print("Src exit: " + str(src_exit))
	var loc_src_exit = to_local(get_child(one).to_global(src_exit))

	var dest_exit = get_dest_exit(get_child(one), get_child(two))
	print("Dest exit: " + str(dest_exit))
	var loc_dest_exit = to_local(get_child(two).to_global(dest_exit))

	# debugging
	positions.append(loc_src_exit)
	positions.append(loc_dest_exit)
	
	draw.draw_line(positions)

	#print("Line length: " + str(loc_dest_exit.distance_to(loc_src_exit)))

	var extendeds = extend_lines(one,two, loc_src_exit, loc_dest_exit, 2)

	var corner_points = get_corner_points(one,two, extendeds[0], extendeds[1], extendeds[0].distance_to(loc_src_exit))

	var data = calculate_initial_turn(corner_points[0], corner_points[1], loc_src_exit, extendeds[0], src_exit)
	
	var top_node = Spatial.new()
	top_node.set_name("Road " +str(one) + "-" + str(two))
	add_child(top_node)

	initial_road_test(one, two, data, corner_points[0], top_node)

	data = calculate_last_turn(corner_points[2], corner_points[3], loc_dest_exit, extendeds[1], dest_exit)

	last_turn_test(one, two, data, corner_points[2], top_node)	
	
	set_straight(corner_points[1], corner_points[3], top_node)

func extend_lines(one, two, loc_src_exit, loc_dest_exit, extend):
	#B-A: A->B
	var src_line = loc_src_exit-get_child(one).get_translation()
	#var extend = ex
	var loc_src_extended = src_line*extend + get_child(one).get_translation()
	
	#debug_cube(loc_src_extended)
	
	var dest_line = loc_dest_exit-get_child(two).get_translation()
	var loc_dest_extended = dest_line*extend + get_child(two).get_translation()
	#debug_cube(loc_dest_extended)
	
	return [loc_src_extended, loc_dest_extended]
	
func get_corner_points(one, two, loc_src_extended, loc_dest_extended, dist):
	var corners = []
	
	# B-A = A-> B
	var vec_back = get_child(one).get_translation() - loc_src_extended
	vec_back = vec_back.normalized()*dist # x units away
	
	var corner_back = loc_src_extended + vec_back
	corners.append(corner_back)
	
	#debug_cube(Vector3(corner_back.x, 1, corner_back.z))
	
	var vec_forw = loc_dest_extended - loc_src_extended
	vec_forw = vec_forw.normalized()*dist # x units away
	
	var corner_forw = loc_src_extended + vec_forw
	corners.append(corner_forw)
	
	#debug_cube(Vector3(corner_forw.x, 1, corner_forw.z))
	
	# the destinations
	# B-A = A-> B
	vec_back = get_child(two).get_translation() - loc_dest_extended
	vec_back = vec_back.normalized()*dist # x units away
	
	corner_back = loc_dest_extended + vec_back
	corners.append(corner_back)
	
	#debug_cube(Vector3(corner_back.x, 1, corner_back.z))
	
	vec_forw = loc_src_extended - loc_dest_extended
	vec_forw = vec_forw.normalized()*dist # x units away
	
	corner_forw = loc_dest_extended + vec_forw
	corners.append(corner_forw)
	
	#debug_cube(Vector3(corner_forw.x, 1, corner_forw.z))
	
	
	return corners
	
	
func calculate_initial_turn(corner1, corner2, loc_src_exit, loc_src_extended, src_exit):
	#B-A: A->B 
	# 3D has no tangent()
	var tang = (Vector2(corner1.x, corner1.z)-Vector2(loc_src_extended.x, loc_src_extended.z)).tangent()
	var tang2 = (Vector2(corner2.x, corner2.z)-Vector2(loc_src_extended.x, loc_src_extended.z)).tangent()
	
	# extend them
	var tang_factor = 20 # 10 is too little for some turns
	tang = tang*tang_factor
	tang2 = tang2*tang_factor
	
	var start = Vector2(corner1.x, corner1.z) + tang
	
	#debug_cube(Vector3(start.x, 1, start.y))
	
	#positions.append(Vector3(start.x, 0, start.y))
	
	#var start = Vector2(corner1.x, corner1.z)
	var end = Vector2(corner1.x, corner1.z)# - tang
	
	#debug_cube(Vector3(end.x, 1, end.y))
	#positions.append(Vector3(end.x, 0, end.y))
	
	#var start_b = Vector2(corner2.x, corner2.z)
	var start_b = Vector2(corner2.x, corner2.z) + tang2
	#debug_cube(Vector3(start_b.x, 1, start_b.y))
	#positions.append(Vector3(start_b.x, 0, start_b.y))
	var end_b = Vector2(corner2.x, corner2.z)#-tang2
	#positions.append(Vector3(end_b.x, 0, end_b.y))
	#debug_cube(Vector3(end_b.x, 1, end_b.y))
	
	# check for intersection (2D only)
	var inters = Geometry.segment_intersects_segment_2d(start, end, start_b, end_b)
	
	if inters:
		#print("Intersect: " + str(inters))
		#positions.append(Vector3(inters.x, 0, inters.y))
		#debug_cube(Vector3(inters.x, 1, inters.y))
	
		# radius = line from intersection to corner point
		var radius = inters.distance_to(Vector2(corner1.x, corner1.z))
	
		# the point to which 0 degrees corresponds
		var angle0 = inters+Vector2(radius,0)
	
		#debug_cube(Vector3(angle0.x, 1, angle0.y))
		#positions.append(Vector3(angle0.x, 0, angle0.y))
	
		var angles = get_arc_angle(inters, Vector2(corner1.x, corner1.z), Vector2(corner2.x, corner2.z), angle0)
		# debug angles
		#positions.append(corner1)
		#positions.append(Vector3(angle0.x, 0, angle0.y))
		#positions.append(corner2)
			
						
		var points_arc = get_circle_arc(inters, radius, angles[0], angles[1], true)
	
		# back to 3D
		#for i in range(points_arc.size()):
		#	positions.append(Vector3(points_arc[i].x, 0.01, points_arc[i].y))
		
		#positions.append(loc_dest_ex)	
	
		var fin = Vector3(points_arc[points_arc.size()-1].x, 0.01, points_arc[points_arc.size()-1].y)
	
		return [radius, angles[0], angles[1], fin] #Vector3(end_point.x, 0, end_point.y)]
	else:
		print("First turn, no inters detected")

func calculate_last_turn(corner1, corner2, loc_dest_exit, loc_dest_extended, dest_ex):
	#B-A: A->B 
	# 3D has no tangent()
	var tang = (Vector2(corner1.x, corner1.z)-Vector2(loc_dest_extended.x, loc_dest_extended.z)).tangent()
	var tang2 = (Vector2(corner2.x, corner2.z)-Vector2(loc_dest_extended.x, loc_dest_extended.z)).tangent()
	
	# extend them
	var tang_factor = 20 # 10 is too little for some turns
	tang = tang*tang_factor
	tang2 = tang2*tang_factor
	var start = Vector2(corner1.x, corner1.z) + tang
	
	#debug_cube(Vector3(start.x, 1, start.y))
	
	#positions.append(Vector3(start.x, 0, start.y))
	
	#var start = Vector2(corner1.x, corner1.z)
	var end = Vector2(corner1.x, corner1.z)# - tang
	
	#debug_cube(Vector3(end.x, 1, end.y))
	#positions.append(Vector3(end.x, 0, end.y))
	
	#var start_b = Vector2(corner2.x, corner2.z)
	var start_b = Vector2(corner2.x, corner2.z) + tang2
	#debug_cube(Vector3(start_b.x, 1, start_b.y))
	#positions.append(Vector3(start_b.x, 0, start_b.y))
	var end_b = Vector2(corner2.x, corner2.z)#-tang2
	#positions.append(Vector3(end_b.x, 0, end_b.y))
	#debug_cube(Vector3(end_b.x, 1, end_b.y))
	
	# check for intersection (2D only)
	var inters = Geometry.segment_intersects_segment_2d(start, end, start_b, end_b)
	
	if inters:
		#print("Intersect: " + str(inters))
		#debug_cube(Vector3(inters.x, 1, inters.y))
	
		var radius = inters.distance_to(Vector2(corner1.x, corner1.z))
		
		# the point to which 0 degrees corresponds
		var angle0 = inters+Vector2(radius,0)
		
		#debug_cube(Vector3(angle0.x, 1, angle0.y))
		
		var angles = get_arc_angle(inters, Vector2(corner1.x, corner1.z), Vector2(corner2.x, corner2.z), angle0)
		# debug angles
		#positions.append(corner1)
		#positions.append(Vector3(angle0.x, 0, angle0.y))
		#positions.append(corner2)
	
		var points_arc = get_circle_arc(inters, radius, angles[0], angles[1], true)
		
		# back to 3D
		#for i in range(points_arc.size()):
		#	positions.append(Vector3(points_arc[i].x, 0.01, points_arc[i].y))
	
		var fin = Vector3(points_arc[points_arc.size()-1].x, 0.01, points_arc[points_arc.size()-1].y)
	
	#positions.append(loc_dest_ex)	
		return [radius, angles[0], angles[1], fin] #Vector3(end_point.x, 0, end_point.y)]
	else:
		print("Last turn, no inters detected")
	
func initial_road_test(one, two, data, loc, node):
	if data == null:
		print("No first turn data, return")
		return
		
	var radius = data[0]
	var start_angle = data[1]
	var end_angle = data[2]
	print("R: " + str(radius) + " , start angle: " + str(start_angle) + " , end: " + str(end_angle))
	
	first_turn = set_curved_road(radius, start_angle, end_angle, 0, node)
	if first_turn != null:
		first_turn.set_translation(loc)
	
		# place
		if get_child(two).get_translation().y > get_child(one).get_translation().y:
			print("Road in normal direction, positive y")
		else:
			first_turn.rotate_y(deg2rad(180))
			print("Rotated because we're going back")

func last_turn_test(one, two, data, loc, node):
	if data == null:
		print("No last turn data, return")
		return
	
	
	var radius = data[0]
	var start_angle = data[1]
	var end_angle = data[2]
	
	
	last_turn = set_curved_road(radius, start_angle, end_angle, 1, node)
	if last_turn != null:
		last_turn.set_translation(loc)
	
		# place
		if get_child(two).get_translation().y > get_child(one).get_translation().y:
			print("Road in normal direction, positive y")
		else:
			last_turn.rotate_y(deg2rad(180))
			print("Rotated because we're going back")
	
	
func set_straight(loc, loc2, node):
	var road_node = road_straight.instance()
	road_node.set_name("Road_instance 0")
	# set length
	var dist = loc.distance_to(loc2)
	#print("Distance between points: " + str(dist))
	var rounded = int(round(dist))
	#print("Rounding" + str(rounded))
	road_node.length = (rounded+1)/2 # road section length
	
	# debug
	#debug_cube(Vector3(loc.x, 1, loc.z))
	#debug_cube(Vector3(loc2.x, 1, loc2.z))
	
	var spatial = Spatial.new()
	spatial.set_name("Spatial0")
	node.add_child(spatial)
	spatial.add_child(road_node)
	
	# place
	spatial.set_translation(loc)
	
	# looking down -Z
	var tg = to_global(loc2)
	#print("Look at target: " + str(tg))
	
	road_node.look_at(tg, Vector3(0,1,0))
	# because we're pointing at +Z, sigh...
	spatial.rotate_y(deg2rad(180))
	
	
		
	
	return road_node	
	
func set_curved_road(radius, start_angle, end_angle, index, node):
	var road_node_right = road.instance()
	road_node_right.set_name("Road_instance"+String(index))

	if start_angle-90 > end_angle-90 and end_angle-90 < 0:
		print("Bad road settings: " + str(start_angle-90) + ", " + str(end_angle-90)) 
		start_angle = start_angle+360
	
	print("Road settings: start: " + str(start_angle-90) + " end: " + str(end_angle-90))	
	
	#set the angles we wanted
	# road angles are in respect to X axis, so let's subtract 90 to point down Y
	road_node_right.get_child(0).get_child(0).start_angle = start_angle-90
	road_node_right.get_child(0).get_child(0).end_angle = end_angle-90
	
	if radius < 3: # less than lanes we want
		print("Bad radius given!")
		return null
	
	#set the radius we wanted
	road_node_right.get_child(0).get_child(0).radius = radius
	
	node.add_child(road_node_right)
	return road_node_right


# assume standard rotation for now
func get_src_exit(src, dest):
	print("X abs: " + str(abs(dest.get_translation().x - src.get_translation().x)))
	print("Z abs: " + str(abs(dest.get_translation().z - src.get_translation().z)))
	
	var src_exits = src.open_exits
	
	if src_exits.size() < 0:
		print("Error, no exits left")
		return
	
	if abs(dest.get_translation().x - src.get_translation().x) > abs(dest.get_translation().z - src.get_translation().z):
		if dest.get_translation().x > src.get_translation().x:
			if src_exits.has(src.point_two):
				print("[src] " + src.get_name() + " " + dest.get_name() + " X rule")
				src_exits.remove(src_exits.find(src.point_two))
				return src.point_two
			else:
				if src_exits.has(src.point_three):
					print("[src] " + src.get_name() + " " + dest.get_name() + " X rule alt")
					src_exits.remove(src_exits.find(src.point_three))
					return src.point_three
		else:
			if src_exits.has(src.point_three):
				print("[src] " + src.get_name() + " " + dest.get_name() + " X rule inv")
				src_exits.remove(src_exits.find(src.point_three))
				return src.point_three
			else:
				if src_exits.has(src.point_one):
					print("[src] " + src.get_name() + " " + dest.get_name() + " X rule inv alt")
					src_exits.remove(src_exits.find(src.point_one))
					return src.point_one
		
		
	elif dest.get_translation().z > src.get_translation().z and src_exits.has(src.point_one):
		print("[src] " + src.get_name() + " " + dest.get_name() + " Y rule")
		src_exits.remove(src_exits.find(src.point_one))
		return src.point_one
		
	else:
		if src_exits.has(src.point_three):
			print("[src] " + src.get_name() + " " + dest.get_name() + " Y rule 2")
			src_exits.remove(src_exits.find(src.point_three))
			return src.point_three	

# assume standard rotation for now
func get_dest_exit(src, dest):
	var dest_exits = dest.open_exits
	
	if dest_exits.size() < 0:
		print("Error, no exits left")
		return
	else:
		print("available exits: " + str(dest_exits))
	
	if abs(dest.get_translation().x - src.get_translation().x) > abs(dest.get_translation().z - src.get_translation().z):
		if dest.get_translation().z > src.get_translation().z:
			if dest_exits.has(dest.point_three):
				print("[dest] " + src.get_name() + " " + dest.get_name() + " X rule a)")
				dest_exits.remove(dest_exits.find(dest.point_three))
				return dest.point_three
		else:
			if dest_exits.has(dest.point_one):
				print("[dest] " + src.get_name() + " " + dest.get_name() + " X rule b)")
				dest_exits.remove(dest_exits.find(dest.point_one))
				return dest.point_one
			else:
				print("[dest] " + src.get_name() + " " + dest.get_name() + " X rule b) alt")
				dest_exits.remove(dest_exits.find(dest.point_three))
				return dest.point_three
	
	elif dest.get_translation().z > src.get_translation().z and dest_exits.has(dest.point_three):
		print("[dest] " + src.get_name() + " " + dest.get_name() + " Y rule")
		dest_exits.remove(dest_exits.find(dest.point_three))
		return dest.point_three
		
	else:
		if dest_exits.has(dest.point_one):
			print("[dest] " + src.get_name() + " " + dest.get_name() + " Y rule 2")
			dest_exits.remove(dest_exits.find(dest.point_one))
			return dest.point_one
		else:
			print("[dest] " + src.get_name() + " " + dest.get_name() + " Y rule 2 alt")
			dest_exits.remove(dest_exits.find(dest.point_three))
			return dest.point_three

# debug
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	node.set_name("Debug")
	add_child(node)
	node.set_translation(loc)

# calculated arc is in respect to X axis
func get_arc_angle(center_point, start_point, end_point, angle0):
	var angles = []
	
	# angle between line from center point to angle0 and from center point to start point
	var angle1 = rad2deg((angle0-center_point).angle_to(start_point-center_point))
	
	if angle1 < 0:
		angle1 = 360+angle1
		#print("Angle 1 " + str(angle))
	
	#angles.append(angle)
	print("Angle 1 " + str(angle1))
	# equivalent angle for the end point
	var angle2 = rad2deg((angle0-center_point).angle_to(end_point-center_point))
	
	if angle2 < 0:
		angle2 = 360+angle2
		#print("Angle 2 " + str(angle))
	
	print("Angle 2 " + str(angle2))
	#angles.append(angle)
	
	var arc = angle1-angle2
	
	print("Arc angle " + str(arc))
		
	if arc > 200:
		print("Too big arc " + str(angle1) + " , " + str(angle2))
		angle2 = angle2+360
		
	angles = [angle1, angle2]
	
	return angles




func draw_circle_arc(center, radius, angle_from, angle_to, right, clr):
	var points_arc = get_circle_arc(center, radius, angle_from, angle_to, right)
	#print("Points: " + str(points_arc))
	
#	for index in range(points_arc.size()-1):
#		draw_line(points_arc[index], points_arc[index+1], clr, 1.5)

	
# from maths
func get_circle_arc( center, radius, angle_from, angle_to, right ):
	var nb_points = 32
	var points_arc = PoolVector2Array()

	for i in range(nb_points+1):
		if right:
			var angle_point = angle_from + i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
		else:
			var angle_point = angle_from - i*(angle_to-angle_from)/nb_points #- 90
			var point = center + Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
			points_arc.push_back( point )
	
	return points_arc

