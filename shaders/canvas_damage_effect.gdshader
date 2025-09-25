shader_type canvas_item;

uniform sampler2D stencil;
uniform float stencil_progress = 1.0;
uniform vec4 noise_color: source_color;
uniform vec4 texture_color: source_color;
uniform float noise_speed = 1.0;
uniform float noise_bias = 0.0;

void vertex() {
}

float hash (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	// Called for every pixel the material is visible on.
    float tex_alfa = texture(stencil, UV).a;
    float edge_distance = min(min(UV.x, UV.y) * 2.0, min(1.0 - UV.x, 1.0 - UV.y) * 2.0);

    float noise = sin(hash(UV) * 2.0 * PI + TIME * noise_speed);

    if (edge_distance < stencil_progress) {
        COLOR = texture(stencil, UV) * texture_color;
        if (COLOR.a == 0.0 && noise > noise_bias) {
            COLOR = noise_color;
        }
    } else {
        if (noise > noise_bias) {
            COLOR = noise_color;
        } else {
            COLOR = vec4(0, 0, 0, 0);
        }
    }
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
