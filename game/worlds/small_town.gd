extends Spatial

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and !event.echo:
		match event.scancode:
			KEY_ESCAPE:  get_tree().quit()
			KEY_C:  goto_next_camera()
			KEY_R:   if event.control: get_tree().reload_current_scene()

var current_camera = 0
func goto_next_camera():
	var cameras = get_tree().get_nodes_in_group("camera")
	current_camera += 1
	current_camera = wrapi(current_camera, 0, cameras.size())
	cameras[current_camera].current = true