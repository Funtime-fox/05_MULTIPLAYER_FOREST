extends CharacterBody2D

# --- Параметры движения ---
var speed = 40
@export var anim: AnimatedSprite2D
@export var hand: Sprite2D
@export var item_resources: ItemData
@export var camera: Camera2D
@export var item_world_scene: PackedScene

var is_sitting = false
var equipped_tool: ItemData

# --- RPC для синхронизации ника ---
@rpc('any_peer', 'call_local')
func setup_nickname(nick):
	$Label.text = nick
	# Регистрируем в списке игроков (для Tab)
	Global.register_player(name.to_int(), nick)

func _ready() -> void:
	# Авторитет по имени узла (имя = ID игрока)
	set_multiplayer_authority(name.to_int())
	
	if is_multiplayer_authority():
		camera.enabled = true
		# Отправляем свой ник всем игрокам!
		setup_nickname.rpc(Global.name_player) 
		Global.add_item(item_resources)
	else:
		camera.enabled = false
	
	# Включаем камеру только у своего персонажа
	if is_multiplayer_authority():
		camera.enabled = true
		# Сообщаем всем свой ник
		setup_nickname.rpc(Global.name_player)
	else:
		camera.enabled = false
	
	# Инвентарь инициализируем только у локального игрока,
	# чтобы не дублировать предметы в Global у клиентов
	if is_multiplayer_authority():
		Global.add_item(item_resources)

func _physics_process(_delta):
	# Управлять можем только своим телом
	if not is_multiplayer_authority(): 
		return
	
	var input = Vector2(
		Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left'),
		Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up')
	)
	
	velocity = input.normalized() * speed

	# Сидение отменяет движение
	if is_sitting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Разворот спрайта
	if input.x > 0:
		anim.flip_h = true
	elif input.x < 0:
		anim.flip_h = false

	# Анимация
	if input != Vector2.ZERO:
		anim.play('walk')
	else:
		anim.play('idle')
		
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# Ввод обрабатываем только у своего персонажа
	if not is_multiplayer_authority():
		return
	
	if event.is_action_pressed('use_tool'):
		if Global.inventory.size() > 0:
			var item = Global.inventory[0]
			if item.is_tool:
				if hand.texture == null:
					hand.texture = item.icon
				else:
					hand.texture = null
	
	if event.is_action_pressed('interact'):
		if is_sitting:
			is_sitting = false
			anim.play('idle')
		else:
			is_sitting = true
			anim.play('sit')
	
	if event.is_action_pressed('next_item'):
		change_selection(1)
	if event.is_action_pressed('prev_item'):
		change_selection(-1)
	if event.is_action_pressed('drop_item'):
		drop_item()


func change_selection(direction: int):
	if Global.inventory.size() == 0: 
		return
	
	Global.active_slot_index = (Global.active_slot_index + direction) % Global.inventory.size()
	if Global.active_slot_index < 0: 
		Global.active_slot_index = Global.inventory.size() - 1
	
	Global.update_selection_visual.emit()
	update_hand_visual()
	
func update_hand_visual():
	if Global.inventory.size() == 0:
		hand.texture = null
		equipped_tool = null
		return
	var item = Global.inventory[Global.active_slot_index]
	if item:
		hand.texture = item.icon
		equipped_tool = item if item.is_tool else null
	else:
		hand.texture = null
		equipped_tool = null


# --- Выброс предмета: должен выполняться на сервере ---
func drop_item():
	if Global.inventory.size() == 0:
		return
	
	# Спавнить предмет в мире имеет право только сервер
	# (иначе у каждого игрока появится своя копия)
	if not multiplayer.is_server():
		return
	
	var item_to_drop = Global.inventory[Global.active_slot_index]
	Global.inventory.remove_at(Global.active_slot_index)
	
	spawn_dropped_item(item_to_drop)
	
	Global.active_slot_index = clamp(Global.active_slot_index, 0, Global.inventory.size() - 1)
	Global.inventory_updated.emit()
	update_hand_visual()

func spawn_dropped_item(item_to_drop: ItemData):
	var new_item = item_world_scene.instantiate()
	new_item.item_resources = item_to_drop
	
	var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	new_item.position = self.position + random_offset
	
	get_tree().current_scene.add_child(new_item)
