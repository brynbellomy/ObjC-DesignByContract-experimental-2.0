//
//  Contracts2-Helpers.h
//  langtest
//
//  Created by bryn austin bellomy on 8.30.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//



/**
 *
 */
#ifndef Contracts_SetInvocationSelf
#define Contracts_SetInvocationSelf(invocation, newSelf) \
  do { \
    [invocation setArgument:((__bridge void *)newSelf) atIndex:0]; \
  } while(0)
#endif



/**
 *
 */
#ifndef Contracts_SetInvocationArg
#define Contracts_SetInvocationArg(invocation, newArg, index) \
  do { \
    void *buffer = calloc(1, sizeof(newArg)); \
    memcpy(buffer, newArg, bufferSize); \
    [invocation setArgument:&buffer atIndex:index]; \
} while(0)
#endif



/**
 *
 */
#ifndef Contracts_SetInvocationArgNil
#define Contracts_SetInvocationArgNil(invocation, index) \
  do { \
    [invocation setArgument:(__bridge void *)NSNull.null atIndex:index]; \
  } while(0)
#endif







