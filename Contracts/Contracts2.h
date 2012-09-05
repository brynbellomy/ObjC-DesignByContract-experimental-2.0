//
//  Contracts2.h  
//  ObjC-DesignByContracts-2.0  
//
//  Created by bryn austin bellomy on 8.29.12.  
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.  
//

#import <objc/objc-runtime.h>
#import <MAObjCRuntime/MARTNSObject.h>
#import <MAObjCRuntime/RTUnregisteredClass.h>
#import <MAObjCRuntime/RTMethod.h>

#import "NSInvocation+EXT.h"
#import "EXTRuntimeExtensions.h"


#ifndef SYNCHRONIZE_CONTRACTS
#  define SYNCHRONIZE_CONTRACTS 1
#endif



#define ContractsPrefix_PreconditionsSelector  @"PRECONDITIONS__:"
#define ContractsPrefix_PostconditionsSelector @"POSTCONDITIONS__:"
#define ContractsPrefix_WrappedMethodSelector  @"INNER__"
#define ContractsPrefix_ProxyingSubclassName   @"Contracts_ProxyingSubclass_"


typedef enum {
  ContractsPhase_Preconditions = (1 << 0),
  ContractsPhase_FirstInvariants = (1 << 1),
  ContractsPhase_SecondInvariants = (1 << 2),
  ContractsPhase_Postconditions = (1 << 3)
} ContractsPhase;


/**
 * # That()
 */

#define That(test, msg, ...) \
  do { \
    if (!(test)) { \
      NSMutableString *classAndMethod = [[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString: ContractsPrefix_ProxyingSubclassName withString: @""] mutableCopy]; \
      \
      NSString *conditionType = nil; \
      ContractsPhase phase = [self Contracts__SetCurrentPhase:0];  \
      switch (phase) { \
        case ContractsPhase_Preconditions: \
          [classAndMethod appendFormat:@" %@", [NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString: ContractsPrefix_PreconditionsSelector withString:@""]]; \
          conditionType = @"precondition"; \
          break; \
        case ContractsPhase_FirstInvariants: \
          [classAndMethod appendString:@" invariants"]; \
          conditionType = @"invariant"; \
          break; \
        case ContractsPhase_SecondInvariants: \
          [classAndMethod appendString:@" invariants"]; \
          conditionType = @"invariant"; \
          break; \
        case ContractsPhase_Postconditions: \
          [classAndMethod appendFormat:@" %@", [NSStringFromSelector(_cmd) stringByReplacingOccurrencesOfString: ContractsPrefix_PostconditionsSelector withString:@""]]; \
          conditionType = @"postcondition"; \
          break; \
        default: \
          break; \
      } \
      \
      NSString *message = [NSString stringWithFormat: msg, ## __VA_ARGS__]; \
      DDLogError(COLOR_ERROR(@"Failed %@ in ") COLOR_SEL(@"%@") @": " @ # test @".  %@", conditionType, classAndMethod, message); \
      NSAssert1(NO, @"Failed while evaluating %@s.", conditionType); \
    } \
  } while(0)


#define Preconditions \
  - (void) PRECONDITIONS__:(id)nilObj


#define Postconditions \
  - (void) POSTCONDITIONS__:(id)nilObj


#define GetResultAs(retType) \
  _result:(retType)result



/**
 * 
 */

#define Invariants \
  - (void) invariants { \
    [self invariantsInner]; \
    [super invariants]; \
  } \
  - (void) invariantsInner



/**
 *
 */
#define Contracts_SetInvocationSelf(invocation, newSelf) \
  do { \
    [invocation setArgument:((__bridge void *)newSelf) atIndex:0]; \
  } while(0)



/**
 *
 */
#define Contracts_SetInvocationArg(invocation, newArg, index) \
  do { \
    void *buffer = calloc(1, sizeof(newArg)); \
    memcpy(buffer, newArg, bufferSize); \
    [invocation setArgument:&buffer atIndex:index]; \
  } while(0)



/**
 *
 */
#define Contracts_SetInvocationArgNil(invocation, index) \
  do { \
    [invocation setArgument:(__bridge void *)NSNull.null atIndex:index]; \
  } while(0)



/**
 *
 */

#define ContractsWrappedMethodSelector(selector) \
  ({ NSSelectorFromString([ContractsPrefix_WrappedMethodSelector stringByAppendingString: NSStringFromSelector(selector)]); })



/**
 *
 */

#define GetPreconditionsSelectorFromBase(base) \
  ({ NSSelectorFromString([ContractsPrefix_PreconditionsSelector stringByAppendingString: NSStringFromSelector(base)]); })



/**
 *
 */

#define GetPostconditionsSelectorFromBase(base) \
  ({ NSSelectorFromString([ContractsPrefix_PostconditionsSelector stringByAppendingFormat:@"%@_result:", NSStringFromSelector(base)]); })




NSInvocation *CreatePreconditionsInvocation(NSInvocation *baseInvocation, id target);
NSInvocation *CreatePostconditionsInvocation(NSInvocation *baseInvocation, id target);
void Contracts_CopyInvocationArg(NSInvocation *from, NSInvocation *to, NSUInteger i_src, NSUInteger i_dst);
void Contracts_CopyInvocationArgs(NSInvocation *from, NSInvocation *to, NSUInteger dstStart, NSInteger dstOffset);
void *Contracts_GetReturnValueForInvokedInvocation(NSInvocation *invocation);



@protocol Contracts <NSObject>

- (void) invariants;
- (id) asContractProxyingSubclass;
- (ContractsPhase) Contracts__SetCurrentPhase:(ContractsPhase)phase;

@end







