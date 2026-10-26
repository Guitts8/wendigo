shader_type canvas_item;
// Efeitos de tela do estado do corpo: visão turva, vinheta, dessaturação,
// tom frio e escurecimento. Tudo em zero = imagem intacta.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur : hint_range(0.0, 5.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.62, 0.75, 1.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, blur).rgb;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(gray), desaturation);
	color = mix(color, color * tint.rgb, tint_amount);
	// Distância do centro: 0 no meio, ~1 nos cantos.
	float edge = smoothstep(0.35, 1.0, length(UV - 0.5) * 1.4142);
	color *= 1.0 - vignette * edge;
	color *= 1.0 - darkness;
	COLOR = vec4(color, 1.0);
}
