extends Node
## Catálogo de itens por id. Para criar um item novo, crie o .tres em
## data/items/ e adicione-o em data/items/item_catalog.tres.

const CATALOG: ItemCatalog = preload("res://data/items/item_catalog.tres")

var _by_id: Dictionary[StringName, ItemData] = {}


func _ready() -> void:
	for item: ItemData in CATALOG.items:
		if _by_id.has(item.id):
			push_error("Item com id repetido no catálogo: %s" % item.id)
		_by_id[item.id] = item


func has_item(item_id: StringName) -> bool:
	return _by_id.has(item_id)


func get_item(item_id: StringName) -> ItemData:
	if not _by_id.has(item_id):
		push_error("Item desconhecido: %s" % item_id)
		return null
	return _by_id[item_id]
