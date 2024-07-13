extends Control

var npc_name_label
var text_label
var npc_name
var page_number

var cat_text = "res://Assets/Texts/TestText.txt"
var file

signal text_ended()

func get_ready(temp_npc_name, temp_page_number):
	npc_name = temp_npc_name
	page_number = temp_page_number
	
	npc_name_label.text = npc_name.to_upper()
	
	match npc_name:
		"cat":
			file = FileAccess.open(cat_text, FileAccess.READ)
			
	
	if page_number != -1:
		skip_to_page(page_number)
		text_label.text = file.get_line()
	else:
		text_label.text = "..."


func _ready():
	npc_name_label = %NameLabel
	text_label = %TextLabel
	


func _process(delta):
	
	if Input.is_action_just_pressed("ui_accept"):
		var line_text = file.get_line()
		if file.get_position() >= file.get_length() or line_text == "///" or page_number == -1:
			queue_free()
			emit_signal("text_ended")
		text_label.text = line_text
		

func skip_to_page(page_nr):
	var cont = 0
	while cont < page_nr:
		var temp = file.get_line()
		if temp == "///":
			cont += 1
