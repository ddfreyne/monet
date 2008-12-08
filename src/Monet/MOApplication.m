#import <Monet/MOApplication.h>

#import <Foundation/Foundation.h>

#import <Monet/MOEvent.h>
#import <Monet/MOSpeedCounter.h>
#import <Monet/MOView.h>
#import <Monet/Private.h>

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

struct MOApplicationData
{
	// Pool
	NSAutoreleasePool *autoreleasePool;

	// Surface
	SDL_Surface       *surface;
	MOSize            screenSize;
	BOOL              isFullscreen;

	// Running or not?
	BOOL              isOpen;

	// Model
	id                model;

	// View
	MOView            *mainView;

	// Timing
	UInt8             gameTicksPerSecond;
	float             interpolation;

	// FPS counter
	MOSpeedCounter    *fpsCounter;

	// Recent views receiving mouse button events
	MOView            *lastLeftMouseButtonDownView;
	MOView            *lastMiddleMouseButtonDownView;
	MOView            *lastRightMouseButtonDownView;
};

@interface MOApplication (Autoreleasing)

- (void)refreshAutoreleasePool;

@end

@implementation MOApplication (Autoreleasing)

- (void)refreshAutoreleasePool
{
	[applicationData->autoreleasePool release];
	applicationData->autoreleasePool = [[NSAutoreleasePool alloc] init];
}

@end

@interface MOApplication (Runloop)

- (void)handleEvents;

@end

@implementation MOApplication (Runloop)

- (void)handleEvents
{
	SDL_Event event;
	while(SDL_PollEvent(&event))
	{
		switch(event.type)
		{
			case SDL_ACTIVEEVENT:
				if(event.active.gain)
					; // Resume
				else
					; // Pause
				break;

			case SDL_KEYDOWN:
				if(event.key.keysym.sym == SDLK_ESCAPE)
					[self closeScreen];
				else
				{
					// Get character
					NSString *character;
					if(event.key.keysym.unicode == 0)
						character = @"";
					else
						character = [[NSString alloc] initWithCharacters:&event.key.keysym.unicode length:1];

					// Create event
					MOEvent *moEvent = [[MOEvent alloc] initKeyEventWithType:MOKeyDownEventType
														modifiers:MOSDLModToMOKeyModifierMask(event.key.keysym.mod)
														character:character
														key:MOSDLKeyToMOKey(event.key.keysym.sym)
					];

					// Dispatch event
					[applicationData->mainView keyDown:moEvent];

					// Cleanup
					[character release];
					[moEvent release];
				}
				break;

			case SDL_KEYUP:
				{
					// Create event
					MOEvent *moEvent = [[MOEvent alloc] initKeyEventWithType:MOKeyUpEventType
														modifiers:MOSDLModToMOKeyModifierMask(event.key.keysym.mod)
														character:0
														key:MOSDLKeyToMOKey(event.key.keysym.sym)
					];

					// Dispatch event
					[applicationData->mainView keyUp:moEvent];

					// Cleanup
					[moEvent release];
				}
				break;

			case SDL_MOUSEMOTION:
				{
					// Create event
					MOEvent *moEvent = [[MOEvent alloc] initMouseMotionEventWithModifiers:MOSDLModToMOKeyModifierMask(SDL_GetModState())
														mouseLocation:MOMakePoint(event.motion.x, applicationData->screenSize.h-event.motion.y-1)
														relativeMouseMotion:MOMakePoint(event.motion.xrel, event.motion.yrel)
					];

					// Dispatch event to subviews that want it
					if(applicationData->lastLeftMouseButtonDownView)
						[applicationData->lastLeftMouseButtonDownView mouseDragged:moEvent];
					if(applicationData->lastMiddleMouseButtonDownView)
						[applicationData->lastMiddleMouseButtonDownView mouseDragged:moEvent];
					if(applicationData->lastRightMouseButtonDownView)
						[applicationData->lastRightMouseButtonDownView mouseDragged:moEvent];

					// Cleanup
					[moEvent release];
				}
				break;

			case SDL_MOUSEBUTTONDOWN:
				{
					// Get event information
					MOPoint mouseLocation		= MOMakePoint(event.button.x, applicationData->screenSize.h-event.button.y-1);
					MOMouseButton mouseButton	= MOSDLMouseButtonToMOMouseButton(event.button.button);
					UInt8 modifiers				= MOSDLModToMOKeyModifierMask(SDL_GetModState());

					// Find deepest subview
					MOView *subview = [applicationData->mainView deepestSubviewAtPoint:mouseLocation];

					// Set last view receiving event
					switch(mouseButton)
					{
						case MOLeftMouseButton:
							applicationData->lastLeftMouseButtonDownView = subview;
							break;

						case MOMiddleMouseButton:
							applicationData->lastMiddleMouseButtonDownView = subview;
							break;

						case MORightMouseButton:
							applicationData->lastRightMouseButtonDownView = subview;
							break;
					}

					// Create event
					MOEvent *moEvent = [[MOEvent alloc] initMouseButtonEventWithType:MOMouseButtonDownEventType
														modifiers:modifiers
														mouseButton:mouseButton
														mouseLocation:mouseLocation
														clickCount:1 // FIXME set correct click count
					];

					// Dispatch event
					[subview mouseDown:moEvent];

					// Cleanup
					[moEvent release];
				}
				break;

			case SDL_MOUSEBUTTONUP:
				{
					// Get event information
					MOPoint mouseLocation		= MOMakePoint(event.button.x, applicationData->screenSize.h-event.button.y-1);
					MOMouseButton mouseButton	= MOSDLMouseButtonToMOMouseButton(event.button.button);
					UInt8 modifiers				= MOSDLModToMOKeyModifierMask(SDL_GetModState());

					// Find subview
					MOView *subview = nil;
					switch(mouseButton)
					{
						case MOLeftMouseButton:
							subview = applicationData->lastLeftMouseButtonDownView;
							break;

						case MOMiddleMouseButton:
							subview = applicationData->lastMiddleMouseButtonDownView;
							break;

						case MORightMouseButton:
							subview = applicationData->lastRightMouseButtonDownView;
							break;
					}

					// Create event
					MOEvent *moEvent = [[MOEvent alloc] initMouseButtonEventWithType:MOMouseButtonUpEventType
														modifiers:modifiers
														mouseButton:mouseButton
														mouseLocation:mouseLocation
														clickCount:1 // FIXME set correct click count
					];

					// Dispatch event
					[subview mouseUp:moEvent];

					// Clear relevant subview
					switch(mouseButton)
					{
						case MOLeftMouseButton:
							applicationData->lastLeftMouseButtonDownView = nil;
							break;

						case MOMiddleMouseButton:
							applicationData->lastMiddleMouseButtonDownView = nil;
							break;

						case MORightMouseButton:
							applicationData->lastRightMouseButtonDownView = nil;
							break;
					}


					// Cleanup
					[moEvent release];
				}
				break;

			case SDL_QUIT:
				[self closeScreen];
				break;
		}
	}
}

