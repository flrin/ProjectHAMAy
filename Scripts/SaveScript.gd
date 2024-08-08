extends Node

class_name SaveManager

var main_node

func get_ready(main_n):
	
	main_node = main_n

func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var save_nodes = main_node.get_tree().get_nodes_in_group("saveable")
	
	for node in save_nodes:
		var node_data = node.save()
		var json_srting = JSON.stringify(node_data)
		save_file.store_line(json_srting)
		print(json_srting)
	
	save_file.close()
	

func load_game():
	for i in main_node.get_tree().get_nodes_in_group("saveable"):
		i.queue_free()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	
	print(save_file.get_as_text())
	
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()
		json.parse(json_string)
		var node_data = json.get_data()
		
		var new_node = load(node_data["scene_name"]).instantiate()
		main_node.get_node(node_data["parent"]).add_child(new_node)
		new_node.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		
		for i in node_data.keys():
			if i != "scene_name" or i != "parent" or i != "pos_x" or i != "pos_y":
				new_node.set(i, node_data[i])
	
	save_file.close()
