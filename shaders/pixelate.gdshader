shader_type canvas_item;

uniform int pixels = 40;
uniform vec4 noise_color: source_color;
uniform float max_lerp = 0.7;
uniform float min_lerp = 0.0;
uniform float speed = 1.0;

void fragment() {

    if (pixels > 0) {
        vec2 grid_uv = round(UV * float(pixels)) / float(pixels);
        vec4 text = texture(TEXTURE, grid_uv);
        
        float noise = abs(sin((sin(grid_uv.x + grid_uv.y - 2.0 * TIME) + cos(grid_uv.y + TIME )) * (1000.0 + TIME * speed)));
        COLOR = mix(text, noise_color, mix(min_lerp, max_lerp, noise));
    } else {
        COLOR = texture(TEXTURE, UV);
    }
}
