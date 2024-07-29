extends CanvasLayer

@onready var timer_label: Label = %"Timer Label"
@onready var meat_label: Label = %"Meat Label"

func _process(delta):
	timer_label.text = GameManager.time_elapsed_string
	meat_label.text = str(GameManager.meat_counter)
