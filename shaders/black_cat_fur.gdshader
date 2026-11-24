shader_type spatial;
render_mode cull_back;

uniform sampler2D fur_texture : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 base_velvet = vec3(0.012, 0.0125, 0.020);
uniform vec3 warm_rim_tint = vec3(0.032, 0.018, 0.009);
uniform float rim_power : hint_range(1.0, 6.0) = 4.2;

void fragment() {
	vec3 tex_rgb = texture(fur_texture, UV).rgb;
	float lum = dot(tex_rgb, vec3(0.299, 0.587, 0.114));
	// Cancel broad tabby stripes and white mittens while preserving 2K hair-strand detail.
	float coarse_lum = dot(textureLod(fur_texture, UV, 4.5).rgb, vec3(0.299, 0.587, 0.114));
	float strand_grain = clamp((lum - coarse_lum) * 2.2, -0.25, 0.25);
	float coat_depth = (clamp(lum, 0.04, 0.34) - 0.18) * 0.18;
	float fur_mod = 1.0 + strand_grain * 0.60 + coat_depth;

	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float fresnel = pow(1.0 - max(dot(n, v), 0.0), rim_power);
	float upper_mask = 0.28 + 0.72 * clamp(n.y * 0.5 + 0.5, 0.0, 1.0);

	ALBEDO = base_velvet * fur_mod + warm_rim_tint * (fresnel * upper_mask);
	ROUGHNESS = 0.82;
	SPECULAR = 0.25;
	RIM = 0.24;
	RIM_TINT = 0.55;
}
