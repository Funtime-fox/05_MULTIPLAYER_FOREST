extends Node

# СИГНАЛЫ

# Сигнал передаёт имя собранного предмета
signal item_collected(item_name: String)

# Сигнал обновления визуального выделения активного слота в хотбаре
signal update_selection_visual

# Сигнал уведомления об обновлении инвентаря
signal inventory_updated

# Сигнал изменения реестра игроков (для таб-списка)
signal players_changed


# ИГРОК

# Ник локального игрока (заполняется на экране ввода имени)
var name_player: String = "Player"

# Ссылка на ChatUI (заполняется в ChatUI._ready)
# Используется в Player для блокировки движения во время печати
var chat_ui: CanvasLayer = null

# Реестр игроков: id (int) -> nickname (String)
var players: Dictionary = {}



# ИНВЕНТАРЬ

var inventory: Array[ItemData] = []
@export var max_inventory_size: int = 10
var amount: int
var active_slot_index: int = 0


func add_item(item: ItemData):
	# 1. Проверяем, есть ли уже такой предмет в массиве инвентаря
	var index = inventory.find(item)

	if index != -1:
		# Если предмет найден, увеличиваем его количество внутри самого ресурса
		inventory[index].amount += 1
		inventory_updated.emit()
	else:
		# 2. Если предмета нет, проверяем, есть ли свободное место для нового слота
		if inventory.size() < max_inventory_size:
			# Убеждаемся, что у нового предмета количество хотя бы 1
			if item.amount == 0:
				item.amount = 1
			inventory.append(item)
			inventory_updated.emit()


func register_player(id: int, nick: String) -> void:
	# Если запись уже есть и ник тот же — не дёргаем сигнал зря
	if players.get(id) == nick:
		return
	players[id] = nick
	players_changed.emit()


func unregister_player(id: int) -> void:
	if players.erase(id):
		players_changed.emit()


func get_players_sorted() -> Array:
	var ids = players.keys()
	ids.sort()
	var result = []
	for id in ids:
		result.append({ "id": id, "nick": players[id] })
	return result
