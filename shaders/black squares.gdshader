shader_type canvas_item;

uniform float square_width : hint_range(1.0, 64.0);
uniform float square_height : hint_range(1.0, 64.0);
uniform float noise_density : hint_range(0.0, 1.0);
uniform float time_speed : hint_range(0.0, 5.0);
uniform vec2 resolution = vec2(100.0, 2000.0);

void fragment() {
    vec2 uv = FRAGCOORD.xy / resolution;

    // Scale UV by square width and height separately
    vec2 scaled_uv = vec2(floor(uv.x * square_width), floor(uv.y * square_height));

    // Generate random value for each square
    float noise = fract(sin(dot(scaled_uv, vec2(12.9898, 78.233))) * 43758.5453 + TIME * time_speed);

    // Use noise to decide if we draw a black rectangle or make it transparent
    if (noise < noise_density) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        discard;
    }
}
