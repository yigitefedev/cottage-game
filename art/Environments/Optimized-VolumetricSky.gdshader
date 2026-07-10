/*
License --
You are allowed to use it for commercial or non-commercial uses,
without giving credits (though credits will be appreciated).

You are not allowed to re-distribute it. Re-distribution means
re-publishing it as your property, even in derivative form.

Contact me --
For queries, mail to muhammadmujtaba150@gmail.com OR visit gameidea.org/contact
For free tutorials on shaders, visit https://gameidea.org

Credits --
This shader is based on https://www.shadertoy.com/view/MldcW2 AND https://www.shadertoy.com/view/Xttcz2
I modified to include a beautiful day-night cycle, and ported to Godot Engine 4.6.
And optimized for realtime games usage.
*/

shader_type sky;
render_mode use_half_res_pass;

uniform vec3 sky_top_color : source_color = vec3(0.0, 0.1, 0.4);
uniform vec3 sky_bottom_color : source_color = vec3(0.3, 0.67, 0.8);

// Night sky colors
uniform vec3 night_top_color : source_color = vec3(0.0, 0.005, 0.03);
uniform vec3 night_bottom_color : source_color = vec3(0.01, 0.01, 0.05);

// Sunset sky colors
uniform vec3 sunset_top_color : source_color = vec3(0.15, 0.05, 0.1);
uniform vec3 sunset_bottom_color : source_color = vec3(0.8, 0.3, 0.1);
uniform vec3 sunset_cloud_tint : source_color = vec3(1.5, 0.6, 0.25);
uniform float sunset_gradient_sharpness : hint_range(0.1, 5.0) = 0.5;

// Night cloud color
uniform vec3 night_cloud_color : source_color = vec3(0.12, 0.12, 0.21);

// Stars
uniform float star_density : hint_range(0.0, 1.0) = 0.85;
uniform float star_brightness : hint_range(0.0, 3.0) = 1.0;
uniform float star_scale : hint_range(10.0, 200.0) = 80.0;

// Weather
uniform float weather_desaturation : hint_range(0.0, 1.0) = 0.0;
uniform vec3 weather_tint : source_color = vec3(1.0, 1.0, 1.0);

// Cloud shape & coverage
uniform bool clouds_enabled = false;
uniform float coverage : hint_range(0.0, 1.0) = 0.3;
uniform float coverage_fade : hint_range(0.0, 0.2) = 0.035;
uniform float thickness : hint_range(10.0, 200.0) = 100.0;
uniform float absorption : hint_range(0.0, 2.0) = 0.5;
uniform int steps : hint_range(10, 150) = 32;

// Animation speeds
uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
uniform vec3 cloud_wind : source_color = vec3(0.3, 0.24, 0.30);           // direction + speed
uniform float cloud_evolution_speed : hint_range(0.0, 2.0) = 0.12;      // creates formation/dissolution

// Noise parameters for main cloud shape
uniform float noise_frequency : hint_range(0.0001, 0.01) = 0.001;
uniform float main_cloud_scale : hint_range(1.0, 5.0) = 2.032;
uniform float cloud_lacunarity : hint_range(1.5, 3.5) = 2.6434;
uniform float cloud_init_gain : hint_range(0.1, 1.0) = 0.5;
uniform float cloud_gain : hint_range(0.1, 1.0) = 0.5;

// Detail layers for nice color variation
uniform float detail_scale1 : hint_range(0.01, 1.0) = 0.2;
uniform float detail_lacunarity1 : hint_range(1.5, 3.5) = 2.0;
uniform float detail_init_gain1 : hint_range(0.1, 1.0) = 0.5;
uniform float detail_gain1 : hint_range(0.1, 1.0) = 0.52;

uniform float detail_scale2 : hint_range(0.01, 1.0) = 0.2;
uniform float detail_lacunarity2 : hint_range(1.5, 3.5) = 2.0;
uniform float detail_init_gain2 : hint_range(0.1, 1.0) = 0.52;
uniform float detail_gain2 : hint_range(0.1, 1.0) = 0.5;

