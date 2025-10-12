@tool
extends Container
class_name MaterialSelectionListing

@export var _fallback_texture: Texture2D
@export var _texture: TextureRect
@export var _label: Label
@export var _use_button: Button

var _on_use: Variant
var mat: Material

func configure(material: Material, color: Color, on_use: Variant) -> void:
    mat = material

    _label.text = material.resource_path
    update(color, on_use)

    if material is StandardMaterial3D:
        var std_mat: StandardMaterial3D = material
        if std_mat.albedo_texture == null:
            _texture.texture = _fallback_texture
        else:
            _texture.texture = std_mat.albedo_texture

        _texture.modulate = std_mat.albedo_color

    else:
        print_debug("[GLD Material Selection Listing] Don't know how to preview %s" % material)
        _texture.texture = _fallback_texture

func update(color: Color, on_use: Variant) -> void:
    _on_use = on_use
    _use_button.disabled = on_use is not Callable

    _label.add_theme_color_override("font_color", color)

func _on_use_pressed() -> void:
    if _on_use is Callable:
        _on_use.call()
