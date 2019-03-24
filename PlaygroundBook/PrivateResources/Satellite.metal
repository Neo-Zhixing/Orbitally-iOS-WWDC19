//
//  Satellite.metal
//  Book_Sources
//
//  Created by 张之行 on 3/22/19.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

constant float EARTH_R = 1.0;

struct TLE {
    float eccentricAnomaly;
    float semimajorAxis;
    float eccentricity;
    float inclination;
    float argumentOfPerigee;
    float rightAscensionOfTheAscendingNode;
};


/**
 * Based on http://en.wikipedia.org/wiki/True_anomaly
 */
float trueAnomalyForEccentricAnomaly(float eccentricAnomaly, float eccentricity)
{
    float halfEccentricAnomalyRad = (eccentricAnomaly * M_PI_F / 180.0) / 2.0;
    return 2.0 * atan2(sqrt(1 + eccentricity) * sin(halfEccentricAnomalyRad), sqrt(1 - eccentricity) * cos(halfEccentricAnomalyRad)) * 180.0 / M_PI_F;
}


float3 calc(TLE tle, float rotationFromGeocentric)
{
    
    float currentTrueAnomaly = trueAnomalyForEccentricAnomaly(tle.eccentricAnomaly, tle.eccentricity);
    float semimajorAxis = tle.semimajorAxis;
    
    // Solve for r0 : the distance from the satellite to the Earth's center
    float currentOrbitalRadius = semimajorAxis - (semimajorAxis * tle.eccentricity) * cospi(tle.eccentricAnomaly / 180.0);
    
    // Solve for the x and y position in the orbital plane
    float orbitalX = currentOrbitalRadius * cospi(currentTrueAnomaly / 180.0);
    float orbitalY = currentOrbitalRadius * sinpi(currentTrueAnomaly / 180.0);
    
    
    // Rotation math  https://www.csun.edu/~hcmth017/master/node20.html
    // First, rotate around the z''' axis by the Argument of Perigee: ⍵
    float cosArgPerigee = cospi(tle.argumentOfPerigee / 180.0);
    float sinArgPerigee = sinpi(tle.argumentOfPerigee / 180.0);
    float orbitalXbyPerigee = cosArgPerigee * orbitalX - sinArgPerigee * orbitalY;
    float orbitalYbyPerigee = sinArgPerigee * orbitalX + cosArgPerigee * orbitalY;
    float orbitalZbyPerigee = 0.0;
    
    // Next, rotate around the x'' axis by inclincation
    float cosInclination = cospi(tle.inclination / 180.0);
    
    float sinInclination = sinpi(tle.inclination / 180.0);
    
    float orbitalXbyInclination = orbitalXbyPerigee;
    
    float orbitalYbyInclination = cosInclination * orbitalYbyPerigee - sinInclination * orbitalZbyPerigee;
    float orbitalZbyInclination = sinInclination * orbitalYbyPerigee + cosInclination * orbitalZbyPerigee;
    
    // Lastly, rotate around the z' axis by RAAN: Ω
    float cosRAAN = cospi(tle.rightAscensionOfTheAscendingNode / 180.0);
    float sinRAAN = sinpi(tle.rightAscensionOfTheAscendingNode / 180.0);
    float geocentricX = cosRAAN * orbitalXbyInclination - sinRAAN * orbitalYbyInclination;
    float geocentricY = sinRAAN * orbitalXbyInclination + cosRAAN * orbitalYbyInclination;
    float geocentricZ = orbitalZbyInclination;
    
    // And then around the z axis by the earth's own rotaton
    float rotationFromGeocentricRad = -rotationFromGeocentric * M_PI_F / 180.0;
    float relativeX = cos(rotationFromGeocentricRad) * geocentricX - sin(rotationFromGeocentricRad) * geocentricY;
    float relativeY = sin(rotationFromGeocentricRad) * geocentricX + cos(rotationFromGeocentricRad) * geocentricY;
    float relativeZ = geocentricZ;
    return float3(relativeX, relativeY, relativeZ);
}






struct VertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal [[attribute(SCNVertexSemanticNormal)]];
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
    float rotationFromGeocentric;
};

struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
};


vertex VertexOut dot_vertex(VertexIn in [[ stage_in ]],
                            constant SCNSceneBuffer& scn_frame[[buffer(0)]],
                            constant NodeBuffer& node_frame[[buffer(1)]],
                            constant OrbitallyFrame & orbitally_frame[[buffer(2)]])
{
    TLE tle;
    tle.eccentricAnomaly = in.position.x;
    tle.semimajorAxis = in.position.y;
    tle.eccentricity = in.position.z;
    
    tle.inclination = in.normal.x;
    tle.argumentOfPerigee = in.normal.y;
    tle.rightAscensionOfTheAscendingNode = in.normal.z;
    
    //float3 position = in.position;
    float3 position = calc(tle, orbitally_frame.rotationFromGeocentric);
    position.x /= EARTH_R;
    position.y /= EARTH_R;
    position.z /= EARTH_R;
    VertexOut out;
    out.position = scn_frame.viewProjectionTransform * float4(position, 1.0);
    
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
