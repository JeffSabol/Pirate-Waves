shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = start, 1 = done
uniform float wave_strength : hint_range(0.0, 0.02) = 0.005;
uniform float wave_frequency : hint_range(0.0, 25.0) = 12.5;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec2 uv = UV;

    // Waves get weaker as progress goes to 1
    float intensity = (1.0 - progress) * wave_strength;

    float offset_x = sin(uv.y * wave_frequency + TIME * wave_speed) * intensity;
    float offset_y = cos(uv.x * wave_frequency * 0.7 + TIME * wave_speed * 0.8) * intensity * 0.5;

    vec2 distorted_uv = uv + vec2(offset_x, offset_y);

    // Sample original screenshot
    vec4 col = texture(TEXTURE, distorted_uv);

    COLOR = col;
}
