extends CanvasLayer

@onready var log_label: RichTextLabel = $Root/VBox/Log
@onready var msg_input: LineEdit = $Root/VBox/InputRow/MsgInput
@onready var send_btn: Button = $Root/VBox/InputRow/SendBtn
@onready var input_row: HBoxContainer = $Root/VBox/InputRow

var is_typing: bool = false

func _ready() -> void:
	Global.chat_ui = self
	log_label.visible = false 
	input_row.visible = false
	
	msg_input.text_submitted.connect(_on_enter_pressed)
	send_btn.pressed.connect(_send_message)
	msg_input.focus_entered.connect(func(): is_typing = true)
	msg_input.focus_exited.connect(func(): is_typing = false)
	
	# Подключаем обработку клавиш прямо в поле ввода
	msg_input.gui_input.connect(_on_msg_input_gui_input)

func _on_msg_input_gui_input(event: InputEvent) -> void:
	# Проверяем, что это нажатие клавиши и это именно Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_chat()
		get_viewport().set_input_as_handled() # Блокируем дальнейшую передачу клавиши
	# То же самое для кнопки Y (если захочешь закрывать и ей)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Y:
		_close_chat()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# Это сработает, если поле ввода ЗАКРЫТО (фокус не в нем)
	if event.is_action_pressed("toggle_chat"):
		if not input_row.visible:
			log_label.visible = true
			input_row.visible = true
			msg_input.grab_focus()

func _close_chat() -> void:
	log_label.visible = false
	input_row.visible = false
	msg_input.release_focus()
	is_typing = false

func _on_enter_pressed(_new_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var text = msg_input.text.strip_edges()
	if text.is_empty():
		return
	
	broadcast_message.rpc(Global.name_player, text)
	
	msg_input.text = ""
	input_row.visible = false
	msg_input.release_focus()
	is_typing = false

@rpc('any_peer', 'call_local', 'reliable')
func broadcast_message(nick: String, text: String) -> void:
	text = text.substr(0, 200)
	var safe_nick = nick.to_utf8_buffer().get_string_from_utf8()
	var safe_text = text.to_utf8_buffer().get_string_from_utf8()
	
	var formatted_text = "[color=#8fd3ff]%s[/color]: %s\n" % [safe_nick, safe_text]
	log_label.append_text(formatted_text)
	log_label.scroll_to_line(log_label.get_line_count() - 1)
