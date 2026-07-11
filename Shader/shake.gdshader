shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float frequency = 20;
uniform float depth = 1;

void fragment()
{	
	vec2 uv = SCREEN_UV;
	float uvx = (sin(TIME*frequency) + 0.5) * depth * 0.01;
	float uvy = (cos(TIME*frequency+0.321) + 0.5) * depth * 0.003;
	
	uv.x += uvx;
	uv.y += uvy;
//	uv.x = clamp(uv.x, 0.0, 1.0);
	vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
	
	COLOR.rgb = c;
}
