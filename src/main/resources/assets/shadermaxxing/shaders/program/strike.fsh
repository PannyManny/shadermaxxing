#version 330 compatibility
#define STEPS 300
#define MIN_DIST 0.001
#define MAX_DIST 2500.0

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform mat4 InverseTransformMatrix;
uniform mat4 ModelViewMat;
uniform vec3 CameraPosition;
uniform vec3 BlockPosition;

in vec2 texCoord;
out vec4 fragColor;

// mapping ndc
vec3 worldPos(vec3 point) {
    vec3 ndc = point * 2.0 - 1.0;
    vec4 homPos = InverseTransformMatrix * vec4(ndc, 1.0);
    vec3 viewPos = homPos.xyz / homPos.w;
    return (inverse(ModelViewMat) * vec4(viewPos, 1.0)).xyz + CameraPosition;
}

// SDF
float sdf( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
//

void main() {
    vec3 original = texture(DiffuseSampler, texCoord).rgb;

    float depth = texture(DepthSampler, texCoord).r;
    vec3 start_point = worldPos(vec3(texCoord, 0.0)) - BlockPosition; // near plane (camera)
    vec3 end_point   = worldPos(vec3(texCoord, depth)) - BlockPosition; // scene depth point
    vec3 dir = normalize(end_point - start_point);

    vec3 radius = vec3(4.0);

    float traveled = 0.0;
    vec3 p = start_point;
    bool hit = false;
    float maxRayLen = distance(start_point, end_point);

    for (int i = 0; i < STEPS; i++) {
        //
        float d = sdf(p, radius);
        //
        if (d <= MIN_DIST) {
            hit = true;
            break;
        }
        traveled += d;
        if (traveled >= maxRayLen || traveled >= MAX_DIST) break;
        p += dir * d;
    }

    // COLOR
    if (hit) {
        fragColor = vec4(vec3(0.0), 1.0); // solid black
    } else {
        fragColor = vec4(original, 1.0);
    }
}