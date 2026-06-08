shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec3 soil_dark : source_color = vec3(0.25, 0.18, 0.13);
uniform vec3 soil_mid : source_color = vec3(0.38, 0.27, 0.19);
uniform vec3 soil_light : source_color = vec3(0.50, 0.38, 0.28);

uniform vec3 soil_mossy : source_color = vec3(0.34, 0.35, 0.21);

uniform vec3 fleck_dark : source_color = vec3(0.30, 0.21, 0.16);
uniform vec3 fleck_light : source_color = vec3(0.56, 0.44, 0.34);
uniform vec3 fleck_green : source_color = vec3(0.34, 0.38, 0.23);

uniform sampler2D noise_tex;

uniform float noise_scale = 0.025;
uniform float toon_strength = 0.50;

uniform float moss_strength = 0.45;
uniform float moss_noise_scale = 0.08;

uniform float fleck_scale = 4.0;
uniform float fleck_size = 0.10;
uniform float fleck_softness = 0.03;
uniform float fleck_chance = 0.88;
uniform float fleck_strength = 0.45;

uniform float green_fleck_scale = 3.2;
uniform float green_fleck_size = 0.08;
uniform float green_fleck_chance = 0.93;
uniform float green_fleck_strength = 0.18;

uniform float wetness = 0.0;
uniform float wet_darkness = 0.78;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 world_uv = world_pos.xz;
	float n = texture(noise_tex, world_uv * noise_scale).r;

	vec3 col = soil_mid;

	if (n < 0.34) {
		col = mix(soil_mid, soil_dark, toon_strength);
	} else if (n > 0.68) {
		col = mix(soil_mid, soil_light, toon_strength);
	}

	float moss_n = texture(noise_tex, world_uv * moss_noise_scale + vec2(8.4, 2.1)).r;
	float moss_mask = smoothstep(0.62, 0.82, moss_n);
	col = mix(col, soil_mossy, moss_mask * moss_strength);

	vec2 fleck_uv = world_uv * fleck_scale;
	vec2 cell = floor(fleck_uv);
	vec2 local = fract(fleck_uv);

	float r = hash21(cell);
	vec2 fleck_pos = vec2(hash21(cell + 17.3), hash21(cell + 48.1));
	float d = distance(local, fleck_pos);

	float fleck_mask = 1.0 - smoothstep(fleck_size, fleck_size + fleck_softness, d);
	fleck_mask *= step(fleck_chance, r);

	vec3 fleck_col = mix(fleck_dark, fleck_light, hash21(cell + 91.0));
	col = mix(col, fleck_col, fleck_mask * fleck_strength);

	vec2 green_uv = world_uv * green_fleck_scale;
	vec2 green_cell = floor(green_uv);
	vec2 green_local = fract(green_uv);

	float gr = hash21(green_cell + 501.7);
	vec2 green_pos = vec2(hash21(green_cell + 82.1), hash21(green_cell + 19.6));
	float gd = distance(green_local, green_pos);

	float green_mask = 1.0 - smoothstep(green_fleck_size, green_fleck_size + 0.025, gd);
	green_mask *= step(green_fleck_chance, gr);

	col = mix(col, fleck_green, green_mask * green_fleck_strength);

	vec3 watered_col = col * vec3(wet_darkness, wet_darkness * 0.96, wet_darkness * 0.90);
	col = mix(col, watered_col, wetness);

	ALBEDO = col;
	ROUGHNESS = 1.0;
}