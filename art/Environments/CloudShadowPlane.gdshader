shader_type spatial;
render_mode cull_disabled, specular_disabled;

global uniform vec3 wind_direction;
global uniform float wind_speed;

uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform bool shadow_enabled = true;
uniform float cloud_speed : hint_range(0.0, 10.0) = 1.0;
uniform float noise_scale : hint_range(0.001, 0.5) = 0.035;
uniform float noise_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float edge_softness : hint_range(0.001, 0.5) = 0.08;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;
uniform vec2 uv_offset = vec2(0.0);
uniform bool debug_solid_shadow = false;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (!shadow_enabled) {
		discard;
	}

	vec2 wind = wind_direction.xz;
	if (length(wind) < 0.001) {
		wind = vec2(1.0, 0.0);
	}
	wind = normalize(wind);

	vec2 cloud_uv = world_position.xz * noise_scale;
	cloud_uv += uv_offset;
	cloud_uv -= wind * TIME * wind_speed * cloud_speed;

	float noise_value = texture(noise_texture, cloud_uv).r;
	float cloud_mask = smoothstep(noise_threshold, noise_threshold + edge_softness, noise_value);

	if (debug_solid_shadow) {
		cloud_mask = 1.0;
	}

	if (cloud_mask < alpha_scissor) {
		discard;
	}

	ALBEDO = vec3(0.0);
}