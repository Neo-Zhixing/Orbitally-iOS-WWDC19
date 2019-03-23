//
//  Satellite.metal
//  Book_Sources
//
//  Created by 张之行 on 3/22/19.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct VertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
};

struct VertexOut {
    float4 position [[position]];
    float point_size [[point_size]];
};

struct FragmentIn {
    float4 position [[position]];
    float2 point_coord [[point_coord]];
};

struct OrbitallyFrame {
    float fov;
    float julian_date;
};

vertex VertexOut dot_vertex(VertexIn in [[ stage_in ]],
                            constant SCNSceneBuffer& scn_frame[[buffer(0)]],
                            constant OrbitallyFrame & orbitally_frame[[buffer(2)]])
{
    VertexOut out;
    out.position = scn_frame.viewProjectionTransform * float4(in.position, 1.0);
    
    //float fov = abs(atan(scn_frame.projectionTransform[2][2] / scn_frame.projectionTransform[1][1]));
    out.point_size = 350 / orbitally_frame.fov;
    out.point_size = min(out.point_size, 20.0);
    out.point_size = max(out.point_size, 8.0);
    return out;
}

fragment half4 dot_fragment(FragmentIn in [[stage_in]])
{
    float r = 1.0 - min(distance(in.point_coord * 2.0, float2(1.0, 1.0)), 1.0);
    float alpha = pow(r + 0.1, 3);
    alpha = min(1.0, alpha);
    half4 color = half4(1, 0.5, 0.5, 1);
    return color * half4(alpha, alpha, alpha, 1);
}
