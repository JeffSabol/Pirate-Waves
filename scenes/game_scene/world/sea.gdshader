shader_type canvas_item;

// How fast the texture scrolls horizontally, in *pixels per second*
uniform float pixels_per_second = 1.0;   // try 0.5–1.5 range
// Set this to your texture's width in pixels (e.g. 512, 1024, 2048)
uniform float texture_width = 1280.0;

// Wobble settings
uniform float wobble_strength = 0.0001;  // vertical displacement in UV
uniform float wobble_freq = 1.0;         // how many waves across the texture
uniform float wobble_speed = 0.2;        // how fast the wobble animates

void fragment() {
    vec2 uv = UV;
    float t = TIME;

    // Convert pixel speed to UV offset
    float uv_dx = (pixels_per_second * t) / texture_width;
    uv.x += uv_dx;

    // Gentle wobble
    uv.y += sin(uv.x * wobble_freq + t * wobble_speed) * wobble_strength;

    COLOR = texture(TEXTURE, uv);
}
