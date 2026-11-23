extends CanvasLayer

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var network_layer: CanvasLayer
@export var ip_input: LineEdit
@onready var name_input: LineEdit = $Menu/NameInput

func _ready():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	name_input.text_submitted.connect(func(_text): _on_host_btn_pressed())

func _on_host_btn_pressed():
	# Сохраняем имя в Global
	Global.name_player = name_input.text.strip_edges()
	if Global.name_player.is_empty():
		Global.name_player = "Игрок 1" # Дефолтное имя, если поле пустое
		
	peer.create_server(7000)
	multiplayer.multiplayer_peer = peer
	add_player(1)
	network_layer.hide() # Скрываем меню

func _on_join_btn_pressed():
	# Сохраняем имя в Global
	Global.name_player = name_input.text.strip_edges()
	if Global.name_player.is_empty():
		Global.name_player = "Игрок" # Дефолтное имя, если поле пустое
		
	var ip = ip_input.text
	peer.create_client(ip, 7000)
	multiplayer.multiplayer_peer = peer
	network_layer.hide() # Скрываем меню
	# Клиент не вызывает add_player, так как сервер сам его создаст и разошлет через MultiplayerSpawner

func add_player(id):
	if not multiplayer.is_server():
		return
	var p = player_scene.instantiate()
	p.name = str(id)
	p.position = Vector2(100, 50)
	get_parent().add_child(p)

func remove_player(id):
	var p = get_parent().get_node_or_null(str(id)) # <--- ИСПРАВЛЕНО: ищем в родителе
	if p: p.queue_free()
