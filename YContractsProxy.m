//
//  YContractsProxy.m
//  ObjC-DesignByContracts-experimental-2.0
//
//  Created by bryn austin bellomy on 8.30.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "YContractsProxy.h"

@implementation YContractsProxy

//- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
//  return [self.target methodSignatureForSelector:aSelector];
//}

- (void)forwardInvocation:(NSInvocation *)invocation {
  NSString *_debug_forwarded_selector_str = NSStringFromSelector(invocation.selector);
  NSLog(@"FORWARDING %@", _debug_forwarded_selector_str);
  
  setInvocationSelf(invocation, self);
  
  // setup preconditions invocation
  
  
  
  // setup postconditions invocation
  NSInvocation *postconditions = nil;
  SEL sel_post = NSSelectorFromString([@"POSTCONDITIONS__:" stringByAppendingFormat:@"%@_result:", NSStringFromSelector(invocation.selector)]);
  
  if ([self.target respondsToSelector: sel_post]) {
    NSMethodSignature *postconditionsMethodSig = [self.target methodSignatureForSelector: sel_post];
    NSAssert(postconditionsMethodSig != nil, @"postconditionsMethodSig is nil.");
    postconditions = [NSInvocation invocationWithMethodSignature: postconditionsMethodSig];
    postconditions.selector = sel_post;
    setInvocationSelf(postconditions, self);
    setInvocationArgNil(postconditions, 2);
    copyInvocationArgs(invocation, postconditions, 2, 1);
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
    NSString *str_ret = (__bridge NSString *) getReturnValueForInvokedInvocation(invocation);
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



//@implementation NSObject (Contracts)
//
//- (void) invariants {
//  NSLog(@"NSObject invariants");
//}
//
//@end





