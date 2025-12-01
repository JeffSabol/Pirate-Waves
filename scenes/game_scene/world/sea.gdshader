shader_type canvas_item;

uniform float wobble_strength = 0.0001;
uniform float wobble_freq = 1.0;
uniform float wobble_speed = 0.2;

void fragment() {
    vec2 uv = UV;

    // Gentle wobble
    float t = TIME;
    uv.y += sin(uv.x * wobble_freq + t * wobble_speed) * wobble_strength;

    COLOR = texture(TEXTURE, uv);
}
