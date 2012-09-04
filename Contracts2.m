//
//  Contracts2.m
//  langtest
//
//  Created by bryn austin bellomy on 8.30.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "Contracts2.h"

/**
 * Function prototypes.
 */

NSInvocation *CreatePreconditionsInvocation(NSInvocation *baseInvocation, id target);
NSInvocation *CreatePostconditionsInvocation(NSInvocation *baseInvocation, id target);
void Contracts_CopyInvocationArg(NSInvocation *from, NSInvocation *to, NSUInteger i_src, NSUInteger i_dst);
void Contracts_CopyInvocationArgs(NSInvocation *from, NSInvocation *to, NSUInteger dstStart, NSInteger dstOffset);
void *Contracts_GetReturnValueForInvokedInvocation(NSInvocation *invocation);

/**
 * # CreatePreconditionsInvocation()
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
    NSLog(@">> TARGET DOES NOT RESPOND TO PRECONDITIONS OF %@ (selector is \"%@\")", NSStringFromSelector(baseInvocation.selector), NSStringFromSelector(sel_pre));
    return nil;
  }
}



/**
 * # CreatePostconditionsInvocation()
 */

NSInvocation *CreatePostconditionsInvocation(NSInvocation *baseInvocation, id target) {
  SEL sel_post = GetPostconditionsSelectorFromBase(baseInvocation.selector);
  if ([target respondsToSelector: sel_post]) {
    NSMethodSignature *postconditionsMethodSig = [target methodSignatureForSelector: sel_post];     NSCAssert(postconditionsMethodSig != nil, @"postconditionsMethodSig is nil.");
    NSInvocation *postconditions = [NSInvocation invocationWithMethodSignature: postconditionsMethodSig];
    
    postconditions.selector = sel_post;
    Contracts_SetInvocationSelf(postconditions, target);
    Contracts_SetInvocationArgNil(postconditions, 2);
    Contracts_CopyInvocationArgs(baseInvocation, postconditions, 2, 1);
    [postconditions retainArguments];
    
    return postconditions;
  }
  else {
    NSLog(@">> TARGET DOES NOT RESPOND TO POSTCONDITIONS OF %@ (selector is \"%@\")", NSStringFromSelector(baseInvocation.selector), NSStringFromSelector(sel_post));
    return nil;
  }
}



/**
 * # Contracts_CopyInvocationArg()
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
 * # Contracts_CopyInvocationArgs()
 */

void Contracts_CopyInvocationArgs(NSInvocation *from, NSInvocation *to, NSUInteger dstStart, NSInteger dstOffset) {
  NSLog(@"copyInvocationArgs: to.numArgs = %ld // start = %ld // offset = %ld", to.methodSignature.numberOfArguments, dstStart, dstOffset);
  for (NSUInteger i = dstStart; i < from.methodSignature.numberOfArguments; i++) {
    Contracts_CopyInvocationArg(from, to, i, i + dstOffset);
  }
}



/**
 * #### Contracts_GetReturnValueForInvokedInvocation()
 *
 * @param {NSInvocation*} invocation - The already-invoked NSInvocation object
 *   whose return value you seek.
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



/**
 * # @impl NSObject (Contracts)
 */

@implementation NSObject (Contracts)



/**
 * #### - (void) invariants
 */

- (void) invariants {
  NSLog(@"NSObject invariants");
}



/**
 * #### - (id) asContractProxyingSubclass
 */

- (id) asContractProxyingSubclass {
  
  NSString *subclassName = [@"Contract_ProxyingSubclass_" stringByAppendingString: NSStringFromClass([self class])];
  Class existingSubclass = NSClassFromString(subclassName);
  
  if (existingSubclass == nil) {
    RTUnregisteredClass *subclass = [self.class rt_createUnregisteredSubclassNamed:subclassName];
    
    if (subclass == nil)
      return self;
    
    NSArray *methods = self.class.rt_methods;
    for (RTMethod *theMethod in methods) {
      if (
          ext_getImmediateInstanceMethod(self.class, theMethod.selector) == NULL
          || sel_isEqual(theMethod.selector, @selector(invariants))
          || sel_isEqual(theMethod.selector, @selector(invariantsInner))
          || sel_isEqual(theMethod.selector, @selector(asContractProxyingSubclass))
          || sel_isEqual(theMethod.selector, @selector(init))
          || [theMethod.selectorName hasPrefix:@"INNER_"]
          || [theMethod.selectorName hasPrefix:@"PRECONDITIONS_"]
          || [theMethod.selectorName hasPrefix:@"POSTCONDITIONS_"]
          || [theMethod.selectorName isEqualToString:@".cxx_destruct"]
          )
      {
        continue;
      }
      
      
      // A.  hide method in INNER_ prefix
      {
        RTMethod *renamedMethod = [RTMethod methodWithSelector: PrefixSelector(INNER__, theMethod.selector)
                                                implementation: theMethod.implementation
                                                     signature: theMethod.signature];
        [self.class rt_addMethod:renamedMethod];
      }
      // end A
      
      
      // B.  swizzle in a new method implementation that trampolines up to the invariants, pre, post, and original method implementations
      {
        NSMethodSignature *methodSignature = [self.rt_class instanceMethodSignatureForSelector: theMethod.selector];
        
        // the new IMP
        [theMethod setImplementation: imp_implementationWithBlock(^(id self, ...) {
          
          NSInvocation *mainInvoc = [NSInvocation invocationWithMethodSignature: methodSignature];
          mainInvoc.selector = theMethod.selector;
          
          // copy the variable args list into the NSInvocation
          va_list args;
          va_start(args, self);
          [mainInvoc setArgumentsFromArgumentList:args];
          va_end(args);
          
          // 1. preconditions
          {
            NSInvocation *pre = CreatePreconditionsInvocation(mainInvoc, self);
            [pre invokeWithTarget:self];
          }
          
          
          // 2. first invariants
          if ([self respondsToSelector: @selector(invariants)])
            [self invariants];
          
          
          // (create post invocation at last possible moment)
          NSInvocation *post = CreatePostconditionsInvocation(mainInvoc, self);
          
          
          // 3. call the main method that's being contracted (i.e. the one we
          //    prefixed with "INNER_") and capture its return value
          mainInvoc.selector = PrefixSelector(INNER__, theMethod.selector);
          [mainInvoc invokeWithTarget:self];
          
          
          // 4. second invariants
          if ([self respondsToSelector:@selector(invariants)])
            [self invariants];
          
          
          // 5. postconditions (with main method return value as its last argument)
          void *retval = (void *) Contracts_GetReturnValueForInvokedInvocation(mainInvoc);
          [post setArgument: &retval
                    atIndex: post.methodSignature.numberOfArguments - 1];
          [post invokeWithTarget: self];
          
          
        })];
        [subclass addMethod: theMethod];
      }
      // end B
    }
    
    // register the dynamic proxying subclass and set the classname that 'self' should pose as
    [subclass registerClass];
    existingSubclass = NSClassFromString(subclassName);
  }
  
  
  // pose
  if (existingSubclass != nil) {
    object_setClass(self, existingSubclass);
  }
  
  return self;
}


