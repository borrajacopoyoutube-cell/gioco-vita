shader_type spatial;
// Muratura in blocchi di pietra (mura, torri, chiesa, zoccoli).
#include "res://borgo/shader/comune.gdshaderinc"
uniform vec3 colore : source_color = vec3(0.64, 0.60, 0.53);
uniform vec3 malta : source_color = vec3(0.80, 0.77, 0.70);
uniform vec2 dim = vec2(0.9, 0.42);
varying vec3 wpos;
varying vec3 wnor;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnor = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 an = abs(wnor);
	vec2 uv;
	if (an.y > 0.7) {
		uv = wpos.xz;
	} else if (an.x > an.z) {
		uv = wpos.zy;
	} else {
		uv = wpos.xy;
	}
	vec2 p = uv / dim;
	p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
	vec2 id = floor(p);
	vec2 f = fract(p);
	float e = min(min(f.x, 1.0 - f.x) * dim.x, min(f.y, 1.0 - f.y) * dim.y);
	float m = smoothstep(0.012, 0.045, e);
	vec3 c = colore * (0.8 + 0.32 * hash21(id)) * (0.93 + 0.1 * vnoise(uv * 4.0));
	ALBEDO = mix(malta, c, m);
	ROUGHNESS = 0.95;
}
