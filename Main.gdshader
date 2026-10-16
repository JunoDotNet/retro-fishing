
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 water_color : source_color = vec4(0.10, 0.30, 0.34, 0.70);
uniform vec4 dark_water : source_color = vec4(0.025, 0.09, 0.11, 1.0);
uniform vec4 light_water : source_color = vec4(0.30, 0.48, 0.46, 1.0);

uniform float wave_strength = 1.0;
uniform float wave_speed = 2.0;
uniform float contrast = 0.65;
uniform float pattern_scale = 0.35;

uniform float foam_scale = 2.0;
uniform float foam_speed = 0.3;
uniform float foam_amount = 1.35;

varying vec3 world_position;

void vertex() {
    float wave_a = sin(VERTEX.x * 2.0 + TIME * wave_speed);
    float wave_b = cos(VERTEX.z * 1.5 + TIME * wave_speed * 0.7);

    VERTEX.y += (wave_a + wave_b) * wave_strength;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	
    float pattern_a = sin(world_position.x * pattern_scale + TIME * 0.35);
    float pattern_b = cos(world_position.z * pattern_scale * 1.3 - TIME * 0.25);
    float pattern_c = sin((world_position.x + world_position.z) * pattern_scale * 0.7);

    float pattern = (pattern_a + pattern_b + pattern_c) / 3.0;
    float variation = clamp(0.5 + pattern * contrast, 0.0, 1.0);

    vec3 water_variation = mix(dark_water.rgb, light_water.rgb, variation);
    vec3 water = mix(water_color.rgb, water_variation, 0.8);

     // Sharp, thin Voronoi-style foam borders.
    vec2 foam_uv = world_position.xz * foam_scale;

    vec2 cell = floor(foam_uv);
    vec2 local_pos = fract(foam_uv);

    float nearest = 10.0;
    float second_nearest = 10.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 id = cell + neighbor;

            vec2 random_point = fract(
                sin(vec2(
                    dot(id, vec2(127.1, 311.7)),
                    dot(id, vec2(269.5, 183.3))
                )) * 43758.5453
            );

            random_point = 0.15 + random_point * 0.7;

            vec2 diff = neighbor + random_point - local_pos;
            float dist = length(diff);

            if (dist < nearest) {
                second_nearest = nearest;
                nearest = dist;
            } else if (dist < second_nearest) {
                second_nearest = dist;
            }
        }
    }

    // The difference between the two nearest cell distances
    // becomes a very thin line along each Voronoi border.
    float edge = second_nearest - nearest;

	
	
	// Dramatically evolving Voronoi borders.
	float t = TIME * foam_speed;
	float morph = 0.5 + 0.5 * sin(t * 0.7);

	// Large-scale deformation that bends the actual borders.
	float warp_x = sin(world_position.x * 2.5 + t * 1.8)
		+ cos(world_position.z * 3.0 - t * 1.3);

	float warp_z = cos(world_position.z * 2.0 + t * 1.5)
		+ sin(world_position.x * 3.2 - t * 1.7);

	// Big, irregular waves of distortion.
	float big_noise = sin(world_position.x * 8.0 + warp_z * 2.5 + t * 2.0)
		* cos(world_position.z * 9.0 + warp_x * 2.5 - t * 1.6);

	float medium_noise = sin(world_position.x * 22.0 + world_position.z * 17.0 + t * 3.0)
		* cos(world_position.z * 19.0 - world_position.x * 15.0 - t * 2.5);

	float fine_noise = (
		sin(world_position.x * 75.0 + world_position.z * 53.0 + t * 5.0)
		+ cos(world_position.z * 110.0 - world_position.x * 83.0 - t * 6.0)
	) / 2.0;

	// Blend the noise layers as the pattern evolves.
	float noise = mix(big_noise, fine_noise, morph);
	noise += medium_noise * 0.5;

	// Strongly deform the Voronoi edge distance.
	float crunchy_edge = edge + noise * 0.16;

	// Cycle between massive foam bands and finer borders.
	float thick = mix(0.10, 0.015, morph);
	float soft = mix(0.16, 0.045, morph);

	float foam = 1.0 - smoothstep(thick, soft, crunchy_edge);

    vec3 foam_color = vec3(0.82, 0.90, 0.84);

	ALBEDO = mix(water, foam_color, foam * 0.9);
	ALPHA = mix(water_color.a, 1.0, foam * 0.9);
	// Make distant water smoother.
	vec3 camera_position = INV_VIEW_MATRIX[3].xyz;
	float camera_distance = distance(world_position, camera_position);

	ROUGHNESS = mix(
    0.8, // Near camera
    0.25, // Far away
    smoothstep(5.0, 70.0, camera_distance)
);
}
