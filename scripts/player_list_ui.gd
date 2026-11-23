extends CanvasLayer

# Ссылки на узлы сцены (заполняются при _ready)
@onready var panel: PanelContainer = $Panel
@onready var entries: VBoxContainer = $Panel/Margin/VBox/Entries


func _ready() -> void:
	# По умолчанию панель скрыта
	panel.visible = false

	# Подписываемся на изменения реестра игроков
	Global.players_changed.connect(_refresh)

	# Первичная отрисовка (вдруг на момент _ready кто-то уже в игре)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	# Tab зажат — показываем панель и обновляем список
	if event.is_action_pressed("ui_focus_next"):
		_refresh()
		panel.visible = true

	# Tab отпущен — скрываем панель
	elif event.is_action_released("ui_focus_next"):
		panel.visible = false


func _refresh() -> void:
	for child in entries.get_children():
		child.queue_free()

	# Добавляем строку на каждого игрока
	for p in Global.get_players_sorted():
		var lbl := Label.new()
		lbl.text = "[%d] %s" % [p.id, p.nick]
		entries.add_child(lbl)
