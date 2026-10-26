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

## 2026-10-26 — Como o colega morre (questão 2)
**Decisão:** ferimento que infecciona. Ele se machuca na chegada (perna), fica de cama e a ferida vira febre até a morte.
**Motivo:** explica por que ele não ajuda, ensina o curativo e a piora é inevitável sem parecer falha do jogador na mecânica.

## 2026-10-26 — Canibalismo no tutorial (questão 3)
**Decisão:** sugerido, com marcas. A tela escurece e só se ouve o som; depois, corpo coberto e sangue nas mãos na câmera.
**Motivo:** barato de produzir, respeitoso com o tema e mais perturbador do que mostrar.

## 2026-10-26 — Rejogar o tutorial (questão 6)
**Decisão:** sim, por uma opção "Novo vale" que rejoga o tutorial e substitui o wendigo ativo. Os registros antigos ficam no histórico, mas só um fica ativo.
**Motivo:** permite testar e corrigir sem perder o peso da escolha; o histórico prepara o ciclo e a questão 7.

## 2026-10-26 — Vozes no protótipo (questão 8)
**Decisão:** só legendas por enquanto. Cada fala aceita um áudio opcional para entrar depois sem mudar o roteiro.
**Motivo:** o roteiro ainda vai mudar muito; gravar agora seria retrabalho.
