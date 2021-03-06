#include <Monet/MOTimer.h>

#include <Monet/Common.h>

struct _MOTimer
{
	COGuts      guts;

	SDL_TimerID	timerID;

	uint32_t    interval;
	double      duration;

	void        *userInfo;
};

void _MOTimerDestroy(void *aTimer);

COClass MOTimerClass = {
	.superclass = NULL,
	.destructor = &_MOTimerDestroy
};

Uint32 _MOTimerFired(uint32_t aInterval, void *aParam)
{
	MOTimer *timer = (MOTimer *)aParam;

	SDL_Event event;
	event.type = SDL_USEREVENT;
	event.user.data1 = timer;
	SDL_PushEvent(&event);

	return MOTimerGetDuration(timer);
}

MOTimer *MOTimerCreate(double aDuration, void *aUserInfo)
{
	MOTimer *timer = malloc(sizeof (MOTimer));
	COInit(timer, &MOTimerClass);

	timer->duration = aDuration;
	timer->userInfo = aUserInfo;

	return timer;
}

void _MOTimerDestroy(void *aTimer)
{
	MOTimer *timer = (MOTimer *)aTimer;

	MOTimerStop(timer);
}

double MOTimerGetDuration(MOTimer *aTimer)
{
	return aTimer->duration;
}

void *MOTimerGetUserInfo(MOTimer *aTimer)
{
	return aTimer->userInfo;
}

void MOTimerStart(MOTimer *aTimer)
{
	aTimer->timerID = SDL_AddTimer(
		(uint32_t)(aTimer->duration * 1000.0l),
		&_MOTimerFired,
		aTimer);
}

void MOTimerStop(MOTimer *aTimer)
{
	SDL_RemoveTimer(aTimer->timerID);
}
