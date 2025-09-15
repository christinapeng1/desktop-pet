extends Node2D

@onready var sprite = $Control/MarginContainer/AnimatedSprite2D
@onready var timer = $Timer
@onready var text_box = $Control/TextBox
@onready var advice = $Control/TextBox/MarginContainer/Label
@onready var http_request = $HTTPRequest

var pet_state : int = STATE.IDLE
var url = "https://api.adviceslip.com/advice"

#signals to send when entering and leaving states
signal walking
signal finished_walking
signal giving_advice
signal finished_giving_advice

enum STATE{
	IDLE,
	LOOK_AROUND,
	WALK,
	SLEEP,
	DEEP_SLEEP,
	ADVICE
}

func _ready(): 
	pet_state = STATE.LOOK_AROUND
	sprite.play("look_around")
	timer.start()

func _on_timer_timeout():
	if pet_state == STATE.WALK:
		finished_walking.emit()
	if pet_state == STATE.ADVICE:
		finished_giving_advice.emit()
	
	await change_state()
	
	#Timer can change according to state and is random
	match pet_state:
		STATE.IDLE :
			timer.set_wait_time(randi_range(20, 100))
			sprite.play("idle")
		STATE.LOOK_AROUND:
			timer.set_wait_time(randi_range(1, 2))
			sprite.play("look_around")
		STATE.WALK:
			timer.set_wait_time(randi_range(5, 20))
			sprite.play("walk")
		STATE.SLEEP:
			timer.set_wait_time(randi_range(20, 100))
			sprite.play("sleep")
		STATE.DEEP_SLEEP:
			timer.set_wait_time(randi_range(20, 100))
			sprite.play("deep_sleep")
		STATE.ADVICE:
			timer.set_wait_time(randi_range(10, 30)) 
			sprite.play("idle")
			await call_advice_api()
	timer.start()

func change_state():
	pet_state = randi_range(0,5)
	print("state changed to ", pet_state)
	if pet_state == STATE.WALK:
		walking.emit()
	if pet_state == STATE.ADVICE:
		giving_advice.emit()
		
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if pet_state == STATE.WALK:
			finished_walking.emit()
		if pet_state == STATE.ADVICE:
			finished_giving_advice.emit()
		pet_state = STATE.LOOK_AROUND
		sprite.play("look_around")

func call_advice_api():
	if http_request.get_http_client_status() == HTTPClient.STATUS_CONNECTED:
		print("Request already in progress, skipping new call.")
		return
	print("Fetching advice...")
	http_request.request(url)

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())
	var advice_text = data["slip"]["advice"]
	set_advice_text(advice_text)
	text_box.visible = true
	print(data)

const WRAP_THRESHOLD = 30  # max chars before wrapping

func set_advice_text(advice_text: String):
	advice.text = advice_text
	
	if advice_text.length() > WRAP_THRESHOLD:
		advice.autowrap_mode = TextServer.AUTOWRAP_WORD  # or AUTOWRAP_ARBITRARY
		advice.custom_minimum_size.x = 180  # desired wrap width (px)
	else:
		advice.autowrap_mode = TextServer.AUTOWRAP_OFF
		advice.custom_minimum_size.x = 0  # let it shrink
