shader_type canvas_item;

uniform vec2 scroll_speed = vec2(0.01, 0.003); // very slow drift
uniform float wobble_strength = 0.0001;         // tiny wobble
uniform float wobble_freq = 1.0;               // long, gentle waves

void fragment() {
    vec2 uv = UV;
    float t = TIME;

    // Tiny drift
    uv += scroll_speed * t;

    // Gentle wobble (almost invisible)
    uv.y += sin(uv.x * wobble_freq + t * 0.5) * wobble_strength;

    COLOR = texture(TEXTURE, uv);
}
