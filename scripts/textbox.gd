extends MarginContainer

@onready var label = $MarginContainer/Label

const MAX_WIDTH = 330

func display_text(advice : String):
	label.text = advice
	
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
