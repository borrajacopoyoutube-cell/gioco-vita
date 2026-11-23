shader_type spatial;
// Coppi/tegole per i tetti. modo 0 = falda dritta, 1 = tetto conico.
#include "res://borgo/shader/comune.gdshaderinc"
uniform vec3 colore : source_color = vec3(0.66, 0.28, 0.18);
uniform int modo = 0;
varying vec3 lpos;
void vertex() {
	lpos = VERTEX;
}
void fragment() {
	vec2 p;
	if (modo == 1) {
		p = vec2(atan(lpos.z, lpos.x) * 4.0, lpos.y / 0.3);
	} else {
		p = vec2(lpos.z / 0.32, lpos.x / 0.26);
	}
	p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
	vec2 id = floor(p);
	vec2 f = fract(p);
	float ombra = mix(0.72, 1.06, f.y);
	float giunto = smoothstep(0.0, 0.1, f.x) * smoothstep(1.0, 0.9, f.x);
	vec3 c = colore * (0.82 + 0.3 * hash21(id)) * ombra;
	ALBEDO = mix(colore * 0.4, c, giunto);
	ROUGHNESS = 0.85;
}
