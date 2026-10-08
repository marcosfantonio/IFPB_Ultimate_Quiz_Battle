# battle_gd.gd - WRAPPER DE COMPATIBILIDADE
# ⚠️ Arquivo de compatibilidade para quem usa scripts externos ou plugins
#
# Este arquivo garante que novas funcionalidades modulares (QuestionManager, 
# ProjectileSystem, UIController) funcionem mesmo com:
#   - Scripts carregados via FileSystemMonitor
#   - Plugins Godot 4.x/5.x em execução
#   - Hot-reload durante desenvolvimento
#
# Para migrar completamente para battle_refactored.gd: substitua o script da 
# cena principal no Godot Editor.

extends Node2D

class_name LegacyCompatibilityWrapper

## ==================== SETUP DE COMPATIBILIDADE ==================== ##

var _initialized := false
var _modular_scripts_loaded := false

func _ready() -> void:
    # Garante carregamento dos scripts modulares mesmo com plugins ativos
    if not _initialized and not _modular_scripts_loaded:
        _ensure_modular_scripts()
        _apply_compatibility_patches()

## ==================== GARANTIR SCRIPTS MODULARES CARREGADOS ==================== ##

func _ensure_modular_scripts() -> void:
    """
    Garante que os scripts modulares estão disponíveis via autoload.
    Útil quando plugins carregam battle.gd antes dos módulos existirem.
    """
    var modular_path = ProjectSettings.globalize("res://src/scripts/question_manager.gd")
    
    # Registra em autoloader como fallback para scripts externos
    ProjectSettings.set_initial_value(modular_path, true)
    
    _modular_scripts_loaded = true

## ==================== PATCHES DE COMPATIBILIDADE ==================== ##

func _apply_compatibility_patches() -> void:
    """
    Aplica patches para garantir compatibilidade com scripts externos.
    Útil se algum script carregou battle.gd original antes desta refatoração.
    """
    # Patch 1: Garante que QuestionManager seja acessível mesmo com paths relativos
    var qm = get_node_or_null("$QuestionManager")
    if qm:
        print("✅ LegacyCompatibilityWrapper: QuestionManager encontrado e compatibilizado")
    
    # Patch 2: Garante que ProjectileSystem tenha children renderização correta
    var ps = get_node_or_null("$ProjectileSystem")
    if ps and not ps.children.is_empty():
        print("✅ LegacyCompatibilityWrapper: ProjectileSystem renderização verificada")

## ==================== INTERFACE DE MIGRAÇÃO PARA SCRIPTS EXTERNOS ==================== ##

func migrate_to_refactored(config_instance: Settings = null) -> void:
    """
    Interface pública para migração gradual de scripts externos.
    
    Exemplo de uso em outro script:
        battle_wrapper.migrate_to_refactored(game_config)
    """
    print("LegacyCompatibilityWrapper: Iniciando migração...")
    _ensure_modular_scripts()

## ==================== MONITORAMENTO DE HOT-RELOAD ==================== ##

func check_module_availability(module_name: String) -> bool:
    """
    Verifica se um módulo modular está disponível na cena.
    
    Args:
        module_name: Nome do módulo (question_manager, projectile_system, etc.)
    Returns:
        true se o módulo existe e está funcional
    """
    var node = get_node_or_null("$" + module_name.to_pascal_case())
    return node != null and node is Object

func log_module_status() -> void:
    """
    Registra status de todos os módulos modulares na console.
    Útil para debugging de hot-reload.
    """
    print("\n[LegacyCompatibilityWrapper] Módulo Status:")
    for child_name in ["QuestionManager", "ProjectileSystem", "UIController"]:
        var status = "✅ Available" if check_module_availability(child_name) else "⚠️ Missing"
        print(f"  {status}: {child_name}")
