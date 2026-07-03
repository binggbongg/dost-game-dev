shader_type canvas_item;

uniform vec2 hole_position = vec2(0.0);
uniform vec2 hole_size = vec2(200.0);
uniform float corner_radius = 18.0;
uniform float feather = 16.0;
uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.72);

float roundedBoxSDF(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment()
{
    vec2 p = FRAGCOORD.xy;

    float dist = roundedBoxSDF(
        p - hole_position,
        hole_size * 0.5,
        corner_radius
    );

    float mask = smoothstep(0.0, feather, dist);

    COLOR = vec4(dim_color.rgb, dim_color.a * mask);
}