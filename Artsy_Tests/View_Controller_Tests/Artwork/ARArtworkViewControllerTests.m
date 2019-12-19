#import "Artwork.h"
#import "ARArtworkViewController.h"
#import "Aerodramus.h"
#import "ArtsyEcho.h"
#import "ARLegacyArtworkViewController.h"
#import <Emission/ARArtworkComponentViewController.h>


@interface ARArtworkViewController (Testing)
@property (strong, nonatomic) Aerodramus *echo;
@end

@interface _ARLegacyArtworkViewControllerMock : UIViewController
@end


@implementation _ARLegacyArtworkViewControllerMock
- (void)setHasFinishedScrolling {}
@end


@interface _ARArtworkComponentViewControllerMock : UIViewController
@end


@implementation _ARArtworkComponentViewControllerMock
@end

static void
StubArtworkWithAvailability(NSString *availability)
{
    NSDictionary *response = @{
        @"data" : @{
            @"artwork" : @{
                @"id" : @"some-artwork",
                @"title" : @"Some Title",
                @"availability" : availability
            }
        }
    };
    [OHHTTPStubs stubJSONResponseForHost:@"metaphysics-staging.artsy.net" withResponse:response];
}

static void
StubArtworkWithBNMOInSale(BOOL buyable, BOOL offerable, BOOL inSale)
{
    NSDictionary *response = @{
        @"data" : @{
            @"artwork" : @{
                @"id" : @"some-artwork",
                @"title" : @"Some Title",
                @"availability" : @"for sale",
                @"is_acquireable": @(buyable),
                @"is_offerable": @(offerable),
                @"is_in_auction": @(inSale)
            }
        }
    };
    [OHHTTPStubs stubJSONResponseForHost:@"metaphysics-staging.artsy.net" withResponse:response];
}

static void
StubArtworkWithBNMO(BOOL buyable, BOOL offerable)
{
    StubArtworkWithBNMOInSale(buyable, offerable, NO);
}


static void
StubArtworkWithSaleArtwork()
{
    NSDictionary *response = @{
        @"data" : @{
            @"artwork" : @{
                @"id" : @"some-artwork",
                @"title" : @"Some Title",
                @"availability" : @"for sale",
                @"is_in_auction": @(YES)
            }
        }
    };
    [OHHTTPStubs stubJSONResponseForHost:@"metaphysics-staging.artsy.net" withResponse:response];
}

static void
StubArtworkWithAvailabilityAndInquireability(NSString *availability, NSNumber *inquireability)
{
    NSDictionary *response = @{
        @"data" : @{
            @"artwork" : @{
                @"id" : @"some-artwork",
                @"title" : @"Some Title",
                @"availability" : availability,
                @"is_inquireable" : inquireability
            }
        }
    };
    [OHHTTPStubs stubJSONResponseForHost:@"metaphysics-staging.artsy.net" withResponse:response];
}

SpecBegin(ARArtworkViewController);