@end




/*@implementation ContractsProxy
 
 - (id) initWithTarget:(NSObject<Contracts> *)target {
 self.target = target;
 return self;
 }
 
 + (ContractsProxy *) createWithTarget:(id<Contracts>)target {
 ContractsProxy *p = [[ContractsProxy alloc] initWithTarget:target];
 return p;
 }
 
 
 - (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
 return [self.target methodSignatureForSelector:aSelector];
 }
 
 - (void)forwardInvocation:(NSInvocation *)invocation {
 NSString *_debug_forwarded_selector_str = NSStringFromSelector(invocation.selector);
 NSLog(@"FORWARDING %@", _debug_forwarded_selector_str);
 
 Contracts_SetInvocationSelf(invocation, self);
 
 // setup preconditions invocation
 NSInvocation *preconditions = nil;
 SEL sel_pre = NSSelectorFromString([@"PRECONDITIONS__:" stringByAppendingString: NSStringFromSelector(invocation.selector)]);
 if ([self.target respondsToSelector: sel_pre]) {
 NSMethodSignature *preconditionsMethodSig = [self.target methodSignatureForSelector: sel_pre];
 preconditions = [NSInvocation invocationWithMethodSignature:preconditionsMethodSig];
 preconditions.selector = sel_pre;
 Contracts_SetInvocationSelf(preconditions, self);
 Contracts_SetInvocationArgNil(preconditions, 2);
 Contracts_CopyInvocationArgs(invocation, preconditions, 2, 1);
 }
 else {
 NSLog(@">> TARGET DOES NOT RESPOND TO PRECONDITIONS OF %@", _debug_forwarded_selector_str);
 }
 
 
 // setup postconditions invocation
 NSInvocation *postconditions = nil;
 SEL sel_post = NSSelectorFromString([@"POSTCONDITIONS__:" stringByAppendingFormat:@"%@_result:", NSStringFromSelector(invocation.selector)]);
 
 if ([self.target respondsToSelector: sel_post]) {
 NSMethodSignature *postconditionsMethodSig = [self.target methodSignatureForSelector: sel_post];
 NSAssert(postconditionsMethodSig != nil, @"postconditionsMethodSig is nil.");
 postconditions = [NSInvocation invocationWithMethodSignature: postconditionsMethodSig];
 postconditions.selector = sel_post;
 Contracts_SetInvocationSelf(postconditions, self);
 Contracts_SetInvocationArgNil(postconditions, 2);
 Contracts_CopyInvocationArgs(invocation, postconditions, 2, 1);
 }
 else {
 NSLog(@">> TARGET DOES NOT RESPOND TO POSTCONDITIONS OF %@", _debug_forwarded_selector_str);
 NSLog(@">> (selector is %@)", NSStringFromSelector(sel_post));
 }
 
 // start calling shit
 
 #if SYNCHRONIZE_ENTIRE_CONTRACT == 1
 @synchronized (self) {
 #endif
 // first invariants
 if ([self.target respondsToSelector:@selector(invariants)]) {
 [self.target invariants];
 }
 
 // preconditions
 [preconditions invokeWithTarget:self.target];
 
 // call the main method and get its return value
 [invocation invokeWithTarget:self.target];
 
 // postconditions with main method return value as its last argument
 NSString *str_ret = (__bridge NSString *) Contracts_GetReturnValueForInvokedInvocation(invocation);
 [postconditions setArgument: &str_ret
 atIndex: postconditions.methodSignature.numberOfArguments - 1];
 [postconditions invokeWithTarget: self.target];
 
 // second invariants
 if ([self.target respondsToSelector:@selector(invariants)])
 [self.target invariants];
 
 
 #if SYNCHRONIZE_ENTIRE_CONTRACT == 1
 }
 #endif
 
 }
 
 - (BOOL)respondsToSelector:(SEL)aSelector {
 return [self.target respondsToSelector:aSelector];
 }
 
 
 @end
 
 */




