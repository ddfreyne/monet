#ifndef __MONET_MOGRAPHICSCONTEXT_H__
#define __MONET_MOGRAPHICSCONTEXT_H__

#include <Monet/Common.h>

typedef struct _MOGraphicsContext MOGraphicsContext;

extern COClass MOGraphicsContextClass;

#include <Monet/MORect.h>

SBArray *MOGraphicsContext_getStack(void);
MOGraphicsContext *MOGraphicsContext_getCurrent(void);
MORect MOGraphicsContext_getCurrentRect(void);

void MOGraphicsContext_push(MOGraphicsContext *aGraphicsContext);
void MOGraphicsContext_pop(void);

MORect MOGraphicsContextGetRect(MOGraphicsContext *aGraphicsContext);

#endif
