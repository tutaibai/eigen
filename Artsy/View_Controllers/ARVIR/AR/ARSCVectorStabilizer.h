#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

// Basically a simple circular buffer for
// SCNVector3 objects.
//
// https://en.wikipedia.org/wiki/Circular_buffer
//
@interface ARSCVectorStabilizer : NSObject

- (SCNVector3)stableVectorForVector:(SCNVector3)vector;

@end
