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
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);

    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


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
void computeSDFs(vec3 p, out float sdf[VOL_COUNT], out vec3 localPos[VOL_COUNT] ) {

    // Position
    vec3 center1 = p - vec3(0.0, 0.0, 0.0); // x y z coordinates (will be inversed)
    vec3 center2 = p - vec3(0.0, 0.0, 0.0);

    // Movement
    // pivPos2.xy *= Rotate(iTime);

    // Size/Dimensions
    float vol1 = sdSphere(center1, 5.0);
    float vol2 = sdRoundedCylinder(center2, 100.0, 10.0, 0.5);

    // Compute
    sdf[VOL_1] = vol1;
    sdf[VOL_2] = vol2;

    localPos[VOL_1] = center1;
    localPos[VOL_2] = center2;
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
        float radius = length(localPos.xz);

        // color
        vec3 hsv = vec3(0.1, 0.2, 1.0);
        float normRad = radius / 50.0;
        hsv.x -= (0.05 * normRad) * 2;
        hsv.y += (0.8 * normRad) * 3;
        hsv.z -= (0.82 * normRad) * 1.6;
        vec3 colorA = hsv2rgb(hsv);


        // opacity
        float clamp = clamp(radius / 50.0, 0.0, 1.0);
        float smoothen = smoothstep(0.2, 0.8, clamp);
        float inv = 1.0 - smoothen;
        float interp = pow(inv, 2.0);

        float opacityA = interp * 2.0;

        color = colorA;
        baseOpacity = opacityA;
        falloff = 30.0;
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
        vec3 localPos[VOL_COUNT];
        computeSDFs(p, sdf, localPos);

        for (int id = 0; id < VOL_COUNT; id++) {

            if (!volumeAllowed(id, sdf))
            continue;

            vec3 color;
            float baseOpacity;
            float falloff;
            volumeVisuals(id, localPos[id], color, baseOpacity, falloff);

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