extends Node2D

@onready var _MainWindow: Window = get_window()
@onready var char_sprite: AnimatedSprite2D = $CanvasLayer/VBoxContainer/Character/Control/MarginContainer/AnimatedSprite2D
@onready var emitter: CPUParticles2D = $CanvasLayer/VBoxContainer/Character/CPUParticles2D
@onready var text_box: MarginContainer = $CanvasLayer/VBoxContainer/Character/Control/TextBox
@onready var char_polygon: CollisionPolygon2D = $CanvasLayer/VBoxContainer/Character/Control/MarginContainer/AnimatedSprite2D/Area2D/CollisionPolygon2D

var player_size: Vector2i = Vector2i(400,400)
#The offset between the mouse and the character
var mouse_offset: Vector2i = Vector2i.ZERO
var dragging: bool = false
var selected: bool = false
#This will be the position of the pet above the taskbar
var taskbar_pos: int = (DisplayServer.screen_get_usable_rect().end.y - player_size.y)
var screen_width: int = DisplayServer.screen_get_usable_rect().size.x
var screen_height: int = DisplayServer.screen_get_usable_rect().size.y

var is_giving_advice: bool = false

var url = "https://api.adviceslip.com/advice"
var updated_array = PackedVector2Array()

var is_walking: bool = false
var walk_direction: int = 1
const WALK_SPEED = 150

func _ready():
	# Change the size of the window
	_MainWindow.min_size = player_size
	_MainWindow.size = _MainWindow.min_size
	# Places the character in the middle of the screen and on top of the taskbar
	@warning_ignore("integer_division")
	_MainWindow.position = Vector2(DisplayServer.screen_get_size().x/2 - (player_size.x/2), taskbar_pos)
	_MainWindow.always_on_top = true  
	text_box.visible = false
	_MainWindow.grab_focus()   
	
	for vec in char_polygon.polygon:
		var pos = (get_viewport().canvas_transform * global_position)
		updated_array.append(vec * 7 + pos + Vector2(100, 250))
	_MainWindow.mouse_passthrough_polygon = updated_array

func _process(delta):
	if dragging:
		drag_window()
	if is_walking:
		walk(delta)
	
	# Emit hearts when pet
	if Input.is_action_just_pressed("click"):
		emitter.emitting = true

func _input(event):
	if event.is_action_pressed("click"):
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		print("left mouse click")
		emitter.restart()
		dragging = true
		# offset relative to top-left corner of window
		mouse_offset = event.position
	elif event.is_action_released("click"):
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		dragging = false
		
func drag_window():
	# get global mouse pos in screen coords
	var global_mouse = DisplayServer.mouse_get_position()
	# move window so that the relative offset stays consistent
	_MainWindow.position = Vector2(global_mouse - mouse_offset)

func clamp_on_screen_width(pos, player_width):
	return clampi(pos, 0, screen_width - player_width)

func walk(delta):
	# Moves the pet
	_MainWindow.position.x = _MainWindow.position.x + WALK_SPEED * delta * walk_direction
	# Clamps the pet position on the width of screen
	_MainWindow.position.x = clampi(_MainWindow.position.x, 0
			,clamp_on_screen_width(_MainWindow.position.x, player_size.x))
	# Changes direction if it hits the sides of the screen
	if ((_MainWindow.position.x == (screen_width - player_size.x)) or (_MainWindow.position.x == 0)):
		walk_direction = walk_direction * -1
		char_sprite.flip_h = !char_sprite.flip_h

func choose_direction():
	if (randi_range(1,2) == 1):
		walk_direction = 1
		char_sprite.flip_h = true
	else:
		walk_direction = -1
		char_sprite.flip_h = false

func _on_character_walking():
	is_walking = true
	print("is walking")
	choose_direction()

func _on_character_finished_walking():
	is_walking = false

func _on_character_giving_advice():
	pass
	
func _on_character_finished_giving_advice():
	if text_box.visible:
		text_box.visible = false
	
