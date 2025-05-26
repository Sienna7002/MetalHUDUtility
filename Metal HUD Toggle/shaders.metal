//
//  shaders.metal
//  MacDown
//
//  Created by 7002 on 19/05/2025.
//

#include <metal_stdlib>
using namespace metal;



// Vertex structure for the cube (matches Swift)
struct CubeVertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

// Output from vertex shader to fragment shader for the cube
struct CubeRasterizerData {
    float4 position [[position]]; // Clip space position
    float2 texCoord;              // Texture coordinate
};

// Vertex structure for the full-screen gradient quad (matches Swift)
struct QuadVertexIn {
    float2 position [[attribute(0)]]; // Normalized Device Coordinates (-1 to 1)
};

// Output from vertex shader to fragment shader for the gradient
struct GradientRasterizerData {
    float4 position [[position]];     // Clip space position
    float2 normalizedScreenCoord; // Screen coordinates (0 to 1) for gradient calculation
};


// MARK: - Gradient Background Shaders

vertex GradientRasterizerData gradient_vertex_shader(QuadVertexIn in [[stage_in]],
                                                    constant float2 &viewport_size [[buffer(1)]] // Optional, not used here
                                                    ) {
    GradientRasterizerData out;
    // The input quad vertices are already in Normalized Device Coordinates (-1 to 1).
    // These are directly used as clip space positions.
    out.position = float4(in.position.x, in.position.y, 0.0, 1.0);
    
    // Convert NDC (-1 to 1) to texture-like coordinates (0 to 1) for gradient calculation.
    // Y is often flipped in NDC vs texture coords, but for a vertical gradient,
    // mapping directly from NDC y (-1 to 1) to gradient t (0 to 1) works well.
    out.normalizedScreenCoord = in.position * 0.5 + 0.5; // Remaps from [-1, 1] to [0, 1]
    
    return out;
}

fragment float4 gradient_fragment_shader(GradientRasterizerData in [[stage_in]]) {
    // Use the y-component of the normalized screen coordinate for the gradient.
    // `in.normalizedScreenCoord.y` ranges from 0 (bottom) to 1 (top).
    float t = in.normalizedScreenCoord.y;

    // Define gradient colors: dark purple to pink
    float3 darkPurple = float3(0.3059, 0.0431, 0.7843);
    float3 pink       = float3(0.9137, 0.2510, 0.3216);

    // Interpolate between the two colors based on 't'
    float3 finalColor = mix(darkPurple, pink, t);

    return float4(finalColor, 1.0); // Return RGBA color
}


// MARK: - Textured Cube Shaders

// Vertex shader for the cube
vertex CubeRasterizerData cube_vertex_shader(CubeVertexIn in [[stage_in]],
                                            constant float4x4 &mvpMatrix [[buffer(1)]]) {
    CubeRasterizerData out;
    // Transform vertex position by Model-View-Projection matrix
    out.position = mvpMatrix * float4(in.position, 1.0);
    // Pass through texture coordinates
    out.texCoord = in.texCoord;
    return out;
}

// Fragment shader for the cube
fragment float4 cube_fragment_shader(CubeRasterizerData in [[stage_in]],
                                     texture2d<float> baseColorTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    // Sample the texture at the interpolated texture coordinate
    float4 color = baseColorTexture.sample(textureSampler, in.texCoord);
    return color;
}
