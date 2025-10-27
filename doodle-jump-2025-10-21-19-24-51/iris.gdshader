shader_type canvas_item;

uniform float radius : hint_range(0.0, 4000.0) = 0.0;   // rayon en px
uniform float feather : hint_range(0.0, 64.0) = 8.0;    // adoucissement du bord
uniform vec2 hole_center_px = vec2(0.0);                // centre en pixels viewport

void fragment() {
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;   // taille viewport en px
    vec2 p = UV * res;                    // coordonnée pixel du fragment
    float d = distance(p, hole_center_px);

    // t = 0 au centre (transparent), 1 à l'extérieur (noir)
    float t = smoothstep(radius - feather, radius + feather, d);

    COLOR = vec4(0.0, 0.0, 0.0, t);
}
