shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixels : hint_range(1, 1920) = 1920;
uniform float frequency : hint_range(0, 60) = 60;
uniform float depth : hint_range(0, 0.01) = 0.005;
uniform float rotation : hint_range(0, 10) = 3.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float time : hint_range(0, 1) = 0.0;

//void fragment() {
//	vec2 uv = SCREEN_UV;
//	vec2 rel = uv - vec2(0.5, 0.5);
//	float angle = length(rel) * rotation;
//	mat2 rot = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
//	rel = rot * rel;
//	uv = clamp(rel + vec2(0.5,0.5), vec2(0.0, 0.0), vec2(1.0, 1.0));
//
//	uv.x += sin(uv.y * frequency + TIME) * depth;
//	uv.x = clamp(uv.x, 0.0, 1.0);
//	vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
//
//	COLOR.rgb = c;
//}

void fragment()
{
    float effectRadius = .9;
    float effectAngle = rotation * 3.1415926;
	
	vec2 uv = SCREEN_UV;
	uv = uv - center;
	
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	
	uv -= mod(uv, vec2(ratio/pixels, 1.0/pixels));
    
    float len = length(uv);
    float angle = atan(uv.y, uv.x) + effectAngle * smoothstep(effectRadius, 0., len);
    float radius = length(uv);
	
	uv = vec2(radius * cos(angle), radius * sin(angle)) + center;


	float uvx = sin(uv.y * frequency + TIME) * depth;
	float uvy = cos(uv.x * frequency * 3.0 + TIME) * depth;
	
	uv.x += uvx;
	uv.x = clamp(uv.x, 0.0, 1.0);
	
	uv.y += uvy;
	uv.y = clamp(uv.y, 0.0, 1.0);
	
	vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
	
	COLOR.rgb = c * (1.0 - time);
}