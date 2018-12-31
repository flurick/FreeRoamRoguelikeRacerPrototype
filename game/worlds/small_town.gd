extends Spatial

func _update(delta):
	if Input.is_key_pressed( KEY_RIGHT):
		position.x += 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
