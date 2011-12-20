typedef struct _MOApplication MOApplication;

#import <Monet/MOPoint.h>
#import <Monet/MOSize.h>
#import <Monet/MOState.h>

MOApplication *MOApplicationCreate(void);

MOSize MOApplicationGetScreenSize(MOApplication *self);
void MOApplicationSetScreenSize(MOApplication *self, MOSize aSize);

bool MOApplicationIsFullscreen(MOApplication *self);
void MOApplicationSetIsFullscreen(MOApplication *self, bool aIsFullscreen);

uint8_t MOApplicationGetGameTicksPerSecond(MOApplication *self);
void MOApplicationSetGameTicksPerSecond(MOApplication *self, uint8_t aGameTicksPerSecond);

uint8_t MOApplicationGetMaxFrameskip(MOApplication *self);
void MOApplicationSetMaxFrameskip(MOApplication *self, uint8_t aMaxFrameskip);

MOState *MOApplicationGetCurrentState(MOApplication *self);
void MOApplicationPushState(MOApplication *self, MOState *aState);
MOState *MOApplicationPopCurrentState(MOApplication *self);
MOState *MOApplicationReplaceCurrentState(MOApplication *self, MOState *aState);

void MOApplicationOpenScreen(MOApplication *self);
void MOApplicationEnterRunloop(MOApplication *self);
void MOApplicationCloseScreen(MOApplication *self);

float MOApplicationGetInterpolation(MOApplication *self);
MOPoint MOApplicationGetMouseLocation(MOApplication *self);
