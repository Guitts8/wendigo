extends Node
## Barramento global de sinais de gameplay.
##
## Os objetos emitem aqui o que aconteceu no mundo; sistemas como o
## TutorialRecorder (Fase 3) e o wendigo (Fase 4) só precisam escutar,
## sem conhecer quem emitiu.

## Um item foi coletado do mundo para o inventário do jogador.
signal item_picked_up(item_id: StringName, amount: int, world_position: Vector3)

## O jogador largou um item no mundo (o recorder usa para "onde guardou itens").
signal item_dropped(item_id: StringName, amount: int, world_position: Vector3)

## O jogador comeu algo.
signal food_eaten(item_id: StringName, world_position: Vector3)

## Uma fogueira acendeu (estava apagada e recebeu combustível).
signal campfire_lit(campfire: Campfire)

## Uma fogueira apagou porque o combustível acabou.
signal campfire_extinguished(campfire: Campfire)

## A lanterna do jogador ligou ou desligou (luz visível de longe).
signal lantern_toggled(is_on: bool, world_position: Vector3)
