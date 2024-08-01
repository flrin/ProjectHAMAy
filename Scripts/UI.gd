extends Control

var player

var health_bar

var text_box_scene = load("res://Scenes/TextBox.tscn")

var cat_max_page_number = 3
var cat_page_number = 0

var candle_totem_max_page_number = 0
var candle_totem_page_number = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	health_bar = $HealthBar
	player = get_node("../../Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func change_health(attack):
	health_bar.change_candles(-attack.attack_damage)

func change_max_health(num):
	health_bar.change_max_candles(num)

func get_max_candles():
	return health_bar.max_candles

func interacted_with_npc(npc):
	var temp_max
	var temp_nr
	
	match npc.get_npc_name():
		"cat":
			temp_max = cat_max_page_number
			temp_nr = cat_page_number
			cat_page_number += 1
		"candle_totem":
			temp_max = candle_totem_max_page_number
			temp_nr = candle_totem_page_number
			candle_totem_page_number += 1
	

	
	var text_box_node = text_box_scene.instantiate()
	var npc_name = npc.get_npc_name()
	
	add_child(text_box_node)
	
	if temp_max >= temp_nr:
		text_box_node.get_ready(npc_name, temp_nr)
	else:
		text_box_node.get_ready(npc_name, -1)
	
	text_box_node.text_ended.connect(player.text_ended)
