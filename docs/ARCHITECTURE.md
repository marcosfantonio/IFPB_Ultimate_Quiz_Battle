# Arquitetura do jogo

`battle.gd` é só o **orquestrador**: cria os módulos, liga os sinais e controla a fase
(`GamePhase.State`). Cada módulo faz uma coisa.

Regras de dependência:
- `core/` e `data/` não dependem de `systems/` nem de `ui/`.
- Os módulos de `systems/` só dependem de `core/` e `data/`; **nunca uns dos outros nem da UI**.
  Quem os conecta entre si e com a UI é o `battle.gd`, por sinais.
- Dentro de `ui/` há composição normal: `BattleHud` instancia os painéis, e os painéis
  reutilizam `LabelPlate` e `UITheme`.

```
src/scripts/
├── battle.gd                  # orquestrador (cena principal)
├── core/
│   ├── game_config.gd         # constantes: HP, dano, projétil, tempos, teclas, cores dos jogadores
│   ├── game_assets.gd         # preloads de fonte, texturas e sons
│   ├── game_phase.gd          # enum de fases (START_SCREEN, QUESTION, ...)
│   └── match_state.gd         # vida dos jogadores + vencedor (sinal hp_changed)
├── data/
│   ├── question.gd            # uma pergunta validada
│   ├── question_repository.gd # carrega o JSON, sorteia sem repetir, fallback
│   └── question_style.gd      # texto/cor das tags de dificuldade e categoria
├── systems/
│   ├── round_controller.gd    # regras da rodada: trava, quem errou, próxima pergunta
│   ├── projectile.gd          # voo em arco + rastro; emite `hit`
│   ├── input_router.gd        # tecla -> sinal (start_requested / answer_requested)
│   ├── audio_manager.gd       # BGM e SFX
│   └── idle_animator.gd       # troca de pose dos alunos
└── ui/
    ├── battle_hud.gd          # agrupa a UI de gameplay
    ├── player_panel.gd        # nome, barra de vida, sprite, flash
    ├── question_panel.gd      # enunciado, tags e alternativas
    ├── controls_hint.gd       # faixa de teclas (gerada do GameConfig)
    ├── game_over_panel.gd     # vencedor + reiniciar
    ├── start_screen.gd        # logo + "Pressione Enter"
    ├── floating_text.gd       # "ACERTOU!" / "ERROU!"
    ├── label_plate.gd         # Label sobre placa preta (componente reutilizável)
    └── ui_theme.gd            # aplica a fonte do jogo
```

## Fluxo

```
InputRouter ──answer_requested──▶ Battle ──▶ RoundController.submit_answer()
RoundController ──question_started──▶ Battle ──▶ QuestionPanel + AudioManager
RoundController ──answer_resolved───▶ Battle ──▶ destaque, texto flutuante, SFX
                                              └─ acertou ▶ Projectile.launch()
RoundController ──retry_unlocked────▶ Battle ──▶ QuestionPanel.reset_highlights()
                  (errou, o outro jogador ainda pode tentar)
Projectile ──hit──▶ Battle ──▶ MatchState.apply_damage() ──hp_changed──▶ BattleHud
                          └─ fim? GameOverPanel : RoundController.start_round()
```

## Onde mexer

| Quero...                              | Arquivo                                  |
|---------------------------------------|------------------------------------------|
| Mudar vida, dano, velocidade, tempos  | `core/game_config.gd`                    |
| Trocar teclas ou cor de um jogador    | `core/game_config.gd` (`PLAYERS`)        |
| Nova categoria ou cor de dificuldade  | `data/question_style.gd`                 |
| Trocar sprite, som ou fonte           | `core/game_assets.gd`                    |
| Regra de quem pode responder          | `systems/round_controller.gd`            |
| Visual do projétil                    | `systems/projectile.gd`                  |
| Layout de uma parte da tela           | o arquivo correspondente em `ui/`        |