// Lighting & camera
uniform float illum_base : hint_range(1.0, 5.0) = 2.1;
uniform float illum_pulse_amp : hint_range(0.0, 1.0) = 0.2;
uniform float illum_pulse_speed : hint_range(0.0, 5.0) = 2.3;

uniform float cloud_bob_speed : hint_range(0.0, 2.0) = 0.2;
uniform float cloud_bob_amount : hint_range(0.0, 0.5) = 0.1;
uniform float cloud_plane_distance : hint_range(50.0, 300.0) = 120.0;

uniform float horizon_fade_start : hint_range(0.0, 0.2) = 0.05;

// Simplex Noise 3D
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
	const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

	vec3 i = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);

	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);

	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;

	i = mod289(i);
	vec4 p = permute(permute(permute(
		i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
		i.y + vec4(0.0, i1.y, i2.y, 1.0)) +
		i.x + vec4(0.0, i1.x, i2.x, 1.0));

	float n_ = 0.142857142857;
	vec3 ns = n_ * D.wyz - D.xzx;
	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);
	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);

	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);

	vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;

	vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// FBM with per-octave time offset for cloud formation/dissolution
float fbm_clouds(vec3 pos, float time, float lacunarity, float init_gain, float gain) {
	vec3 p = pos;
	float H = init_gain;
	float t = 0.0;

	for (int i = 0; i < 5; i++) {
		float octave_time = time * cloud_evolution_speed * pow(lacunarity, float(i));
		vec3 offset = vec3(0.0, octave_time, 0.0);
		t += abs(snoise(p + offset)) * H;
		p *= lacunarity;
		H *= gain;
	}
	return t;
}

// Reduced-octave FBM for cubemap pass (3 octaves instead of 5)
float fbm_clouds_low(vec3 pos, float time, float lacunarity, float init_gain, float gain) {
	vec3 p = pos;
	float H = init_gain;
	float t = 0.0;

	for (int i = 0; i < 3; i++) {
		float octave_time = time * cloud_evolution_speed * pow(lacunarity, float(i));
		vec3 offset = vec3(0.0, octave_time, 0.0);
		t += abs(snoise(p + offset)) * H;
		p *= lacunarity;
		H *= gain;
	}
	return t;
}

// Sky gradient + sun + horizon glow,, shared by all passes
vec3 compute_sky(vec3 eye_dir, vec3 sun_dir, float day_factor, float sunset_factor, float night_factor) {
	vec3 top_color = mix(sky_top_color, night_top_color, night_factor);
	top_color = mix(top_color, sunset_top_color, sunset_factor * 0.7);
	vec3 bot_color = mix(sky_bottom_color, night_bottom_color, night_factor);
	bot_color = mix(bot_color, sunset_bottom_color, sunset_factor * 0.8);

	float sun_brightness = mix(1.0, 0.0, night_factor);
	vec3 sun_color = vec3(4.8, 3.14, 3.15) * 0.65 * sun_brightness;
	sun_color = mix(sun_color, vec3(4.0, 1.5, 0.3) * 0.65, sunset_factor);

	float sun_amount = max(dot(eye_dir, sun_dir), 0.0);

	vec3 sky = mix(top_color, bot_color * 0.9, 1.0 - eye_dir.y);
	sky += sun_color * min(pow(sun_amount, 355.0) * 6.0, 1.0);
	sky += sun_color * min(pow(sun_amount, 8.0) * 0.2, 1.0);

	float horizon_glow = pow(max(1.0 - abs(eye_dir.y), 0.0), 3.0);
	sky += sunset_bottom_color * horizon_glow * sunset_factor * 0.4;

	float luminance = dot(sky, vec3(0.2126, 0.7152, 0.0722));
	sky = mix(sky, vec3(luminance), weather_desaturation);
	sky *= weather_tint;

	return sky;
}

