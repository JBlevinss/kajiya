#define DIFFUSE_GI_USE_RESTIR 1
#define DIFFUSE_GI_BRDF_SAMPLING 0
#define RESTIR_TEMPORAL_M_CLAMP 10.0

// Reduces fireflies, but causes darkening in corners
#define RESTIR_RESERVOIR_W_CLAMP 10.0
// RTDGI_RESTIR_USE_JACOBIAN_BASED_REJECTION covers the same niche.
//#define RESTIR_RESERVOIR_W_CLAMP 1e5

#define RESTIR_USE_SPATIAL true
#define RESTIR_TEMPORAL_USE_PERMUTATIONS true
#define RESTIR_USE_PATH_VALIDATION true

#define RESTIR_SPATIAL_USE_RAYMARCH true
#define RTDGI_RESTIR_USE_JACOBIAN_BASED_REJECTION true
#define RTDGI_RESTIR_JACOBIAN_BASED_REJECTION_VALUE 5
