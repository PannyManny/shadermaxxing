#version 330 compatibility
#define STEPS 1700

#define VOL_COUNT 2
#define VOL_NONE -1
#define VOL_1 0
#define VOL_2 1
#define VOL_3 2
#define VOL_4 3
#define VOL_5 4
#define VOL_6 5

const float STEP_SIZE = 0.08;

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform mat4 InverseTransformMatrix;
uniform mat4 ModelViewMat;
uniform vec3 CameraPosition;
uniform vec3 BlockPosition;
uniform float iTime;

in vec2 texCoord;
out vec4 fragColor;

// slop functions
mat2 Rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 worldPos( vec3 point ) {
    vec3 ndc = point * 2.0 - 1.0;
    vec4 homPos = InverseTransformMatrix * vec4(ndc, 1.0);
    vec3 viewPos = homPos.xyz / homPos.w;
    return (inverse(ModelViewMat) * vec4(viewPos, 1.0)).xyz + CameraPosition;
}

float densityFromSD( float sDistance, float falloff )
{
    return (sDistance < 0.0) ? 1.0 : exp(-sDistance * falloff);
}

// SDF(s)
float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
    vec2 d = vec2( length(p.xz)-ra+rb, abs(p.y) - h + rb );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}
//

// Configure movement and position
void computeSDFs(vec3 p, out float sdf[VOL_COUNT]) {

    // Position
    vec3 pivPos1 = p - vec3(0.0, 0.0, 0.0); // x y z coordinates (will be inversed)
    vec3 pivPos2 = p - vec3(0.0, 0.0, 0.0);

    float vol1 = sdSphere(pivPos1, 5.0);
    float vol2 = sdRoundedCylinder(pivPos2, 20.0, 20.0, 2.0);

    // Movement
    // pivPos2.xy *= Rotate(iTime);


    // Compute
    sdf[VOL_1] = sdSphere(p, 5.0);
    sdf[VOL_2] = sdRoundedCylinder(p, 20.0, 20.0, 2.0);
}


// Configure appearance
void volumeVisuals( int id, vec3 localPos, out vec3 color, out float baseOpacity, out float falloff ) {
    if (id == VOL_1) {
        color = vec3(0.0, 0.0, 0.0);
        baseOpacity = 1.0;
        falloff = 99.0;
        return;
    }

    if (id == VOL_2) {
        color = vec3(0.93, 0.59, 0.11);
        baseOpacity = 0.25;
        falloff = 4.0;
        return;
    }

    // if id isn't found:
    color = vec3(1.0, 0.0, 1.0);
    baseOpacity = 0.0;
    falloff = 1.0;
}

// Configure volume layers
int volumePriority(int id) {
    // higher number = higher priority
    if (id == VOL_1) return 2;
    if (id == VOL_2) return 1;
    return 0;
}

bool volumeAllowed(int id, float sdf[VOL_COUNT]) {
    int p = volumePriority(id);

    for (int i = 0; i < VOL_COUNT; i++) {
        if (i == id) continue;

        if (sdf[i] < 0.0 && volumePriority(i) > p)
        return false;
    }
    return true;
}

vec4 raymarchVolume(vec3 ro, vec3 rd) {
    float ray = 0.0;
    vec4 accum = vec4(0.0);

    for (int i = 0; i < STEPS; i++) {
        if (accum.a > 0.99) break;

        vec3 p = ro + rd * ray;

        float sdf[VOL_COUNT];
        computeSDFs(p, sdf);

        for (int id = 0; id < VOL_COUNT; id++) {

            if (!volumeAllowed(id, sdf))
            continue;

            vec3 color;
            float baseOpacity;
            float falloff;
            volumeVisuals(id, p, color, baseOpacity, falloff);

            float density = densityFromSD(sdf[id], falloff);
            float alpha = density * baseOpacity * STEP_SIZE;

            accum.rgb += (1.0 - accum.a) * color * alpha;
            accum.a   += (1.0 - accum.a) * alpha;
        }

        ray += STEP_SIZE;
    }

    return accum;
}


void main() {
    vec3 original = texture(DiffuseSampler, texCoord).rgb;

    float depthSample = texture(DepthSampler, texCoord).r;

    vec3 ro = worldPos(vec3(texCoord, 0.0)) - BlockPosition;
    vec3 hitWorld = worldPos(vec3(texCoord, depthSample)) - BlockPosition;
    vec3 rd = normalize(hitWorld - ro);

    vec4 volume = raymarchVolume(ro, rd);

    vec3 finalColor = original * (1.0 - volume.a) + volume.rgb;
    fragColor = vec4(finalColor, 1.0);
}
