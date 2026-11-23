shader_type spatial;
// Pavimentazione a ciottoli per piazza e strade.
#include "res://borgo/shader/comune.gdshaderinc"
uniform vec3 pietra1 : source_color = vec3(0.56, 0.53, 0.49);
uniform vec3 pietra2 : source_color = vec3(0.70, 0.66, 0.60);
uniform vec3 fuga : source_color = vec3(0.30, 0.28, 0.25);
uniform float scala = 2.2;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = wpos.xz * scala;
	p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
	vec2 id = floor(p);
	vec2 f = fract(p);
	float e = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float m = smoothstep(0.02, 0.12, e);
	vec3 c = mix(pietra1, pietra2, hash21(id)) * (0.92 + 0.12 * vnoise(wpos.xz * 3.0));
	ALBEDO = mix(fuga, c, m);
	ROUGHNESS = 0.9;
}
