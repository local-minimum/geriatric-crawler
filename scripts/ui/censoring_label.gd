extends Control
class_name CensoringLabel

@export var censoring_textures: Array[Texture2D]

@export var allow_transpose_of_censoring_texture: bool:
    set(value):
        allow_transpose_of_censoring_texture = value
        queue_redraw()

@export var text: String:
    set(value):
        text = value
        _last_censor.clear()
        queue_redraw()

@export var censored_letters: String:
    set(value):
        censored_letters = value.to_upper() if censor_both_cases else value
        _last_censor.clear()
        queue_redraw()

@export var censor_both_cases: bool = true:
    set(value):
        censor_both_cases = true
        queue_redraw()

@export var font_size: int = 12:
    set(value):
        font_size = value
        queue_redraw()

@export var letter_spacing: int = 0:
    set (value):
        letter_spacing = value
        queue_redraw()

@export var update_freq_msec: int = 200

@export var font: Font

@export var color: Color = Color.WHITE_SMOKE:
    set(value):
        color = value
        queue_redraw()

@export var baseline_height: int = 6

@export var live: bool = true

var _last_draw: int
var _last_censor: Dictionary[int, int]

func _get_minimum_size() -> Vector2:
    return Vector2(font_size * text.length() + letter_spacing * (text.length() - 1), font_size)

func _draw() -> void:
    var pos: Vector2 = Vector2.ZERO
    for idx: int in range(text.length()):
        var letter: String = text[idx]

        if censored_letters.contains(letter.to_upper() if censor_both_cases else letter):
            var r: Rect2 = Rect2(pos + Vector2.UP * (font_size - baseline_height), Vector2(font_size, font_size))
            if !censoring_textures.is_empty():
                var texture_idx: int = randi_range(0, censoring_textures.size() - 1)
                if _last_censor.get(idx, -1) == texture_idx:
                    texture_idx += 1
                    texture_idx = posmod(texture_idx, censoring_textures.size())

                draw_texture_rect(
                    censoring_textures[texture_idx],
                    r,
                    false,
                    color,
                    allow_transpose_of_censoring_texture,
                )

                _last_censor[idx] = texture_idx
        else:
            draw_char(
                font if font else ThemeDB.fallback_font,
                pos,
                letter,
                font_size,
                color,
            )

        pos.x += font_size + letter_spacing


    _last_draw = Time.get_ticks_msec()


func _process(_delta: float) -> void:
    if live && Time.get_ticks_msec() > _last_draw + update_freq_msec && !censored_letters.is_empty():
        queue_redraw()
