#version 150 compatibility

out VS_OUT {
    float seed;
} vs_out;

void main()
{
    gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
    vs_out.seed = 1.0;
}

