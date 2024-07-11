extends Control

var health_bar
# Called when the node enters the scene tree for the first time.
func _ready():
	health_bar = $HealthBar


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func change_health(num):
	health_bar.change_candles(-num)
