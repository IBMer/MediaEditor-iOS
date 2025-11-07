#include <metal_stdlib>
using namespace metal;

// ============================================================
// ImPAWsibleMetalFilters - GPU Filter Kernels
// High-performance real-time video filter shaders
// Target: < 5ms @ 1920x1080 on Apple Silicon
// ============================================================

// ============================================================
// 1. Mono Filter (Black & White with adjustable contrast)
// ============================================================
kernel void monoFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &contrast [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // ITU-R BT.709 luminance formula (perceptual grayscale)
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Apply contrast adjustment
    gray = (gray - 0.5) * contrast + 0.5;
    gray = clamp(gray, 0.0, 1.0);

    float3 monoColor = float3(gray);
    float3 finalColor = mix(color.rgb, monoColor, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 2. Noir Filter (Dramatic black & white film effect)
// ============================================================
kernel void noirFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // High contrast black & white (crush shadows, boost highlights)
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // S-curve contrast enhancement
    float enhanced = gray < 0.5
        ? 2.0 * gray * gray
        : 1.0 - 2.0 * (1.0 - gray) * (1.0 - gray);

    float3 noirColor = float3(enhanced);
    float3 finalColor = mix(color.rgb, noirColor, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 3. Sepia Filter (Warm brown tone with adjustable warmth)
// ============================================================
kernel void sepiaFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &warmth [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Sepia matrix (dynamically adjusted by warmth parameter)
    float3x3 sepiaMatrix = float3x3(
        0.393 + warmth * 0.1, 0.769, 0.189,
        0.349, 0.686 + warmth * 0.1, 0.168,
        0.272, 0.534, 0.131 + warmth * 0.2
    );

    float3 sepiaColor = sepiaMatrix * color.rgb;
    sepiaColor = clamp(sepiaColor, 0.0, 1.0);

    float3 finalColor = mix(color.rgb, sepiaColor, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 4. Vintage Filter (Classic film processing look)
// ============================================================
kernel void vintageFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Vintage tone: reduce saturation + add warm yellow-red tones
    float3 vintage = color.rgb;

    // 1. Reduce saturation
    float gray = dot(vintage, float3(0.299, 0.587, 0.114));
    vintage = mix(vintage, float3(gray), 0.3);

    // 2. Add warm tones (yellow-red)
    vintage.r = min(vintage.r * 1.1, 1.0);
    vintage.g = min(vintage.g * 1.05, 1.0);
    vintage.b = vintage.b * 0.9;

    // 3. Slight fade (reduce contrast)
    vintage = (vintage - 0.5) * 0.85 + 0.5;

    float3 finalColor = mix(color.rgb, vintage, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 5. Tonal Filter (Soft tonal color effect)
// ============================================================
kernel void tonalFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Soft tonal: slight desaturation + midtone lift
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float3 tonal = mix(color.rgb, float3(gray), 0.2);

    // Lift midtones (gamma adjustment)
    tonal = pow(tonal, float3(0.9));

    float3 finalColor = mix(color.rgb, tonal, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 6. Transfer Filter (Color transfer effect)
// ============================================================
kernel void transferFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Color transfer: enhance greens and cyans, reduce reds
    float3 transfer = color.rgb;
    transfer.g = min(transfer.g * 1.15, 1.0);
    transfer.b = min(transfer.b * 1.1, 1.0);
    transfer.r = transfer.r * 0.95;

    float3 finalColor = mix(color.rgb, transfer, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 7. Chrome Filter (Metallic chrome effect)
// ============================================================
kernel void chromeFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Metallic chrome: high contrast + desaturation + edge sharpening
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float3 chrome = mix(color.rgb, float3(gray), 0.5);

    // Enhance contrast (S-curve)
    chrome = chrome < 0.5
        ? 2.0 * chrome * chrome
        : 1.0 - 2.0 * (1.0 - chrome) * (1.0 - chrome);

    float3 finalColor = mix(color.rgb, chrome, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 8. Fade Filter (Faded photograph with adjustable brightness)
// ============================================================
kernel void fadeFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &brightness [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Faded effect: reduce contrast + slight yellowing + brighten
    float3 faded = color.rgb;

    // 1. Reduce contrast
    faded = (faded - 0.5) * 0.7 + 0.5;

    // 2. Slight yellowing
    faded.r = min(faded.r * 1.05, 1.0);
    faded.g = min(faded.g * 1.03, 1.0);

    // 3. Apply brightness adjustment
    faded = faded * brightness;
    faded = clamp(faded, 0.0, 1.0);

    float3 finalColor = mix(color.rgb, faded, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}

// ============================================================
// 9. Instant Filter (Instant camera style with vignette)
// ============================================================
kernel void instantFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Instant camera: high saturation + blue-green cast + vignette
    float3 instant = color.rgb;

    // 1. Increase saturation
    float gray = dot(instant, float3(0.299, 0.587, 0.114));
    instant = mix(float3(gray), instant, 1.3);

    // 2. Blue-green color cast
    instant.g = min(instant.g * 1.08, 1.0);
    instant.b = min(instant.b * 1.12, 1.0);

    // 3. Vignette (darken edges)
    float2 uv = float2(gid) / float2(outTexture.get_width(), outTexture.get_height());
    float2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.5;
    instant = instant * vignette;

    instant = clamp(instant, 0.0, 1.0);

    float3 finalColor = mix(color.rgb, instant, intensity);

    outTexture.write(float4(finalColor, color.a), gid);
}
