extends Spatial

export(String) var player_name = "一郎"
export(String) var romaji = "Ichiro"

onready var panel = get_node("BODY").get_node("Viewport").get_node("Nametag")
onready	var nameplate = get_node("BODY").get_node("Viewport 2").get_node("nameplate")


func _ready():
	set_name("???")


func select_name(s_name, s_romaji):
	player_name = s_name
	romaji = s_romaji
	set_name("???")


func set_name(arg):
	
	if player_name != "" and romaji != "":
		panel.set_name(romaji)
		nameplate.set_name(player_name)