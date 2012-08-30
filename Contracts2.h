//
//  Contracts2.h
//  langtest
//
//  Created by bryn austin bellomy on 8.29.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#define SYNCHRONIZE_ENTIRE_CONTRACT 0


//#define Preconditions(methSig)  \
- (void) PRECONDITIONS__ ## methSig
#define Preconditions \
  - (void) PRECONDITIONS__:(id)nilObj

//#define Postconditions(methSig, returnType) \
- (void) POSTCONDITIONS__ ## methSig _result:(returnType)result
#define Postconditions \
  - (void) POSTCONDITIONS__:(id)nilObj

//#define GetResultAs

#define GetResultAs(retType) \
  _result:(retType)result

#define Invariants \
  - (void) invariantsAndSuper { \
    [self invariants]; \
    [super invariants]; \
  } \
  - (void) invariants

#define UseContracts(self) \
  (id)({ \
    ContractsProxy *p = nil; \
    if (self) { \
      p = [ContractsProxy createWithTarget:self]; \
      objc_setAssociatedObject(self, CONTRACTS__proxyAssocObjKey, p, OBJC_ASSOCIATION_RETAIN);  \
      proxySelf = p; \
    } \
    p; \
  })

#define Contracted(classname) \
  classname \
  static ContractsProxy *proxySelf; \
  static char *CONTRACTS__proxyAssocObjKey; \


@class ContractsProxy;

@protocol Contracts <NSObject>
  - (void) invariants;
@end


@interface ContractsProxy : NSProxy
  @property (nonatomic, strong, readwrite) NSObject<Contracts> *target;

  - (id) initWithTarget:(NSObject<Contracts> *)target;
@end


@implementation ContractsProxy

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

#define setInvocationSelf(invocation, newSelf) \
  do { \
    [invocation setArgument:((__bridge void *)newSelf) atIndex:0]; \
  } while(0)

#define setInvocationArg(invocation, newArg, index) do { \
    void *buffer = calloc(1, sizeof(newArg)); \
    memcpy(buffer, newArg, bufferSize); \
    [invocation setArgument:buffer atIndex:index]; \
  } while(0)

#define setInvocationArgNil(invocation, index) do { \
    [invocation setArgument:(__bridge void *)NSNull.null atIndex:index]; \
  } while(0)

void copyInvocationArg(NSInvocation *from, NSInvocation *to, NSUInteger i_src, NSUInteger i_dst) {
  const char *type = [to.methodSignature getArgumentTypeAtIndex:i_dst];
  NSUInteger bufferSize = 0;
  NSGetSizeAndAlignment(type, &bufferSize, NULL);
  void *buffer = calloc(1, bufferSize);
  [from getArgument:buffer atIndex:i_src];
  [to setArgument:buffer atIndex:i_dst];
}

void copyInvocationArgs(NSInvocation *from, NSInvocation *to, NSUInteger dstStart, NSInteger dstOffset) {
  NSLog(@"copyInvocationArgs: to.numArgs = %ld // start = %ld // offset = %ld", to.methodSignature.numberOfArguments, dstStart, dstOffset);
  for (NSUInteger i = dstStart; i < from.methodSignature.numberOfArguments; i++) {
    NSLog(@"i = %ld", i);
    copyInvocationArg(from, to, i, i + dstOffset);
  }
}

void *getReturnValueForInvokedInvocation(NSInvocation *invocation) {
  NSMethodSignature *invocationSignature = [invocation.target methodSignatureForSelector: invocation.selector];
  NSUInteger returnValueSize =  invocationSignature.methodReturnLength;
  if (returnValueSize > 0) {
    void *returnValue = calloc(1, returnValueSize);
    [invocation getReturnValue: &returnValue];
    return returnValue;
  }
  return NULL;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  NSLog(@"FORWARDING %@", NSStringFromSelector(invocation.selector));
  
  const char *type = [invocation.methodSignature getArgumentTypeAtIndex:0];
  NSAssert(type != NULL, @"type is null");
  NSUInteger bufferSize = 0;
  NSGetSizeAndAlignment(type, &bufferSize, NULL);
  void *buffer = calloc(1, bufferSize);                 NSAssert(buffer != NULL, @"buffer is null");
  [invocation getArgument:&buffer atIndex:0];           NSAssert(buffer != NULL, @"arg in buffer is null");
  id theSelf = (__bridge id)buffer;                     NSAssert(theSelf != nil, @"theSelf is nil.");
  NSLog(@"theSelf: %@", theSelf);
  
  setInvocationSelf(invocation, self);
  
  // setup preconditions invocation
  NSInvocation *preconditions = nil;
  SEL sel_pre = NSSelectorFromString([@"PRECONDITIONS__:" stringByAppendingString: NSStringFromSelector(invocation.selector)]);
//  NSLog(@"PRE SEL: %@", NSStringFromSelector(sel_pre));
  if ([self.target respondsToSelector: sel_pre]) {
    NSMethodSignature *preconditionsMethodSig = [self.target methodSignatureForSelector: sel_pre];
//    preconditions = [invocation copy];
    preconditions = [NSInvocation invocationWithMethodSignature:preconditionsMethodSig];
    preconditions.selector = sel_pre;
    setInvocationSelf(preconditions, self);
    setInvocationArgNil(preconditions, 1);
    NSLog(@"prrreeee");
    copyInvocationArgs(invocation, preconditions, 2, 1);
  }
  
  
  // setup postconditions invocation
  NSInvocation *postconditions = nil;
  SEL sel_post = NSSelectorFromString([@"POSTCONDITIONS__:" stringByAppendingFormat:@"%@_result:", NSStringFromSelector(invocation.selector)]);
  
  if ([self.target respondsToSelector: sel_pre]) {
    NSMethodSignature *postconditionsMethodSig = [self.target methodSignatureForSelector: sel_post];
    NSAssert(postconditionsMethodSig != nil, @"postconditionsMethodSig is nil.");
    postconditions = [NSInvocation invocationWithMethodSignature: postconditionsMethodSig];
    postconditions.selector = sel_post;
    setInvocationSelf(postconditions, self);
    setInvocationArgNil(postconditions, 1);
    NSLog(@"poooossstttt");
    copyInvocationArgs(invocation, postconditions, 2, 1);
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




@interface NSObject (Contracts)
- (void) invariants;
@end

@implementation NSObject (Contracts)

- (void) invariants {
  NSLog(@"NSObject invariants");
}

@end
