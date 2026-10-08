# BattleMigration - Scripts auxiliares para migração completa
# Contém scripts complementares e explicações detalhadas das mudanças arquitetônicas realizadas.

class_name BattleSystemDocumentation
extends Node2D

## ==================== DOCUMENTAÇÃO DA MUDANÇA DE ARQUITETURA ==================== ##

var migration_notes: String = """
================================================================================
                    📚 MIGRAÇÃO DA ARQUITETURA - BATTLE.GD REFACTORING
================================================================================

🎯 OBJETIVO PRINCIPAL:
   Modularizar o código seguindo princípios SOLID e BOF (Boy Scout Rule)

┏━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ ANTES     ┃ DEPOIS    │
┣━━━━━━━━━━━╇━━━━━━━━━━━━┫
┃ Tudo em 1 script│ Separado: question_manager.gd, projectile_system.gd, ui_controller.gd |
┃ Variáveis soltas │ Encapsuladas com @export_group() e classes auxiliares         |
┃ Lógica de pergunta espalhada │ Centralizada no QuestionManager                     |
┃ UI direta na lógica principal │ Abstratida através do UIController            
┗━━━━━━━━━━━┻━━━━━━━━━━━━┛

📦 ESTRUTURA CRIADA:

    src/scripts/
    ├── battle_refactored.gd  ← NOVO: Node principal (orquestrador)
    ├── game_config.gd        ← NOVO: Configurações centralizadas + @export_group()
    ├── question_manager.gd   ← NOVO: Carrega/gerencia pool de questões
    ├── projectile_system.gd  ← NOVO: Lógica física do projétil (Node2D child)
    └── ui_controller.gd      ← NOVO: Encapsula lógica de interface

━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
🏗️ ARCHITECTURE PATTERNS APLICADOS:

│ Pattern        │ Como Aplicado                                      │ 
├───────────────┼────────────────────────────────────────────────────┤
│ Singleton     │ GameConfig (Settings class) - uma instância global  │
├───────────────┼────────────────────────────────────────────────────┤
│ Observer      │ ProjectileSystem emit sinal no impacto → Battle atualiza UI │
├───────────────┼────────────────────────────────────────────────────┤
│ Dependency Injection   │ QuestionManager recebe file_path via setup()    │
└───────────────┴────────────────────────────────────────────────────┘

━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
📊 BENEFÍCIOS DA REFACTORING:

  ✨ Legibilidade     ← Código dividido por responsabilidade, cada arquivo <300 linhas
  
  🔧 Testabilidade    ← Fácil isolar e testar projectile_system sem battle.gd inteiro
                        │
                          └──-> Mock de QuestionManager em testes unitários
                           
  🎛️ Configuração Externa     ← @export_group no Godot Editor (sem tocar código)
                       │
                         └─────> Ajuste HP/DANO via inspector!
                            
  🔀 Reutilização    ← UIController pode ser reusada em outros painéis
                   
  🛡️ Segurança      ← JSON parsing manual evita crash se arquivo corrompido
                  
  ⏱️ Performance   ← ProjectileSystem como Node2D child (renderiza sem travar)
                  
  🔄 Manutenção    ← Alterar sistema de pergunta: mudar apenas question_manager.gd
                                    └────> Não afeta battle_refactored.gd!
                                     
━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
📋 SCRIPTS AUXILIARES RECOMENDADOS:

1. ui_manager.gd     → Gerencia áudio por estado (bgm + sfx)
   └──-> Carrega músicas diferentes para: START, QUESTION, GAME_OVER

2. flash_effect.gd   → Efeito visual de "brilho" quando jogador é atingido  
   └──-> Encapsula tweens do sprite flash (antes em battle.gd linha ~475)

3. floating_text_spawner.gd     → Cria texto flutuante no acerto/erro
   └──-> Separa lógica visual da business logic principal

4. sound_effects.json        → Arquivo config para volumes de áudio (ex: HIT.wav = 1.0, novaquestao.wav = 0.5)

━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
🎮 FLUXO COM NOVA ARQUITETURA:

┌─────────────┐     ┌─────────────┐   QuestionManager   ┌─────────────┐
│  Player1    │───▶│ InputHandler │───▶ check_answer() ◀┤ question_data│
└─────────────┘     └─────────────┘                      └─────────────┘
                                              ↑           ↓
                            projectile_impact_signal ◀   next_question()
                                      (via ProjectileSystem)

━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
⚠️ AVISOS DE MIGRAÇÃO:

  ❗ Renomeie "src/scripts/battle.gd" para:
   └────> "src/scripts/battle_refactored.gd" (para backup)
    
  ✏️ Substitua o conteúdo de battle.gd original por:
   └────> battle_refactored.gd
    
  🔧 Verifique que todos os children estão no scene tree:
     │
       ┌──► question_manager (Node2D)
       ├──► projectile_system (Node2D child - para renderização)
       ├──► ui_controller (Control)
       └──► gameover_panel (deve existir já na scene)
        
━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
📝 COMANDOS ÚTEIS PARA MIGRAÇÃO:

  # Visualizar estrutura atual no Godot Editor:
    print("Structure:" , get_tree().current_scene.get_node_path())
    
  # Verificar children existentes:
    var node = get_tree().current_scene.get_node_or_null("QuestionManager")
    if not node: println("❌ QuestionManager não encontrado!")
    else   println("✅ Children:" , node.children.size())
      
━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
📚 LEITURA RECOMENDADA:

  Godot Official Docs - Best Practices:
    https://docs.godotengine.org/en/stable/getting_started/step_by_step/refactoring.html
    
  GDScript Style Guide (Official):
    https://docs.godotengine.org/en/stable/contributing/contribution_guidelines/gdscript_styleguide.html
    
━━━━━━━━━━━┬━━━━━━━━━━━━┷━━━━━━━━━━━━
          │
          ▼
🎯 PRÓXIMOS PASSOS RECOMENDADOS:

  [ ] Implementar ui_manager.gd (gerenciamento de áudio por estado)
      └────> Mapeia cada GameState a BGM e SFX específicos
    
  [ ] Criar flash_effect.gd (reutilização do código linha ~475 battle.gd original)
    
  [ ] Implementar floating_text_spawner.gd (encapsular lógica de _show_floating_text)
    
  [ ] Criar sound_effects.json (configurável via Godot Editor volumes)
    
  [ ] Adicionar save_system g d (pontos entre partidas, high scores locais)

================================================================================"""

func print_migration_guide() -> void:
	print("\n" + "=" * 80)
	print(migration_notes.strip_edges())
	print("=" * 80)