// Full cloud raymarching,, used in half-res pass and cubemap pass
vec4 compute_clouds(vec3 eye_dir, vec3 sun_dir, float dotR, float sunset_factor, float night_factor, bool low_quality) {
	float local_time = TIME * time_scale;
	vec3 cld_wind_dir = cloud_wind * local_time;

	// In cubemap pass, use half the steps for faster rendering
	int actual_steps = low_quality ? max(steps / 2, 8) : steps;
	float march_step = thickness / float(actual_steps);
	vec3 projection = eye_dir / eye_dir.y;
	vec3 iter = projection * march_step;

	vec3 eye_origin = vec3(0.0, 2.0 + sin(local_time * cloud_bob_speed) * cloud_bob_amount, 0.0);
	vec3 cloud_origin = eye_origin + projection * cloud_plane_distance;
	vec3 cloud_pos = cloud_origin;

	float cloud_T = 1.0;
	vec3 cloud_C = vec3(0.0);
	float cloud_alpha = 0.0;

	float cloud_illum_mult = mix(1.0, 0.2, night_factor);
	cloud_illum_mult = mix(cloud_illum_mult, 0.7, sunset_factor);

	for (int i = 0; i < actual_steps; i++) {
		float cloud_height = (cloud_pos.y - cloud_origin.y) / thickness;
		vec3 p = cloud_pos * noise_frequency + cld_wind_dir;

		float dens;
		if (low_quality) {
			dens = fbm_clouds_low(p * main_cloud_scale, local_time, cloud_lacunarity, cloud_init_gain, cloud_gain);
		} else {
			dens = fbm_clouds(p * main_cloud_scale, local_time, cloud_lacunarity, cloud_init_gain, cloud_gain);
		}
		dens *= smoothstep(coverage, coverage + coverage_fade, dens);

		float T_i = exp(-absorption * dens * march_step);
		cloud_T *= T_i;

		float illumstrength = illum_base + sin(local_time * illum_pulse_speed) * illum_pulse_amp;
		float illum = exp(cloud_height) / illumstrength * cloud_illum_mult;
		cloud_C += cloud_T * illum * dens * march_step;

		cloud_alpha += (1.0 - T_i) * (1.0 - cloud_alpha);
		cloud_pos += iter;

		if (cloud_alpha > 0.99) break;
	}

	// Color detail layers,, skip for cubemap pass
	vec3 v3;
	if (low_quality) {
		// Simplified,, just blend day/sunset/night tint without detail noise
		vec3 day_cloud_tint = vec3(1.0);
		float sun_facing = dot(eye_dir, sun_dir) * 0.5 + 0.5;
		sun_facing = pow(sun_facing, sunset_gradient_sharpness);
		vec3 sunset_tint = mix(day_cloud_tint, sunset_cloud_tint, sun_facing);
		v3 = mix(day_cloud_tint, sunset_tint, sunset_factor);
		v3 = mix(v3, night_cloud_color, night_factor);
	} else {
		vec3 p_final = (cloud_origin * noise_frequency + cld_wind_dir) * 1.0;
		float dens2 = fbm_clouds(p_final * detail_scale1, local_time, detail_lacunarity1, detail_init_gain1, detail_gain1);
		float dens3 = fbm_clouds(p_final * detail_scale2, local_time, detail_lacunarity2, detail_init_gain2, detail_gain2);

		vec3 day_cloud_tint = vec3(1.0);
		vec3 sunset_tint = sunset_cloud_tint;
		sunset_tint.g *= dens2 + 0.2;
		sunset_tint.b *= dens3 + 0.1;
		sunset_tint = clamp(sunset_tint, vec3(0.0), vec3(2.0));

		float sun_facing = dot(eye_dir, sun_dir) * 0.5 + 0.5;
		sun_facing = pow(sun_facing, sunset_gradient_sharpness);
		sunset_tint = mix(day_cloud_tint, sunset_tint, sun_facing);

		v3 = mix(day_cloud_tint, sunset_tint, sunset_factor);
		v3 = mix(v3, night_cloud_color, night_factor);
	}

	float calpha = cloud_alpha * smoothstep(0.0, 0.2, dot(eye_dir, vec3(0.0, 0.7, 0.0)));
	vec4 cld = vec4(pow(max(cloud_C * v3, vec3(0.0)), vec3(1.0, 0.9, 0.8)), calpha * 0.999);

	return cld;
}

