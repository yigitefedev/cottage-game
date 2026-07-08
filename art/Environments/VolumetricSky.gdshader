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
uniform vec3 night_cloud_color : source_color = vec3(0.13, 0.13, 0.22);

// Stars
uniform float star_density : hint_range(0.0, 1.0) = 0.85;
uniform float star_brightness : hint_range(0.0, 3.0) = 1.0;
uniform float star_scale : hint_range(10.0, 200.0) = 80.0;

// Cloud shape & coverage
uniform float coverage : hint_range(0.0, 1.0) = 0.3;
uniform float coverage_fade : hint_range(0.0, 0.2) = 0.035;
uniform float thickness : hint_range(10.0, 200.0) = 100.0;
uniform float absorption : hint_range(0.0, 2.0) = 0.5;
uniform int steps : hint_range(10, 150) = 32;

// Animation speeds
uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
uniform vec3 cloud_wind : source_color = vec3(0.0, 0.0, -0.11);           // direction + speed
uniform float cloud_evolution_speed : hint_range(0.0, 2.0) = 0.12;      // this creates formation/dissolution

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

// FBM with per-octave time offset.. so clouds form & dissolve
float fbm_clouds(vec3 pos, float time, float lacunarity, float init_gain, float gain) {
	vec3 p = pos;
	float H = init_gain;
	float t = 0.0;

	for (int i = 0; i < 5; i++) {
		// Higher octaves evolve faster, making beautiful formation/dissolution
		float octave_time = time * cloud_evolution_speed * pow(lacunarity, float(i));
		vec3 offset = vec3(0.0, octave_time, 0.0); // feel free to change direction

		t += abs(snoise(p + offset)) * H;
		p *= lacunarity;
		H *= gain;
	}
	return t;
}


