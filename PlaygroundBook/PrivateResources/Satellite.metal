//
//  Satellite.metal
//  Book_Sources
//
//  Created by 张之行 on 3/22/19.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct TLE {
    float meanAnomaly;
    float semimajorAxis;
    float eccentricity;
    float inclination;
    float argumentOfPerigee;
    float rightAscensionOfTheAscendingNode;
    float epoch;
    float meanMotion;
};


/**
 * Based on http://en.wikipedia.org/wiki/True_anomaly
 */
float trueAnomalyForEccentricAnomaly(float eccentricAnomaly, float eccentricity)
{
    float halfEccentricAnomalyRad = (eccentricAnomaly * M_PI_F / 180.0) / 2.0;
    return 2.0 * atan2(sqrt(1 + eccentricity) * sin(halfEccentricAnomalyRad), sqrt(1 - eccentricity) * cos(halfEccentricAnomalyRad)) * 180.0 / M_PI_F;
}

float meanAnomalyForJulianDate(float daysSinceEpoch, float meanMotion, float meanAnomaly) {
    float revolutionsSinceEpoch = meanMotion * daysSinceEpoch;
    float meanAnomalyForJulianDate = meanAnomaly + revolutionsSinceEpoch * 360.0;
    float fullRevolutions = floor(meanAnomalyForJulianDate / 360.0);
    float adjustedMeanAnomalyForJulianDate = meanAnomalyForJulianDate - 360.0 * fullRevolutions;
    
    return adjustedMeanAnomalyForJulianDate;
}

float eccentricAnomalyForMeanAnomaly(float meanAnomaly, float eccentricity) {

        // Do Newton–Raphson to solve Kepler's Equation : M = E - e * sin(E)
        // Start with the estimate = meanAnomaly converted to radians
        
    float estimate = 0.0;
    float estimateError = 1;
    float meanAnomalyInRadians = meanAnomaly * M_PI_F / 180.0;
    float previousEstimate = meanAnomalyInRadians;
    
    while (estimateError > 0.0001){
        estimate = previousEstimate - (previousEstimate - eccentricity * sin(previousEstimate) - meanAnomalyInRadians) / ( 1 - eccentricity * cos(previousEstimate) );
        estimateError = fabs(estimate - previousEstimate);
        previousEstimate = estimate;
    }
    
    return (estimate * 180.0 / M_PI_F);
}


float3 calc(TLE tle, float rotationFromGeocentric, float time)
{
    float meanAnomaly = meanAnomalyForJulianDate(tle.epoch + time, tle.meanMotion, tle.meanAnomaly);
    
    float eccentricAnomaly = eccentricAnomalyForMeanAnomaly(meanAnomaly, tle.eccentricity);
    
    float currentTrueAnomaly = trueAnomalyForEccentricAnomaly(eccentricAnomaly, tle.eccentricity);
    float semimajorAxis = tle.semimajorAxis;
    
    // Solve for r0 : the distance from the satellite to the Earth's center
    float currentOrbitalRadius = semimajorAxis - (semimajorAxis * tle.eccentricity) * cospi(eccentricAnomaly / 180.0);
    
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
    float4 position [[attribute(SCNVertexSemanticPosition)]];
    float4 normal [[attribute(SCNVertexSemanticNormal)]];
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
    float rotationFromGeocentric;
    float time_constant;
    float dot_size;
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
    tle.meanAnomaly = in.position.x;
    tle.semimajorAxis = in.position.y;
    tle.eccentricity = in.position.z;
    tle.inclination = in.position.w;
    tle.argumentOfPerigee = in.normal.x;
    tle.rightAscensionOfTheAscendingNode = in.normal.y;
    tle.epoch = in.normal.z;
    tle.meanMotion = in.normal.w;
    
    //float3 position = in.position;
    float3 position = calc(tle, orbitally_frame.rotationFromGeocentric, scn_frame.time / orbitally_frame.time_constant);
    position = float3(position.y, position.z, position.x);
    VertexOut out;
    out.position = scn_frame.viewProjectionTransform * float4(position, 1.0);
    
    //float fov = abs(atan(scn_frame.projectionTransform[2][2] / scn_frame.projectionTransform[1][1]));
    out.point_size = 500 / orbitally_frame.fov;
    out.point_size = min(out.point_size, 20.0);
    out.point_size = max(out.point_size, 8.0);
    out.point_size *= orbitally_frame.dot_size;
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