void sky() {
	vec3 eye_dir = EYEDIR;
	float dotR = max(0.0, eye_dir.y);

	vec3 sun_dir = LIGHT0_DIRECTION;
	if (length(sun_dir) < 0.1) sun_dir = normalize(vec3(0.0, 0.4, -1.0));

	float sun_y = sun_dir.y;
	float day_factor = smoothstep(0.0, 0.3, sun_y);
	float sunset_factor = smoothstep(-0.1, 0.0, sun_y) * smoothstep(0.3, 0.05, sun_y);
	float night_factor = smoothstep(0.0, -0.2, sun_y);

	// CUBEMAP PASS: simplified sky + low-quality clouds
	// Runs only when updating the radiance cubemap (low res).
	// Uses fewer ray steps and fewer FBM octaves.
	if (AT_CUBEMAP_PASS) {
		vec3 sky = compute_sky(eye_dir, sun_dir, day_factor, sunset_factor, night_factor);

		// Stars (simplified, no twinkle, no color variation for cubemap)
		if (night_factor > 0.01) {
			vec3 star_pos = normalize(eye_dir) * star_scale;
			float n = snoise(star_pos);
			float stars = max(n - star_density, 0.0) / (1.0 - star_density);
			stars = stars * stars * star_brightness;
			sky += stars * night_factor;
		}

		vec3 color = sky;

		if (clouds_enabled && dotR > 0.001) {
			vec4 cld = compute_clouds(eye_dir, sun_dir, dotR, sunset_factor, night_factor, true);

			vec3 col_mix = mix(sky, cld.rgb, cld.a);
			col_mix = mix(col_mix, sky * (1.0 - cld.a) + cld.rgb, 0.6);

			if (dotR < horizon_fade_start) {
				color = mix(sky, col_mix, dotR / horizon_fade_start);
			} else {
				color = col_mix;
			}
		}

		COLOR = color;
		ALPHA = 1.0;

	// HALF-RES PASS: full-quality cloud raymarching at 1/4 pixels
	// This is the main performance win,, expensive clouds are
	// computed at half resolution and composited in the main pass.
	} else if (AT_HALF_RES_PASS) {
		if (clouds_enabled && dotR > 0.001) {
			vec4 cld = compute_clouds(eye_dir, sun_dir, dotR, sunset_factor, night_factor, false);
			COLOR = cld.rgb;
			ALPHA = cld.a;
		} else {
			COLOR = vec3(0.0);
			ALPHA = 0.0;
		}

	// MAIN (FULL-RES) PASS: sky gradient + sun + stars only,
	// then composite clouds from the half-res subpass.
	// No raymarching here,, just reads HALF_RES_COLOR.
	} else {
		vec3 sky = compute_sky(eye_dir, sun_dir, day_factor, sunset_factor, night_factor);

		// Stars at night,, full quality with twinkle + color variation
		if (night_factor > 0.01) {
			vec3 star_pos = normalize(eye_dir) * star_scale;
			float n = snoise(star_pos);
			float stars = max(n - star_density, 0.0) / (1.0 - star_density);
			stars = stars * stars * star_brightness;

			float color_seed = snoise(star_pos * 0.5 + 500.0);
			vec3 star_col;
			if (color_seed > 0.6) {
				star_col = vec3(0.7, 0.8, 1.0);
			} else if (color_seed > 0.2) {
				star_col = vec3(1.0, 0.95, 0.8);
			} else if (color_seed > -0.2) {
				star_col = vec3(1.0, 0.7, 0.4);
			} else {
				star_col = vec3(1.0, 0.5, 0.3);
			}

			float twinkle = snoise(star_pos * 1.5 + vec3(TIME * 1.3, TIME * 0.7, TIME * 1.1));
			twinkle = 0.7 + 0.3 * twinkle;

			sky += stars * star_col * night_factor * twinkle;
		}

		vec3 color = sky;

		// Composite half-res clouds into full-res sky
		vec4 half_res = HALF_RES_COLOR;
		if (clouds_enabled && half_res.a > 0.001) {
			vec3 col_mix = mix(sky, half_res.rgb, half_res.a);
			col_mix = mix(col_mix, sky * (1.0 - half_res.a) + half_res.rgb, 0.6);

			if (dotR < horizon_fade_start) {
				color = mix(sky, col_mix, dotR / horizon_fade_start);
			} else {
				color = col_mix;
			}
		}

		COLOR = color;
	}
}
