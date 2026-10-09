class_name UITheme
extends RefCounted
## Aplica a fonte do jogo. Necessário porque a raiz é um Node2D
## (o Theme do Godot só propaga por ancestrais Control).


static func apply_font(node: Node) -> void:
	if node is Label or node is Button:
		node.add_theme_font_override("font", GameAssets.FONT)
	for child in node.get_children():
		apply_font(child)
