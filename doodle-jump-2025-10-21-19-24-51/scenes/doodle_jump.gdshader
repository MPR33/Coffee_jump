shader_type canvas_item;

// Paramètres de l'effet de lueur
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_speed : hint_range(0.0, 10.0) = 3.0;
uniform float glow_threshold : hint_range(-1.0, 1.0) = 0.0;

// Vitesse du joueur (à passer depuis le script)
uniform float player_vertical_velocity = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Calculer l'intensité de la lueur basée sur la vitesse verticale
    // Seulement quand le joueur monte (vitesse négative en Godot)
    float velocity_factor = max(0.0, -player_vertical_velocity);
    velocity_factor = clamp(velocity_factor / 500.0, 0.0, 1.0); // Normaliser

    // Effet de pulsation
    float pulse = sin(TIME * glow_speed) * 0.5 + 0.5;

    // Gradient vertical pour concentrer l'effet vers le haut
    float vertical_gradient = 1.0 - UV.y;

    // Combiner tous les facteurs
    float glow_strength = velocity_factor * pulse * vertical_gradient * glow_intensity;

    // Appliquer la lueur seulement si au-dessus du seuil
    if (velocity_factor > glow_threshold) {
        vec3 glow = glow_color.rgb * glow_strength;
        color.rgb += glow;
    }

    COLOR = color;
}