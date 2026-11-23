shader_type spatial;
// Erba con variazioni; dentro le mura diventa terra battuta.
#include "res://borgo/shader/comune.gdshaderinc"
uniform vec3 erba1 : source_color = vec3(0.17, 0.28, 0.10);
uniform vec3 erba2 : source_color = vec3(0.26, 0.37, 0.13);
uniform vec3 terra : source_color = vec3(0.55, 0.47, 0.34);
uniform float raggio_borgo = 34.0;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float n = vnoise(wpos.xz * 0.12) * 0.6 + vnoise(wpos.xz * 1.1) * 0.4;
	vec3 c = mix(erba1, erba2, n);
	float r = length(wpos.xz);
	float dentro = 1.0 - smoothstep(raggio_borgo - 6.0, raggio_borgo, r + vnoise(wpos.xz * 0.4) * 5.0);
	c = mix(c, terra * (0.85 + 0.3 * n), dentro * 0.75);
	float roccia = smoothstep(26.0, 40.0, wpos.y + vnoise(wpos.xz * 0.05) * 8.0);
	c = mix(c, vec3(0.45, 0.44, 0.42) * (0.8 + 0.3 * n), roccia);
	float neve = smoothstep(52.0, 60.0, wpos.y + vnoise(wpos.xz * 0.07) * 6.0);
	c = mix(c, vec3(0.92, 0.94, 0.96), neve);
	ALBEDO = c;
	ROUGHNESS = 0.97;
}