void sky() {
	vec3 eye_dir = EYEDIR;
	float dotR = max(0.0, eye_dir.y);

	vec3 sun_dir = LIGHT0_DIRECTION;
	if (length(sun_dir) < 0.1) sun_dir = normalize(vec3(0.0, 0.4, -1.0));

	// Sun elevation: 1 = high noon, 0 = horizon, negative = below horizon
	float sun_y = sun_dir.y;

	// Time-of-day factors
	// day_factor is 1 when sun is well above horizon, 0 at sunset/night
	float day_factor = smoothstep(0.0, 0.3, sun_y);
	// sunset_factor peaks when sun is near horizon (sun_y ~ 0.0 to 0.15)
	float sunset_factor = smoothstep(-0.1, 0.0, sun_y) * smoothstep(0.3, 0.05, sun_y);
	// night_factor is 1 when sun is well below horizon
	float night_factor = smoothstep(0.0, -0.2, sun_y);

	// Blend sky colors based on time of day
	vec3 top_color = mix(sky_top_color, night_top_color, night_factor);
	top_color = mix(top_color, sunset_top_color, sunset_factor * 0.7);
	vec3 bot_color = mix(sky_bottom_color, night_bottom_color, night_factor);
	bot_color = mix(bot_color, sunset_bottom_color, sunset_factor * 0.8);

	// Sun color dims at sunset, vanishes at night
	float sun_brightness = mix(1.0, 0.0, night_factor);
	vec3 sun_color = vec3(4.8, 3.14, 3.15) * 0.65 * sun_brightness;
	// Sunset makes the sun more orange/red
	sun_color = mix(sun_color, vec3(4.0, 1.5, 0.3) * 0.65, sunset_factor);

	float sun_amount = max(dot(eye_dir, sun_dir), 0.0);

	vec3 sky = mix(top_color, bot_color * 0.9, 1.0 - eye_dir.y);
	sky += sun_color * min(pow(sun_amount, 355.0) * 6.0, 1.0);
	sky += sun_color * min(pow(sun_amount, 8.0) * 0.2, 1.0);

	// Sunset horizon glow
	float horizon_glow = pow(max(1.0 - abs(eye_dir.y), 0.0), 3.0);
	sky += sunset_bottom_color * horizon_glow * sunset_factor * 0.4;

	// Stars at night
	if (night_factor > 0.01) {
		vec3 star_pos = normalize(eye_dir) * star_scale;
		float n = snoise(star_pos);
		// Sharpen noise into point-like stars
		float stars = max(n - star_density, 0.0) / (1.0 - star_density);
		stars = stars * stars * star_brightness;

		// Realistic star color classes based on spectral type
		// Use noise to assign each star a "class" for color variation
		float color_seed = snoise(star_pos * 0.5 + 500.0);
		vec3 star_col;
		if (color_seed > 0.6) {
			// Hot blue-white stars (type B/A) ~20%
			star_col = vec3(0.7, 0.8, 1.0);
		} else if (color_seed > 0.2) {
			// White/yellow-white stars (type F/G, like our Sun) ~40%
			star_col = vec3(1.0, 0.95, 0.8);
		} else if (color_seed > -0.2) {
			// Orange stars (type K) ~20%
			star_col = vec3(1.0, 0.7, 0.4);
		} else {
			// Red stars (type M) ~20%
			star_col = vec3(1.0, 0.5, 0.3);
		}

		// Twinkle,, slow flicker per star using noise offset by TIME
		float twinkle = snoise(star_pos * 1.5 + vec3(TIME * 1.3, TIME * 0.7, TIME * 1.1));
		twinkle = 0.7 + 0.3 * twinkle; // range ~0.4 to 1.0

		sky += stars * star_col * night_factor * twinkle;
	}

	vec3 color = sky;

	if (dotR > 0.001) {
		float local_time = TIME * time_scale;
		vec3 cld_wind_dir = cloud_wind * local_time;

		float march_step = thickness / float(steps);
		vec3 projection = eye_dir / eye_dir.y;
		vec3 iter = projection * march_step;

		vec3 eye_origin = vec3(0.0, 2.0 + sin(local_time * cloud_bob_speed) * cloud_bob_amount, 0.0);
		vec3 cloud_origin = eye_origin + projection * (cloud_plane_distance);
		vec3 cloud_pos = cloud_origin;

		float cloud_T = 1.0;
		vec3 cloud_C = vec3(0.0);
		float cloud_alpha = 0.0;

		// Cloud illumination dims with sun elevation
		float cloud_illum_mult = mix(1.0, 0.2, night_factor);
		cloud_illum_mult = mix(cloud_illum_mult, 0.7, sunset_factor);

		for (int i = 0; i < steps; i++) {

			float cloud_height = (cloud_pos.y - cloud_origin.y) / thickness;
			vec3 p = cloud_pos * noise_frequency + cld_wind_dir;

			float dens = fbm_clouds(p * main_cloud_scale, local_time, cloud_lacunarity, cloud_init_gain, cloud_gain);
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

		// Color detail layers
		vec3 p_final = (cloud_origin * noise_frequency + cld_wind_dir) * 1.0;
		float dens2 = fbm_clouds(p_final * detail_scale1, local_time, detail_lacunarity1, detail_init_gain1, detail_gain1);
		float dens3 = fbm_clouds(p_final * detail_scale2, local_time, detail_lacunarity2, detail_init_gain2, detail_gain2);

		// Day is neutral white/grey clouds,, no warm tint
		vec3 day_cloud_tint = vec3(1.0);

		// Sunset is warm orange tint driven by noise detail
		vec3 sunset_tint = sunset_cloud_tint;
		sunset_tint.g *= dens2 + 0.2;
		sunset_tint.b *= dens3 + 0.1;
		sunset_tint = clamp(sunset_tint, vec3(0.0), vec3(2.0));

		// Clouds facing the sun get more orange, away from sun get neutral
		// Full 3D dot gives gradient across entire sky sphere,, sun to opposite pole
		float sun_facing = dot(eye_dir, sun_dir);
		// Remap from [-1, 1] to [0, 1]
		sun_facing = sun_facing * 0.5 + 0.5;
		// Apply sharpness control,, >1 concentrates orange near sun, <1 spreads it wider
		sun_facing = pow(sun_facing, sunset_gradient_sharpness);
		sunset_tint = mix(day_cloud_tint, sunset_tint, sun_facing);

		// Night has dark desaturated cloud color
		vec3 night_tint = night_cloud_color;

		// Blend cloud tint based on time of day
		vec3 v3 = mix(day_cloud_tint, sunset_tint, sunset_factor);
		v3 = mix(v3, night_tint, night_factor);

		float calpha = cloud_alpha * smoothstep(0.0, 0.2, dot(eye_dir, vec3(0.0, 0.7, 0.0)));

		vec4 cld = vec4(pow(max(cloud_C * v3, vec3(0.0)), vec3(1.0, 0.9, 0.8)), calpha * 0.999);

		vec3 col_mix = mix(sky, cld.rgb, cld.a);
		col_mix = mix(col_mix, sky * (1.0 - cld.a) + cld.rgb, 0.6);

		if (dotR < horizon_fade_start) {
			color = mix(sky, col_mix, dotR / horizon_fade_start);
		} else {
			color = col_mix;
		}
	}

	COLOR = color;
}