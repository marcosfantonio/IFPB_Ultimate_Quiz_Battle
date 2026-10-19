# IFPB Ultimate Quiz Battle

Jogo de perguntas competitivo para dois jogadores, desenvolvido em Godot. Os jogadores respondem
simultaneamente às questões: cada acerto dispara uma bola de papel contra o adversário. Vence quem
esgotar primeiro a vida do oponente.

O professor pune respostas excessivamente rápidas: três respostas abaixo de 2 segundos em questões
consecutivas, ou dois acertos consecutivos nesse intervalo, acionam o fatality e causam 40% da vida
máxima de dano ao jogador responsável.

## Como executar

1. Abra `src/project.godot` no Godot 4.7 ou superior.
2. Execute o projeto com **F6/F5** ou pelo botão **Executar projeto**.
3. No menu inicial, pressione **Enter**, escolha **Nova Batalha** e informe os nomes dos
   representantes e das equipes.

## Controles

| Ação | Player 1 | Player 2 |
|---|---|---|
| Selecionar alternativa 1 | `1` | `Z` |
| Selecionar alternativa 2 | `2` | `X` |
| Selecionar alternativa 3 | `3` | `C` |

- No menu: **↑/↓** para escolher e **Enter** para confirmar.
- **Esc** volta das telas de opções, cadastro e criador de questões.
- Debug: digite `VENCEU` durante uma pergunta para o Player 1 acertar um golpe letal, ou `TRIGGER`
  para executar o fatality do professor contra o Player 2.

## Bancos de questões

No menu **Criador de Questoes**, é possível criar ou importar bancos JSON, editar questões,
alternativas, resposta correta, categoria e dificuldade, exportar o banco e selecioná-lo para a
próxima partida. Cada questão usa três alternativas.

## Tecnologias

- Godot Engine 4.7+
- GDScript e cenas `.tscn`
- Resolução-base: 1152×648 (16:9)

## Screenshots

<p align="center">
  <a href="src/screenshots/screenshot1.png"><img src="src/screenshots/screenshot1.png" width="49%" alt="Screenshot 1"></a>
  <a href="src/screenshots/screenshot2.png"><img src="src/screenshots/screenshot2.png" width="49%" alt="Screenshot 2"></a>
</p>
<p align="center">
  <a href="src/screenshots/screenshot3.png"><img src="src/screenshots/screenshot3.png" width="49%" alt="Screenshot 3"></a>
  <a href="src/screenshots/screenshot4.png"><img src="src/screenshots/screenshot4.png" width="49%" alt="Screenshot 4"></a>
</p>
<p align="center">
  <a href="src/screenshots/screenshot5.png"><img src="src/screenshots/screenshot5.png" width="49%" alt="Screenshot 5"></a>
  <a href="src/screenshots/screenshot6.png"><img src="src/screenshots/screenshot6.png" width="49%" alt="Screenshot 6"></a>
</p>
<p align="center">
  <a href="src/screenshots/screenshot7.png"><img src="src/screenshots/screenshot7.png" width="49%" alt="Screenshot 7"></a>
  <a href="src/screenshots/screenshot8.png"><img src="src/screenshots/screenshot8.png" width="49%" alt="Screenshot 8"></a>
</p>
<p align="center">
  <a href="src/screenshots/screenshot9.png"><img src="src/screenshots/screenshot9.png" width="49%" alt="Screenshot 9"></a>
  <a href="src/screenshots/screenshot10.png"><img src="src/screenshots/screenshot10.png" width="49%" alt="Screenshot 10"></a>
</p>
