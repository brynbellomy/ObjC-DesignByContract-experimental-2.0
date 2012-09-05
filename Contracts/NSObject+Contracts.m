//
//  NSObject+Contracts.m
//  ObjC-DesignByContracts-2.0
//
//  Created by bryn austin bellomy on 9.4.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <MAObjCRuntime/RTMethod.h>
#import <BrynKit/BrynKit.h>
#import <CocoaLumberjack/DDLog.h>

#import "Contracts2.h"
#import "NSObject+Contracts.h"



/**
 * # @implementation NSObject (Contracts)
 */

@implementation NSObject (Contracts)

/**
 * ## Instance methods
 */

/**
 * #### invariants
 *
 * Stub method called to implement class invariants on an object.
 */

- (void) invariants {
}



/**
 * #### Contracts__SetCurrentPhase:
 *
 * Internal method allowing us to log which phase of a contract has failed.
 *
 * @api private
 */

- (ContractsPhase) Contracts__SetCurrentPhase:(ContractsPhase)phase {
  static ContractsPhase Contracts_CurrentPhase = 0;
  if (phase != 0) Contracts_CurrentPhase = phase;
  return Contracts_CurrentPhase;
}



/**
 * #### asContractProxyingSubclass
 *
 * This is it.  The big deal.
 * 
 * If you want to use contracts on an instance of a class, you must call this method and replace any references you're holding to the original instance with the return value of this method.
 *
 * ```objective-c
 * - (id) init {
 *   self = [super init];
 *   if (self) { ... }
 *   return [self asContractProxyingSubclass];
 * }
 * ```
 *
 * @return {id} itself ... kind of narcissistic, I know.
 */

- (id) asContractProxyingSubclass {
  
  NSString *className = NSStringFromClass([self class]);
  
  NSString *subclassName = [ContractsPrefix_ProxyingSubclassName stringByAppendingString: className];
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
          || sel_isEqual(theMethod.selector, @selector(Contracts__SetCurrentPhase:))
          || [theMethod.selectorName hasPrefix: ContractsPrefix_WrappedMethodSelector]
          || [theMethod.selectorName hasPrefix: ContractsPrefix_PreconditionsSelector]
          || [theMethod.selectorName hasPrefix: ContractsPrefix_PostconditionsSelector]
          || [theMethod.selectorName isEqualToString:@".cxx_destruct"]
          )
      {
        continue;
      }
      
      NSString *strSelector = theMethod.selectorName;
      NSString *classAndSelector = [NSString stringWithFormat:@"%@ %@", className, strSelector];
      
      // A.  hide the actual method by prefixing its selector with INNER_
      {
        RTMethod *renamedMethod = [RTMethod methodWithSelector: ContractsWrappedMethodSelector(theMethod.selector)
                                                implementation: theMethod.implementation
                                                     signature: theMethod.signature];
        [self.class rt_addMethod:renamedMethod];
      }
      
      
      // B.  swizzle in a new method implementation that trampolines up to the invariants, pre, post, and original method implementations
      {
        NSMethodSignature *methodSignature = [self.rt_class instanceMethodSignatureForSelector: theMethod.selector];
        
        // this block is the new IMP for the selector
        [theMethod setImplementation: imp_implementationWithBlock(^(id self, ...) {
          
#if SYNCHRONIZE_CONTRACTS == 1
          @synchronized(self) {
#endif
            
            NSInvocation *mainInvoc = [NSInvocation invocationWithMethodSignature: methodSignature];
            mainInvoc.selector = theMethod.selector;
            
            // copy the variable args list into the NSInvocation
            va_list args;
            va_start(args, self);
            [mainInvoc setArgumentsFromArgumentList:args];
            va_end(args);
            
            // 1) preconditions
            {
              [self Contracts__SetCurrentPhase: ContractsPhase_Preconditions];
              NSInvocation *pre = CreatePreconditionsInvocation(mainInvoc, self);
              [pre invokeWithTarget:self];
              DDLogInfo(([NSString stringWithFormat: COLOR_SEL(@"%@") COLOR_SUCCESS(@" Preconditions passed."), classAndSelector]));
            }
            
            
            // 2) first invariants
            if ([self respondsToSelector: @selector(invariants)]) {
              [self Contracts__SetCurrentPhase: ContractsPhase_FirstInvariants];
              [self invariants];
              DDLogInfo(([NSString stringWithFormat: COLOR_SEL(@"%@") COLOR_SUCCESS(@" First invariants passed."), classAndSelector]));
            }
            
            // (create post invocation at last possible moment)
            NSInvocation *post = CreatePostconditionsInvocation(mainInvoc, self);
            
            
            // 3) call the main method that's being contracted (i.e. the one we prefixed with "INNER_") and capture its return value
            mainInvoc.selector = ContractsWrappedMethodSelector(theMethod.selector);
            [mainInvoc invokeWithTarget:self];
            
            
            // 4) second invariants
            if ([self respondsToSelector: @selector(invariants)]) {
              [self Contracts__SetCurrentPhase: ContractsPhase_SecondInvariants];
              [self invariants];
              DDLogInfo(([NSString stringWithFormat: COLOR_SEL(@"%@") COLOR_SUCCESS(@" Second invariants passed."), classAndSelector]));
            }
            
            
            // 5) postconditions (with main method return value as its last argument)
            void *retval = (void *) Contracts_GetReturnValueForInvokedInvocation(mainInvoc);
            [self Contracts__SetCurrentPhase: ContractsPhase_Postconditions];
            [post setArgument: &retval
                      atIndex: post.methodSignature.numberOfArguments - 1];
            [post invokeWithTarget: self];
            DDLogInfo(([NSString stringWithFormat: COLOR_SEL(@"%@") COLOR_SUCCESS(@" Postconditions passed."), classAndSelector]));
            
#if SYNCHRONIZE_CONTRACTS == 1
          }
#endif
          
        })];
        [subclass addMethod: theMethod];
      }
    }
    
    // register the dynamic proxying subclass and set the classname that 'self' should pose as
    [subclass registerClass];
    existingSubclass = NSClassFromString(subclassName);
  }
  
  
  // annnnnd pose
  if (existingSubclass != nil) {
    object_setClass(self, existingSubclass);
  }
  
  return self;
}


@end





