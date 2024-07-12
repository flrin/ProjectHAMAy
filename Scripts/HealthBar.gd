extends Control

var candle_container

var lit_candels_res = [load("res://Assets/Other/Health/image1.png"), load("res://Assets/Other/Health/image2.png"), load("res://Assets/Other/Health/image3.png"), load("res://Assets/Other/Health/image4.png"), load("res://Assets/Other/Health/image5.png"), load("res://Assets/Other/Health/image6.png"), load("res://Assets/Other/Health/image7.png"), load("res://Assets/Other/Health/image8.png")]
var unlit_candels_res = [load("res://Assets/Other/Health/image11.png"), load("res://Assets/Other/Health/image22.png"), load("res://Assets/Other/Health/image33.png"), load("res://Assets/Other/Health/image44.png"), load("res://Assets/Other/Health/image55.png"), load("res://Assets/Other/Health/image66.png"), load("res://Assets/Other/Health/image77.png"), load("res://Assets/Other/Health/image88.png")]

var candles = []
var max_candles = 8
var number_of_lit_candels = 8

# Called when the node enters the scene tree for the first time.
func _ready():
	candle_container = $HBoxContainer
	for i in range(0,8):
		var new_candle = TextureRect.new()
		new_candle.set_texture(lit_candels_res[i])
		var new_vbox = VBoxContainer.new()
		new_vbox.alignment = BoxContainer.ALIGNMENT_END
		candles.append(new_candle)
		new_vbox.add_child(new_candle)
		candle_container.add_child(new_vbox)
	
	set_max_candle_number(max_candles)


func change_candles(ammount):
	if ammount > 0:
		for i in range(number_of_lit_candels, number_of_lit_candels + ammount - 1):
			if i < max_candles:
				candles[i].texture = unlit_candels_res[i]
	else:
		for i in range(number_of_lit_candels - 1, number_of_lit_candels + ammount - 1, -1):
			if i >= 0:
				candles[i].texture = unlit_candels_res[i]
	
	number_of_lit_candels += ammount

func set_max_candle_number(num):
	for i in range(0,num):
		candles[i].visible = true
	for i in range(num,8):
		candles[i].visible = false
	
	number_of_lit_candels = num
	max_candles = num
