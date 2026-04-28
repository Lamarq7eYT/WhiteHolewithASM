#version 150 compatibility

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

out vec2 g_uv;
out vec2 g_ndc;

void emit_corner(vec2 p)
{
    g_ndc = p;
    g_uv = p * 0.5 + 0.5;
    gl_Position = vec4(p, 0.0, 1.0);
    EmitVertex();
}

void main()
{
    emit_corner(vec2(-1.0, -1.0));
    emit_corner(vec2( 1.0, -1.0));
    emit_corner(vec2(-1.0,  1.0));
    emit_corner(vec2( 1.0,  1.0));
    EndPrimitive();
}

