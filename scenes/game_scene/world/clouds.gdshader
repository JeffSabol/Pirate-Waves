shader_type canvas_item;

// Tint + opacity of fog
uniform vec4 fog_color = vec4(1.0, 1.0, 1.0, 0.5);

// Mask cutoff (higher = tighter fog)
uniform float cutoff = 0.1;

// How fast the fog scrolls horizontally
uniform float scroll_speed = 0.02; // try 0.005–0.05 range

void fragment() {
    vec2 uv = UV;
    float t = TIME;

    // Move clouds horizontally
    uv.x += scroll_speed * t;

    // Sample mask from your B/W cloud texture
    vec4 tcol = texture(TEXTURE, uv);
    float mask = tcol.r;

    float alpha = clamp(mask - cutoff, 0.0, 1.0);

    vec4 col = fog_color;
    col.a *= alpha;

    COLOR = col;
}
