shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.95, 0.72, 0.1, 1.0);
uniform float outline_width : hint_range(0.0, 5.0) = 1.0;
uniform bool show_outline = false;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (!show_outline) {
		COLOR = tex;
	} else {
		vec2 px = outline_width / vec2(textureSize(TEXTURE, 0));
		float neighbor = 0.0;
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
		neighbor = max(neighbor, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);
		if (tex.a < 0.2 && neighbor > 0.2) {
			COLOR = outline_color;
		} else {
			COLOR = tex;
		}
	}
}