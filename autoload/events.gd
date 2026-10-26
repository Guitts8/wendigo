extends Node
## Barramento global de sinais de gameplay.
##
## Os objetos emitem aqui o que aconteceu no mundo; sistemas como o
## TutorialRecorder (Fase 3) e o wendigo (Fase 4) só precisam escutar,
## sem conhecer quem emitiu.

## Um item foi coletado do mundo para o inventário do jogador.
signal item_picked_up(item_id: StringName, amount: int, world_position: Vector3)

## Uma fogueira acendeu (estava apagada e recebeu combustível).
signal campfire_lit(campfire: Campfire)

## Uma fogueira apagou porque o combustível acabou.
signal campfire_extinguished(campfire: Campfire)
