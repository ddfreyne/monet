#import <Foundation/Foundation.h>

#import <SDL/SDL.h>

#import <Monet/MOPoint.h>
#import <Monet/MOSize.h>

@class MOSpeedCounter;
@class MOView;
@class MOImage;

@interface MOScreen : NSObject
{
	// Pool
	NSAutoreleasePool	*autoreleasePool;

	// Dimensions
	MOSize				size;
	BOOL				isFullscreen;

	// Image and buffer
	SDL_Surface			*surface;

	// Running or not?
	BOOL				isOpen;

	// Content view
	MOView				*contentView;

	// Timing
	UInt8				ticksPerSecond;

	// FPS counter
	MOSpeedCounter		*fpsCounter;

	// Recent views receiving mouse button events
	MOView				*lastLeftMouseButtonDownView;
	MOView				*lastMiddleMouseButtonDownView;
	MOView				*lastRightMouseButtonDownView;
}

- (MOView *)contentView;
- (void)setContentView:(MOView *)aContentView;
- (MOSize)size;
- (void)setSize:(MOSize)aSize;
- (BOOL)isFullscreen;
- (void)setFullscreen:(BOOL)aIsFullscreen;
- (UInt8)ticksPerSecond;
- (void)setTicksPerSecond:(UInt8)aTicksPerSecond;

- (void)open;
- (void)enterRunloop;
- (void)close;

- (MOPoint)mouseLocation;

- (void)screenDidLoad;
- (void)update;

@end
