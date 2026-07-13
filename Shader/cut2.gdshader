shader_type canvas_item;

uniform float pixels : hint_range(1, 60) = 30.0;
uniform float degree : hint_range(0, 90);

uniform float time : hint_range(0, 1);

void vertex() {
    VERTEX.x *= 1.0 + 0.5*time;
}

void fragment()
{
	vec2 uv = UV;
//	uv -= mod(uv, vec2(1.0/pixels, 1.0/pixels));
	
	vec2 v = vec2(cos(radians(degree+90.0)), sin(radians(degree+90.0)));
	
	v += vec2(0.5);
	
	float d = (uv.x - 0.5) * (v.y - 0.5) - (uv.y - 0.5) * (v.x - 0.5);

	
	if(d > 0.0) {
		vec2 uv_t = vec2(uv.x, uv.y);
		uv_t.x = 1.0 - (1.0 - uv_t.x)*(1.0 + 0.5*time);
		
		float d2 = (uv_t.x - 0.5) * (v.y - 0.5) - (uv_t.y - 0.5) * (v.x - 0.5);
		if (d2 > 0.0 && uv_t.x > 0.0 && uv_t.x < 1.0) {
			COLOR = texture(TEXTURE, uv_t);
			COLOR.rgb *= 1.0 - time;
		} else {
			COLOR.a = 0.0;
		}
	} else {
		vec2 uv_t = vec2(uv.x, uv.y);
		uv_t.x *= 1.0 + 0.5*time;
		
		float d2 = (uv_t.x - 0.5) * (v.y - 0.5) - (uv_t.y - 0.5) * (v.x - 0.5);
		if (d2 < 0.0 && uv_t.x > 0.0 && uv_t.x < 1.0) {
			COLOR = texture(TEXTURE, uv_t);
			COLOR.rgb *= 1.0 - time;
		} else {
//			COLOR = vec4(1.0,1.0,0.0,1.0);
			COLOR.a = 0.0;
		}
	}
	
	if (time > 0.65 && time < 0.74) {
		COLOR.a = 0.0;
	}
	if (time > 0.78 && time < 0.83) {
		COLOR.a = 0.0;
	}
	if (time > 0.91 && time < 0.96) {
		COLOR.a = 0.0;
	}
	if (time > 0.99) {
		COLOR.a = 0.0;
	}
	
}
