shader_type canvas_item;
render_mode unshaded;

uniform vec4  tint : source_color = vec4(1.0);
uniform vec3  gloss_color = vec3(1.0, 1.0, 1.0); // teinte du highlight
uniform float gloss_strength : hint_range(0.0, 5.0) = 0.8; // force du spéculaire
uniform float spec_power     : hint_range(1.0, 128.0) = 32.0; // dureté

// Bande lumineuse "sweep"
uniform bool  use_sweep = true;
uniform float sweep_angle_deg = 35.0;
uniform float sweep_width     : hint_range(0.02, 0.6) = 0.18;
uniform float sweep_speed     : hint_range(-3.0, 3.0) = 0.25;
uniform float sweep_strength  : hint_range(0.0, 3.0) = 1.3;

// Position de la lumière (en coordonnées d’écran 0..1)
uniform vec2 light_pos = vec2(0.2, 0.8);

vec2 rotate(vec2 p, float a) {
    float s = sin(a), c = cos(a);
    // colonnes de la matrice (column-major)
    mat2 R = mat2(vec2(c, s), vec2(-s, c));
    return R * p;
}

void fragment() {
    vec4 base = texture(TEXTURE, UV) * tint;

    // --- Spéculaire "fake" (surface légèrement bombée) ---
    vec2 suv = SCREEN_UV;
    vec2 L2  = normalize(light_pos - suv);
    vec2 grad = normalize(vec2(0.5) - UV); // pseudo-normale convexe
    vec3 N = normalize(vec3(grad, 1.0));
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 H = normalize(vec3(L2, 0.0) + V);
    float spec = pow(max(dot(N, H), 0.0), spec_power);

    // --- Bande “sweep” animée ---
    float ang = radians(sweep_angle_deg);
    vec2  q   = rotate(UV - 0.5, ang);
    float line = q.x - fract(TIME * sweep_speed);
    float sweep = 1.0 - smoothstep(0.0, sweep_width, abs(line));

    float highlight = spec * gloss_strength + (use_sweep ? sweep * sweep_strength : 0.0);

    // Sortie HDR (déclenche le Glow)
    vec3 col = base.rgb + gloss_color * highlight;
    COLOR = vec4(col, base.a);
}

