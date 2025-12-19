#version 330 compatibility
#define STEPS 300
#define MIN_DIST 0.001
#define MAX_DIST 2500.0
#define TWO_PI 6.28318530718

#define MAT_NONE 0
#define MAT_SDF1 1
#define MAT_SDF2 2
#define MAT_SDF3 3
#define MAT_SDF4 4
#define MAT_SDF5 5

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform mat4 InverseTransformMatrix;
uniform mat4 ModelViewMat;
uniform vec3 CameraPosition;
uniform vec3 BlockPosition;
uniform float iTime;

in vec2 texCoord;
out vec4 fragColor;

// mapping ndc to world position
vec3 worldPos(vec3 point) {
    vec3 ndc = point * 2.0 - 1.0;
    vec4 homPos = InverseTransformMatrix * vec4(ndc, 1.0);
    vec3 viewPos = homPos.xyz / homPos.w;
    return (inverse(ModelViewMat) * vec4(viewPos, 1.0)).xyz + CameraPosition;
}
//

mat2 Rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// SDFs
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdCappedCylinder( vec3 p, float r, float h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
//

// Configure shapes' movement
float configSDF(vec3 p, out int mat_id, out vec3 outLocalPos) {
    float d = 1e9;
    mat_id = MAT_NONE;

    vec3 pivPos1 = p - vec3(0.0, 0.0, 0.0);
    float oneSDF = sdSphere(pivPos1, 4.0);
    if (oneSDF < d) {
        d = oneSDF;
        mat_id = MAT_SDF1;
        outLocalPos = pivPos1;
    }

    vec3 pivPos2 = p - vec3(20.0, 0.0, 0.0);
    float twoSDF = sdSphere(pivPos2, 7.0);
    if (twoSDF < d) {
        d = twoSDF;
        mat_id = MAT_SDF2;
        outLocalPos = pivPos2;
    }

    return d;
}

// Configure shapes' visuals (color, opacity, etc)
void materialVisuals(int mat, vec3 localPos, out vec3 color, out float opacity) {
    if (mat == MAT_SDF1) {
        color = vec3(0.0, 1.0, 0.0);
        opacity = 0.6;
        return;
    }

    if (mat == MAT_SDF2) {
        color = vec3(1.0,0.0,0.0);
        opacity = 1.0;
        return;
    }

    color = vec3(1.0,0.0,1.0);
    opacity = 0.9;
    // if you see magenta, there was an id error
}

void main() {
    vec3 original = texture(DiffuseSampler, texCoord).rgb;

    float depth = texture(DepthSampler, texCoord).r;

    vec3 start_point = worldPos(vec3(texCoord, 0.0)) - BlockPosition;
    vec3 end_point   = worldPos(vec3(texCoord, depth)) - BlockPosition;
    vec3 dir = normalize(end_point - start_point);

    float traveled = 0.0;
    vec3 p = start_point;
    bool hit = false;
    float maxRayLen = distance(start_point, end_point);

    vec3 matColor = vec3(0.0);
    float matOpacity = 0.0;
    vec3 accumColor = vec3(0.0);
    float accumAlpha = 0.0;

    int lastMat = MAT_NONE;
    vec3 hitLocalPos = vec3(0.0);

    for (int i = 0; i < STEPS; i++) {
        int stepMat = MAT_NONE;
        vec3 stepLocalPos;

        float d = configSDF(p, stepMat, stepLocalPos);

        if (d <= MIN_DIST) {
            hit = true;
            hitLocalPos = stepLocalPos;

            if (stepMat != lastMat && stepMat != MAT_NONE) {
                materialVisuals(stepMat, stepLocalPos, matColor, matOpacity);
                float alpha = clamp(matOpacity, 0.0, 1.0);

                accumColor += matColor * alpha * (1.0 - accumAlpha);
                accumAlpha += alpha * (1.0 - accumAlpha);

                lastMat = stepMat;
            }

            float escape = max(-d, MIN_DIST);
            p += dir * escape;
            traveled += escape;
            if (traveled >= maxRayLen || traveled >= MAX_DIST) break;
            continue;
        }
        traveled += d;
        if (traveled >= maxRayLen || traveled >= MAX_DIST) break;
        p += dir * d;
    }

    if (hit) {
        vec3 finalColor = mix(original, accumColor, accumAlpha);
        fragColor = vec4(finalColor, 1.0);
    } else {
        fragColor = vec4(original, 1.0);
    }
}