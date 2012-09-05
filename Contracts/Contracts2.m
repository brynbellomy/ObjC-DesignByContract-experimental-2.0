//
//  Contracts2.m
//  ObjC-DesignByContracts-2.0
//
//  Created by bryn austin bellomy on 8.30.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <BrynKit/BrynKit.h>
#import <CocoaLumberjack/DDLog.h>
#import <MAObjCRuntime/RTMethod.h>

#import "Contracts2.h"

/**
 * # @module Contracts
 */

/**
 * #### CreatePreconditionsInvocation()
 *
 * Creates an NSInvocation instance capable of calling the method that implements the precondition checks for a given method.
 *
 * @param {[NSInvocation*]} baseInvocation The invocation that the precondition invocation will be created to target.
 * @param {[id]} target The object upon which the original method (pointed to by baseInvocation) resides.
 * @return {[NSInvocation*]} The preconditions invocation.
 */

NSInvocation *CreatePreconditionsInvocation(NSInvocation *baseInvocation, id target) {
  SEL sel_pre = GetPreconditionsSelectorFromBase(baseInvocation.selector);
  if ([target respondsToSelector: sel_pre]) {
    NSMethodSignature *preconditionsMethodSig = [target methodSignatureForSelector: sel_pre];
    NSInvocation *preconditions = [NSInvocation invocationWithMethodSignature:preconditionsMethodSig];
    
    preconditions.selector = sel_pre;
    Contracts_SetInvocationSelf(preconditions, target);
    Contracts_SetInvocationArgNil(preconditions, 2);
    Contracts_CopyInvocationArgs(baseInvocation, preconditions, 2, 1);
    [preconditions retainArguments];
    
    return preconditions;
  }
  else {
    return nil;
  }
}



/**
 * #### CreatePostconditionsInvocation()
 *
 * Creates an NSInvocation instance capable of calling the method that implements the postcondition checks for a given method.
 *
 * @param {[NSInvocation*]} baseInvocation The invocation that the postcondition invocation will be created to target.
 * @param {[id]} target The object upon which the original method (pointed to by baseInvocation) resides.
 * @return {[NSInvocation*]} The postconditions invocation.
 */

NSInvocation *CreatePostconditionsInvocation(NSInvocation *baseInvocation, id target) {
  SEL sel_post = GetPostconditionsSelectorFromBase(baseInvocation.selector);
  if ([target respondsToSelector: sel_post]) {
    NSMethodSignature *postconditionsMethodSig = [target methodSignatureForSelector: sel_post];
    NSInvocation *postconditions = [NSInvocation invocationWithMethodSignature: postconditionsMethodSig];
    
    postconditions.selector = sel_post;
    Contracts_SetInvocationSelf(postconditions, target);
    Contracts_SetInvocationArgNil(postconditions, 2);
    Contracts_CopyInvocationArgs(baseInvocation, postconditions, 2, 1);
    [postconditions retainArguments];
    
    return postconditions;
  }
  else {
    return nil;
  }
}



/**
 * #### Contracts_CopyInvocationArg()
 * 
 * Helper method that copies a single argument from one NSInvocation object to another.
 */

void Contracts_CopyInvocationArg(NSInvocation *from, NSInvocation *to, NSUInteger i_src, NSUInteger i_dst) {
  const char *type = [to.methodSignature getArgumentTypeAtIndex:i_dst];
  NSUInteger bufferSize = 0;
  NSGetSizeAndAlignment(type, &bufferSize, NULL);
  
  void *buffer = calloc(1, bufferSize);
  [from getArgument:&buffer atIndex:i_src];
  [to setArgument:&buffer atIndex:i_dst];
}



/**
 * #### Contracts_CopyInvocationArgs()
 *
 * Helper method that copies all of the arguments from one NSInvocation object to another, beginning with the argument at index `dstStart`.
 */

void Contracts_CopyInvocationArgs(NSInvocation *from, NSInvocation *to, NSUInteger dstStart, NSInteger dstOffset) {
  for (NSUInteger i = dstStart; i < from.methodSignature.numberOfArguments; i++) {
    Contracts_CopyInvocationArg(from, to, i, i + dstOffset);
  }
}



/**
 * #### Contracts_GetReturnValueForInvokedInvocation()
 *
 * @param {[NSInvocation*]} invocation The already-invoked NSInvocation object whose return value you seek.
 * @return {[void*]} A void pointer to a chunk of memory containing the untyped return value of `invocation`.
 */

void *Contracts_GetReturnValueForInvokedInvocation(NSInvocation *invocation) {
  NSMethodSignature *invocationSignature = [invocation.target methodSignatureForSelector: invocation.selector];
  NSUInteger returnValueSize =  invocationSignature.methodReturnLength;
  if (returnValueSize > 0) {
    void *returnValue = calloc(1, returnValueSize);
    [invocation getReturnValue: &returnValue];
    return returnValue;
  }
  return NULL;
}



