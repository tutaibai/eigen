#import "ARSCVectorStabilizer.h"
#import <SceneKit/SceneKit.h>

@interface ARSCVectorStabilizer()
@property (assign, nonatomic) NSInteger index;
@property (nonatomic) SCNVector3 *vectors;
@property (assign, nonatomic) BOOL isFull;
@end


@implementation ARSCVectorStabilizer

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    _index = -1;

    SCNVector3 vertices[5];
    _vectors = vertices;

    return self;
}

- (SCNVector3)stableVectorForVector:(SCNVector3)vector
{
    self.index++;
    if (self.index == 5) {
        self.isFull = true;
        self.index = -1;
    }

    self.vectors[self.index] = vector;

    if (!self.isFull) {
        return vector;
    }

    SCNVector3 average = { 0 };
    for (int i = 0; i < 5; i++) {
        SCNVector3 current = self.vectors[i];
        average.x += current.x;
        average.y += current.y;
        average.z += current.z;
        NSLog(@"%@ - %@ %@ %@", @(i), @(current.x), @(current.y), @(current.z));

    }
    NSLog(@"avg - %@ %@ %@", @(average.x/5), @(average.y/5), @(average.z/5));

    return SCNVector3Make(average.x/5, average.y/5, average.z/5);
//    return vector;
}

@end
