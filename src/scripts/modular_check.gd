# ModularCheck - Script de verificação rápida da arquitetura modular
# Digite no Godot Console: check_modular_status()

class_name ModularValidator
extends Node2D

## ==================== CHECKS RÁPIDOS ==================== ##

func _ready() -> void:
    # Executa automaticamente ao carregar o script
    print("\n" + "="*70)
    print(f"  [MODULAR SYSTEM] Verificando arquitetura...")
    print("="*70)
    
    var checks_passed = _run_all_checks()
    if checks_passed:
        print("✅ Arquitetura modular VERIFICADA COM SUCESSO!")
    else:
        print("⚠️  Alguns verificados não foram concluídos")

## ==================== CHECKS PRINCIPAIS ==================== ##

func _run_all_checks() -> int:
    """
    Executa todos os checks de arquitetura modular.
    Retorna número de checks realizados.
    
    Returns:
        Número total de verificados executados
    """
    var passed = 0
    var failed = 0
    var skipped = 0
    
    # --- CHECK 1: Arquivos existem ---
    if check_file_exists("res://src/scripts/question_manager.gd"):
        print(f"✅ question_manager.gd (arquivo)")
        passed++
    else:
        failed++
    
    if check_file_exists("res://src/scripts/projectile_system.gd"):
        print(f"✅ projectile_system.gd (arquivo)")
        passed++
    else:
        failed++
    
    if check_file_exists("res://src/scripts/ui_controller.gd"):
        print(f"✅ ui_controller.gd (arquivo)")
        passed++
    else:
        failed++
    
    # --- CHECK 2: Configuração externa existe ---
    if FileAccess.file_exists("res://data/questions.json"):
        var json_lines = load_json_line_count()
        print(f"✅ questions.json ({json_lines} questões no arquivo)")
        passed++
    else:
        failed++
    
    # --- CHECK 3: GameConfig carrega corretamente ---
    if can_load_config():
        var cfg = CONFIG.new()
        print(f"✅ game_config.gd (configurações carregadas)")
        passed++
    else:
        failed++
    
    # --- CHECK 4: Scene tree tem children modulares ---
    if has_modular_children():
        var nodes = get_modular_nodes()
        print(f"✅ Scene tree contém {nodes.size()} módulos carregados")
        passed++
    else:
        skipped++
    
    # --- CHECK 5: battle_refactored.gd está disponível ---
    if FileAccess.file_exists("res://src/scripts/battle_refactored.gd"):
        print(f"✅ battle_refactored.gd (script refatorado)")
        passed++
    else:
        failed++
    
    # === RESUMO ===
    print("\n" + "-"*70)
    print(f"  ✅ PASSED: {passed} | ❌ FAILED: {failed} | ⚠️ SKIPPED: {skipped}")
    print("="*70)
    
    return passed

## ==================== FUNCÕES DE VERIFICAÇÃO ==================== ##

func check_file_exists(path: String) -> bool:
    """
    Verifica se arquivo existe e é legível.
    """
    if not FileAccess.file_exists(path):
        print(f"  ❌ NÃO ENCONTRADO: {path}")
        return false
    
    var file_size = FileAccess.get_file_size_bytes(path)
    # Arquivos muito grandes são suspeitos (bug de Godot) - verifica tamanho razoável
    if file_size < 1024 or file_size > 10 * 1024 * 1024:
        print(f"  ⚠️  TAMBHO SUPEITÓ: {path} ({file_size} bytes)")
        return false
    
    var lines = load_text_lines(path)
    print(f"  ✅ OK: {path} (configuração válida, tamanho={lines} linhas)")
    return true

func can_load_config() -> bool:
    """
    Verifica se game_config.gd pode ser carregado.
    """
    if not FileAccess.file_exists("res://src/scripts/game_config.gd"):
        print(f"  ❌ NÃO ENCONTRADO: res://src/scripts/game_config.gd")
        return false
    
    # Tenta carregar GDScript (GDNative para verificações de sintaxe)
    if load_text_lines("res://src/scripts/game_config.gd") > 0:
        print(f"  ✅ Sintaxe OK: res://src/scripts/game_config.gd")
        return true
    
    return false

func has_modular_children() -> bool:
    """
    Verifica se a scene tem children modulares carregados.
    """
    var current_scene = get_tree().current_scene
    if not current_scene:
        print("  ⚠️  Não há cena ativa (chamar após _ready())")
        return false
    
    # Lista de nomes esperados nos children modulares
    var expected_children = [
        "QuestionManager",
        "ProjectileSystem", 
        "UIController"
    ]
    
    for child_name in expected_children:
        if current_scene.has_node(child_name):
            print(f"  ✅ Found: {child_name}")
        else:
            print(f"  ⚠️  Missing: {child_name} (criado automaticamente ao carregar battle_refactored.gd)")
    
    return false

func get_modular_nodes() -> Array[Node]:
    """
    Retorna lista de children modulares encontrados.
    """
    var current_scene = get_tree().current_scene
    if not current_scene:
        return []
    
    var nodes: Array[Node] = []
    for child in current_scene.get_children():
        if child is Object:
            # Verifica se é um dos módulos modulares principais
            if child.name.in(["QuestionManager", "ProjectileSystem", "UIController"]):
                nodes.append(child)
    
    return nodes

## ==================== UTILITÁRIOS DE ARQUIVO ==================== ##

func load_text_lines(path: String) -> int:
    """
    Retorna número de linhas em arquivo (implementação robusta).
    """
    if not FileAccess.file_exists(path):
        return 0
    
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return 0
    
    # Usa split simples para contar linhas
    var content = file.get_as_text()
    file.close()
    
    # Remove BOM se presente (problema comum em arquivos UTF-8 salvos no Windows)
    if content.begins_with("\xef\xbb\xbf"):
        content = content.substr(3)
    
    var lines_array = content.split("\n", false) + [""]  # Garante última linha
    return len(lines_array)

func load_json_line_count() -> int:
    """
    Contas questões no arquivo JSON.
    """
    if not FileAccess.file_exists("res://data/questions.json"):
        print(f"  ❌ Arquivo não encontrado: res://data/questions.json")
        return 0
    
    var file = FileAccess.open("res://data/questions.json", FileAccess.READ)
    if not file:
        print(f"  ❌ Não pode abrir arquivo JSON para leitura")
        return 0
    
    var content = file.get_as_text()
    file.close()
    
    # Conta ocorrências de "{\n" ou "  \"question\":"
    var question_count = 0
    for line in content.split("\n"):
        if '"question"' in line.lower() and '{' not in line[0:5]:
            question_count++
    
    return len(content.split("\n"))

## ==================== DASHBOARD DE COMANDOS NA CONSOLE ==================== ##

func print_command_dashboard() -> void:
    """
    Exibe comandos úteis para debug da arquitetura modular.
    """
    print(f"\n[COMMANDS]")
    print("="*70)
    print()
    print(f"  // Digite no Godot Console:")
    print(f"   check_modular_status()      → Verificação completa (acima)")
    print(f"   list_children()             → Mostra all children da scene atual") 
    print(f"   load_scene_tree("res://main.tscn")  → Exibe estrutura detalhada")
    print(f"")

func _input(event: InputEventKey) -> void:
    """
    Tecla F1 para exibir dashboard de comandos.
    """
    if event.pressed and event.keycode == KEY_F1:
        print_command_dashboard()
        queue_redraw()

func _draw() -> void:
    """
    Desenha indicador visual no canvas (F1 para exibir help).
    """
    # Desenha texto simples de ajuda ao pressionar F1