@end

@implementation MOApplication

- (id)init
{
	if(self = [super init])
	{
		// Create data
		applicationData = calloc(1, sizeof (struct MOApplicationData));

		// Set default values
		applicationData->gameTicksPerSecond = 30;
	}

	return self;
}

- (void)dealloc
{
	SDL_FreeSurface(applicationData->surface);
	SDL_Quit();

	[self setMainView:nil];
	[applicationData->fpsCounter release];

	[super dealloc];
}

#pragma mark -

- (id)model
{
	return applicationData->model;
}

- (void)setModel:(id)aModel
{
	applicationData->model = aModel;
}

- (MOView *)mainView
{
	return applicationData->mainView;
}

- (void)setMainView:(MOView *)aMainView
{
	[aMainView retain];
	[applicationData->mainView release];
	applicationData->mainView = aMainView;
}

- (MOSize)screenSize
{
	return applicationData->screenSize;
}

- (void)setScreenSize:(MOSize)aScreenSize
{
	applicationData->screenSize = aScreenSize;
}

- (BOOL)isFullscreen
{
	return applicationData->isFullscreen;
}

- (void)setFullscreen:(BOOL)aIsFullscreen
{
	applicationData->isFullscreen = aIsFullscreen;
}

- (UInt8)gameTicksPerSecond
{
	return applicationData->gameTicksPerSecond;
}

- (void)setGameTicksPerSecond:(UInt8)aGameTicksPerSecond
{
	applicationData->gameTicksPerSecond = aGameTicksPerSecond;
}

#pragma mark -

- (float)interpolation
{
	return applicationData->interpolation;
}

- (void)setInterpolation:(float)aInterpolation
{
	applicationData->interpolation = aInterpolation;
}

