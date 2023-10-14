
//!DESC unsharp
//!HOOK SCALED  
//!BIND HOOKED

#define effect_width 1
#define coeff_blur 0.9

#define coeff_orig (1 + coeff_blur)

#define Src(a,b) HOOKED_texOff(vec2(a,b))
#define dx (effect_width)
#define dy (effect_width)

vec4 hook()
{
	
	// Retrieves the original pixel
	vec4 orig = Src(0,0);

	// Calculates blurred image (gaussian blur)
	vec4 c1 = Src(-dx,-dy);
	vec4 c2 = Src(0,-dy);
	vec4 c3 = Src(dx,-dy);
	vec4 c4 = Src(-dx,0);
	vec4 c5 = Src(dx,0);
	vec4 c6 = Src(-dx,dy);
	vec4 c7 = Src(0,dy);
	vec4 c8 = Src(dx,dy);

	// gaussian blur filter
	// [ 1, 2 , 1 ]
	// [ 2, 4 , 2 ]
	// [ 1, 2 , 1 ]
	// c1 c2 c3
	// c4    c5
	// c6 c7 c8
	vec4 blur = (c1 + c3 + c6 + c8 + 2 * (c2 + c4 + c5 + c7) + 4 * orig)/16;

	// The blurred image is substracted from the origginal image
	vec4 corr = coeff_orig*orig - coeff_blur*blur;

	return corr;
}

