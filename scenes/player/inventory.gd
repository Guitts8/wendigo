class_name Inventory
extends Node
## Inventário por quantidade, limitado pelo peso total.
## Os pesos ficam numa tabela aqui por enquanto; quando houver mais itens,
## isso vira um Resource de definição de item.

signal changed(item_id: StringName, amount: int)

const DEFAULT_ITEM_WEIGHT: float = 1.0
## Peso de cada item em kg.
const ITEM_WEIGHTS: Dictionary = {
	&"firewood": 2.0,
}

## Peso máximo carregado em kg.
@export var max_weight: float = 20.0

var _items: Dictionary[StringName, int] = {}


func get_amount(item_id: StringName) -> int:
	return _items.get(item_id, 0)


func has(item_id: StringName, amount: int = 1) -> bool:
	return get_amount(item_id) >= amount


func get_item_weight(item_id: StringName) -> float:
	return ITEM_WEIGHTS.get(item_id, DEFAULT_ITEM_WEIGHT)


func get_total_weight() -> float:
	var total: float = 0.0
	for item_id: StringName in _items:
		total += get_item_weight(item_id) * _items[item_id]
	return total


func can_add(item_id: StringName, amount: int = 1) -> bool:
	# Pequena folga para não barrar por erro de arredondamento.
	return get_total_weight() + get_item_weight(item_id) * amount <= max_weight + 0.001


func add(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or not can_add(item_id, amount):
		return false
	_items[item_id] = get_amount(item_id) + amount
	changed.emit(item_id, _items[item_id])
	return true


func remove(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or not has(item_id, amount):
		return false
	var remaining: int = get_amount(item_id) - amount
	if remaining == 0:
		_items.erase(item_id)
	else:
		_items[item_id] = remaining
	changed.emit(item_id, remaining)
	return true