#pragma mark -

- (void)openScreen
{
	// Setup autorelease pool
	[self refreshAutoreleasePool];

	// Initialize SDL
	if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0)
		[NSException raise:@"SDLException" format:@"SDL_Init failed: %s\n", SDL_GetError()];
	atexit(&SDL_Quit);

	// Setup OpenGL attributes
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

	// Create screen
	Uint32 flags = SDL_OPENGL | (applicationData->isFullscreen ? SDL_FULLSCREEN : 0);
	applicationData->surface = SDL_SetVideoMode(applicationData->screenSize.w, applicationData->screenSize.h, 0, flags);
	if(!applicationData->surface)
		[NSException raise:@"SDLException" format:@"SDL_SetVideoMode failed: %s\n", SDL_GetError()];

	// Set up texturing
	if(!gluCheckExtension("GL_EXT_texture_rectangle", glGetString(GL_EXTENSIONS)))
		[NSException raise:@"OpenGLException" format:@"Unsupported extension: GL_EXT_texture_rectangle"];
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

	// Set clear color
	glClearColor(0.0, 0.0, 0.0, 0.0);

	// Enable blending
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	// Enable clipping
	glEnable(GL_SCISSOR_TEST);

	// Set projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0, applicationData->surface->w, 0, applicationData->surface->h);

	// Set modelview matrix
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	// Ignore unused events
	SDL_EventState(SDL_JOYAXISMOTION,	SDL_IGNORE);
	SDL_EventState(SDL_JOYBALLMOTION,	SDL_IGNORE);
	SDL_EventState(SDL_JOYHATMOTION,	SDL_IGNORE);
	SDL_EventState(SDL_JOYBUTTONDOWN,	SDL_IGNORE);
	SDL_EventState(SDL_JOYBUTTONUP,		SDL_IGNORE);
	SDL_EventState(SDL_SYSWMEVENT,		SDL_IGNORE);
	SDL_EventState(SDL_VIDEORESIZE,		SDL_IGNORE);
	SDL_EventState(SDL_VIDEOEXPOSE,		SDL_IGNORE);

	// Make sure key down event have unicode
	SDL_EnableUNICODE(1);

	// We're open!
	applicationData->isOpen = YES;

	// Notify
	[self screenDidLoad];
}

#define MAX_FRAMESKIP		(5)

- (void)enterRunloop
{
	// Create game and draw FPS counters
	MOSpeedCounter *gameSpeedCounter	= [[MOSpeedCounter alloc] init];
	MOSpeedCounter *drawSpeedCounter	= [[MOSpeedCounter alloc] init];

	Uint32	gameTickLength	= 1000/applicationData->gameTicksPerSecond;
	Uint32	nextGameTick	= SDL_GetTicks();

	while(applicationData->isOpen)
	{
		for(int i = 0; SDL_GetTicks() > nextGameTick && i < MAX_FRAMESKIP; ++i)
		{
			// Update game
			// TODO make this [model tick] and [controller tick]
			if([applicationData->model respondsToSelector:@selector(tick)])
				[applicationData->model performSelector:@selector(tick)];
			[applicationData->mainView tick];

			// Record speed
			[gameSpeedCounter tick];

			nextGameTick += gameTickLength;
		}

		// Handle events
		[self handleEvents];

		// Calculate interpolation
		[self setInterpolation:(float)(SDL_GetTicks() + gameTickLength - nextGameTick)/(float)gameTickLength];

		// Redraw
		glClear(GL_COLOR_BUFFER_BIT);
		[applicationData->mainView display];
		SDL_GL_SwapBuffers();

		// Record speed
		[drawSpeedCounter tick];

		// Show speeds
		if([drawSpeedCounter isAtNewSecond])
			printf(
				"[speed] game=%u  draw=%u\n",
				[gameSpeedCounter ticksPerSecond],
				[drawSpeedCounter ticksPerSecond]
			);

		// Empty autorelease pool
		[self refreshAutoreleasePool];
	}
}

- (void)closeScreen
{
	applicationData->isOpen = NO;
}

#pragma mark -

- (MOPoint)mouseLocation
{
	int x,y;
	SDL_GetMouseState(&x, &y);

	return MOMakePoint(x, applicationData->screenSize.h-y-1);
}

#pragma mark -

- (void)screenDidLoad
{
	// Do nothing by default
}

@end