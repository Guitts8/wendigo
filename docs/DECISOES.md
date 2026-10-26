# Decisões

Registro de cada decisão tomada no projeto, com data e motivo. Quando uma questão em aberto do `CLAUDE.md` for respondida, ela vem para cá.

Formato:

```
## AAAA-MM-DD — Título curto
**Decisão:** o que foi decidido.
**Motivo:** por quê.
```

---

## 2026-10-26 — Engine e linguagem
**Decisão:** Godot 4 (versão instalada: 4.7.2 stable) com GDScript de tipagem estática.
**Motivo:** definido no README/GDD; o escopo cabe bem no Godot e a tipagem estática pega erros cedo.

## 2026-10-26 — Renderizador Forward+
**Decisão:** usar o renderizador Forward+.
**Motivo:** o GDD pede fog volumétrico no `WorldEnvironment`, que só existe no Forward+.

## 2026-10-26 — Convenções de código e assets
**Decisão:** nomes de arquivos e nós em inglês, comentários em português, cenas pequenas e reaproveitáveis, placeholders CSG por enquanto.
**Motivo:** definido no README.

## 2026-10-26 — Agachar na tecla C
**Decisão:** agachar usa C (não Ctrl).
**Motivo:** preferência do autor.

## 2026-10-26 — Pulo adiado
**Decisão:** sem pulo por enquanto; `jump_velocity = 0` no Player e sem ação "jump". Decidir depois entre sem pulo (transpor por contexto), pulo livre ou pulo baixo com custo.
**Motivo:** o autor quer decidir mais tarde; o código aceita qualquer resposta.

## 2026-10-26 — Lampião em vez de lanterna
**Decisão:** a fonte de luz portátil é um lampião (luz em volta, chama que oscila), reabastecido com querosene; gordura animal entra como combustível quando houver caça. Sem pilhas por enquanto.
**Motivo:** combina com a cabana de caça e com o GDD ("Luz recupera com lenha, gordura animal"). Também muda o jogo: ilumina perto e em volta, e deixa o jogador visível de longe, o que alimenta a tensão com o wendigo.
