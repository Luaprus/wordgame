shader_type canvas_item;

//  noise texture (see Dissolve.material for GUI Generated one or Main.gd::_on_reseed_noise_pressed() for scripted one)
// position (time) of burning
uniform float time : hint_range(0, 1);
uniform float stagger_amount: hint_range(0, 1) = 0.;
uniform float direction : hint_range(0, 360);
uniform bool reverse = false;
uniform bool reverse_vanish_direction = false;
uniform float speed: hint_range(0, 1) = 1.;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void fragment()
{
	COLOR = texture(TEXTURE, UV);
	
//	float pixels = 30.0;

//	vec2 size = 1./TEXTURE_PIXEL_SIZE;
	vec2 size = vec2(18.*60.);
	
	vec2 grid_size = size/60.0;

	vec2 gv = fract(UV*grid_size);
	vec2 id = floor(UV*grid_size)/grid_size;
	
	float r = gv.y;
	if (reverse_vanish_direction) {
		r = 1. - r;
	}
	
	
	vec2 dir = vec2(cos(radians(direction)), sin(radians(direction)));
	dir.x /= size.y/size.x;
	dir = normalize(dir);
	vec2 start_position = dir * -1.;
	float start_time = dot(id-start_position, dir);
	
	float max_time =  
		max(max(dot(vec2(0,0)-start_position, dir),
		dot(vec2(1,0)-start_position, dir)),
		max(dot(vec2(0,1)-start_position, dir),
		dot(vec2(1,1)-start_position, dir)));
	float min_time =  
		min(min(dot(vec2(0,0)-start_position, dir),
		dot(vec2(1,0)-start_position, dir)),
		min(dot(vec2(0,1)-start_position, dir),
		dot(vec2(1,1)-start_position, dir)));
	min_time = max(min_time, 0.);
		
	start_time = map(start_time, min_time, max_time, 0., 1.); // 0 ~ 1
	
	// 動畫佔 0.2
	stagger_amount; //1-0 -> 0.01-1
	float ani_time = max(0.01, 1.-stagger_amount);
	start_time = start_time * (1.-ani_time); // 0.0 ~ 0.8
	float t = time - start_time; // -0.8 ~ 1.0
	float p = clamp(t*(1./ani_time), 0., 1);
	
	//COLOR.rgb = mix(COLOR.rgb, vec3(0), step(r,p));
	
//	float _speed = 0.1 * speed;
	
	vec2 uv = UV;
	
	float x_pos = floor(uv.x * 18.);
	
	uv = mod(uv, vec2(1./18., 5./18.));
	uv *= vec2(18./30., 18./5.);
	
	float frame = 0.;
	frame = floor(fract(TIME)*30.);
	frame -= x_pos;
	frame = mod(frame, 30.);
	uv.x += 1./30. * (frame);
	
	COLOR = texture(TEXTURE, uv);

	
	if(reverse) {
		COLOR.a = mix(0., COLOR.a, step(r,p));
	} else {
		COLOR.a = mix(COLOR.a, 0., step(r,p));
	}
	
}
