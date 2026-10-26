class_name Interactable
extends StaticBody3D
## Classe base para tudo que o jogador pode usar com a tecla de interação.
##
## O Interactor do jogador mira no corpo de colisão, pergunta o texto com
## get_prompt(), checa can_interact() e chama interact().
## Cenas que herdam devem ficar na camada de física "interactable" (3).

## Texto padrão mostrado no HUD ao mirar no objeto.
@export var prompt_text: String = "Interagir"


func get_prompt(_player: Player) -> String:
	return prompt_text


func can_interact(_player: Player) -> bool:
	return true


func interact(_player: Player) -> void:
	pass