describe(@"ARArtworkViewController", ^{
    NSArray *legacyAvailabilityStates = @[@"for sale"];
    NSArray *componentAvailabilityStates = @[@"not for sale", @"on loan", @"permanent collection", @"sold", @"on hold"];

    __block Artwork *artwork = nil;
    __block ARArtworkViewController *vc = nil;

    __block id mockLegacyVCClass = nil;
    __block _ARLegacyArtworkViewControllerMock *mockLegacyVC = nil;

    __block id mockComponentVCClass = nil;
    __block _ARArtworkComponentViewControllerMock *mockComponentVC = nil;

    __block Aerodramus *echo = nil;

    beforeEach(^{
        artwork = [[Artwork alloc] initWithArtworkID:@"some-artwork"];

        mockLegacyVC = [_ARLegacyArtworkViewControllerMock new];
        mockLegacyVCClass = [OCMockObject mockForClass:ARLegacyArtworkViewController.class];
        (void)[[[mockLegacyVCClass stub] andReturn:mockLegacyVCClass] alloc];
        (void)[[[mockLegacyVCClass stub] andReturn:mockLegacyVC] initWithArtwork:artwork fair:OCMOCK_ANY];

        mockComponentVC = [_ARArtworkComponentViewControllerMock new];
        mockComponentVCClass = [OCMockObject mockForClass:ARArtworkComponentViewController.class];
        (void)[[[mockComponentVCClass stub] andReturn:mockComponentVCClass] alloc];
        (void)[[[mockComponentVCClass stub] andReturn:mockComponentVC] initWithArtworkID:artwork.artworkID];

        echo = [[ArtsyEcho alloc] init];
        echo.features = @{
            @"ARReactNativeArtworkEnableNSOInquiry" : [[Feature alloc] initWithName:@"" state:@(NO)]
        };

        vc = [[ARArtworkViewController alloc] initWithArtwork:artwork fair:nil];
        vc.echo = echo;
    });

    afterEach(^{
        [mockLegacyVCClass stopMocking];
        [mockComponentVCClass stopMocking];
    });

    describe(@"concerning artworks for which to show the legacy view", ^{
        for (NSString *availability in legacyAvailabilityStates) {
            it([NSString stringWithFormat:@"shows it with a `%@` artwork", availability], ^{
                StubArtworkWithAvailability(availability);
                (void)vc.view;
                expect(vc.childViewControllers[0]).to.equal(mockLegacyVC);
            });
        }

        describe(@"when inquireable", ^{
            for (NSString *availability in componentAvailabilityStates) {
                it([NSString stringWithFormat:@"shows it with a `%@` artwork", availability], ^{
                    StubArtworkWithAvailabilityAndInquireability(availability, @(YES));
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockLegacyVC);
                });
            }
        });

        describe(@"NSO/inquiry artworks", ^{
            it(@"works with buy-nowable artworks", ^{
                StubArtworkWithBNMO(YES, NO);
                (void)vc.view;
                expect(vc.childViewControllers[0]).to.equal(mockLegacyVC);
            });

            it(@"works with make-offerable artworks", ^{
                StubArtworkWithBNMO(NO, YES);
                (void)vc.view;
                expect(vc.childViewControllers[0]).to.equal(mockLegacyVC);
            });
        });

        it(@"works artworks that are in a sale", ^{
            StubArtworkWithSaleArtwork();
            (void)vc.view;
            expect(vc.childViewControllers[0]).to.equal(mockLegacyVC);
        });
    });

    describe(@"concerning artworks for which to show the new component view", ^{
        describe(@"noncommerical artworks", ^{
            describe(@"enabled through debug options", ^{
                for (NSString *availability in componentAvailabilityStates) {
                    it([NSString stringWithFormat:@"shows it with a `%@` artwork", availability], ^{
                        StubArtworkWithAvailability(availability);
                        (void)vc.view;
                        expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                    });
                }
            });

            describe(@"enabled through echo", ^{
                for (NSString *availability in componentAvailabilityStates) {
                    it([NSString stringWithFormat:@"shows it with a `%@` artwork", availability], ^{
                        StubArtworkWithAvailability(availability);
                        (void)vc.view;
                        expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                    });
                }
            });
        });

        describe(@"NSO/inquiry artworks", ^{
            describe(@"enabled through debug options", ^{
                it(@"works with buy-nowable artworks", ^{
                    StubArtworkWithBNMO(YES, NO);
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });

                it(@"works with make-offerable artworks", ^{
                    StubArtworkWithBNMO(NO, YES);
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });

                it(@"doesn't work if the artwork is in a sale", ^{
                    StubArtworkWithBNMOInSale(YES, YES, YES);
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).notTo.equal(mockComponentVC);
                });
            });

            describe(@"enabled through echo", ^{
                it(@"works with buy-nowable artworks", ^{
                    StubArtworkWithBNMO(YES, NO);
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });

                it(@"works with make-offerable artworks", ^{
                    StubArtworkWithBNMO(NO, YES);
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });
            });
        });

        describe(@"auctions artworks", ^{
            describe(@"enabled through debug options", ^{
                it(@"works artworks that are in a sale", ^{
                    StubArtworkWithSaleArtwork();
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });
            });

            describe(@"enabled through echo", ^{
                pending(@"works artworks that are in a sale", ^{
                    StubArtworkWithSaleArtwork();
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });
            });
        });

        describe(@"when all artworks lab option is enabled", ^{
            for (NSString *availability in componentAvailabilityStates) {
                it([NSString stringWithFormat:@"shows it with a `%@` artwork", availability], ^{
                    StubArtworkWithAvailability(availability);
                    (void)vc.view;
                    expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
                });
            }

            it(@"works with buy-nowable artworks", ^{
                StubArtworkWithBNMO(YES, NO);
                (void)vc.view;
                expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
            });

            it(@"works with make-offerable artworks", ^{
                StubArtworkWithBNMO(NO, YES);
                (void)vc.view;
                expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
            });

            it(@"works artworks that are in a sale", ^{
                StubArtworkWithSaleArtwork();
                (void)vc.view;
                expect(vc.childViewControllers[0]).to.equal(mockComponentVC);
            });
        });
    });
});

SpecEnd;
