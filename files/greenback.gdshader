shader_type canvas_item;

uniform float h_min_value = 80.0;
uniform float h_max_value = 160.0;
uniform float s_value = 0.3;
uniform float v_value = 0.4;

uniform float h_min_margin = 30.0;
uniform float h_max_margin = 30.0;
uniform float s_value_margin = 0.25;
uniform float v_value_margin = 0.25;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
  COLOR = texture(TEXTURE, UV); // Read from texture again.
  vec4 color_norm = COLOR ;// 255.0;
  float cmax = max(color_norm.r, max(color_norm.g, color_norm.b));
  float cmin = min(color_norm.r, min(color_norm.g, color_norm.b));
  float diff = cmax - cmin;
  float h = 0.0;
    if (cmax != cmin) {
        if (cmax == color_norm.r) {
            h = mod(60.0 * ((color_norm.g - color_norm.b) / diff) + 360.0, 360.0);
        } else if (cmax == color_norm.g) {
            h = mod(60.0 * ((color_norm.b - color_norm.r) / diff) + 120.0, 360.0);
        } else {
            h = mod(60.0 * ((color_norm.r - color_norm.g) / diff) + 240.0, 360.0);
        }
    }
	float s = 0.0;
    if (cmax != 0.0) {
        s = (diff / cmax) ;
    }
	float v = cmax ;
	
	
	
	float s_alpha = 0.0;
	
	
	s_alpha = smoothstep(max(0,s_value - s_value_margin),s_value,s);
	
	float v_alpha = 0.0;
	
	v_alpha = smoothstep(max(0,v_value - v_value_margin),v_value,v);
	
	  

float h_alpha = 0.0;
			if(h>h_min_value && h<h_max_value){
				h_alpha = 1.0;
			}else if(h<h_min_value && h>h_min_value-h_min_margin){
				h_alpha = smoothstep(h_min_value-h_min_margin, h_min_value, h);
			}else if(h>h_max_value && h<h_max_value+h_max_margin){
				h_alpha = 1.0 - smoothstep(h_max_value, h_max_value+h_max_margin, h);
			}
			bool green_back = false;
			float alpha = 0.0;
			if(h_alpha == 1.0 && s_alpha == 1.0 && v_alpha == 1.0){
				green_back= true;
			}else{
				alpha = h_alpha*s_alpha*v_alpha;
			}
				
				
				
				
//COLOR = vec4(s_alpha,s_alpha,s_alpha,1);

 
if( green_back ){
	COLOR = vec4(0,0,0,0);
}else{
	if (alpha>0.0){
		COLOR.a = 1.0 - alpha;
	}else{
		//original
	}
}

//COLOR = vec4(h_alpha,h_alpha,h_alpha,1);
//COLOR = vec4(alpha,alpha,alpha,1);

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
