//
//  Contracts2.h
//  langtest
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

#import "Contracts2-Helpers.h"

#define SYNCHRONIZE_ENTIRE_CONTRACT 1


#define PrefixSelector(prefix, selector) \
  ({ NSSelectorFromString([@ # prefix stringByAppendingString: NSStringFromSelector(selector)]); })


#define GetPreconditionsSelectorFromBase(base) \
  ({ NSSelectorFromString([@"PRECONDITIONS__:" stringByAppendingString: NSStringFromSelector(base)]); })


#define GetPostconditionsSelectorFromBase(base) \
  ({ NSSelectorFromString([@"POSTCONDITIONS__:" stringByAppendingFormat:@"%@_result:", NSStringFromSelector(base)]); })


#define Preconditions \
  - (void) PRECONDITIONS__:(id)nilObj


#define Postconditions \
  - (void) POSTCONDITIONS__:(id)nilObj


#define GetResultAs(retType) \
  _result:(retType)result


#define Invariants \
  - (void) invariants { \
    [self invariantsInner]; \
    [super invariants]; \
  } \
  - (void) invariantsInner



NSInvocation *CreatePreconditionsInvocation(NSInvocation *baseInvocation, id target);
NSInvocation *CreatePostconditionsInvocation(NSInvocation *baseInvocation, id target);


@class ContractsProxy;

@interface NSObject (Contracts)

- (void) invariants;
- (id) asContractProxyingSubclass;

@end



@protocol Contracts <NSObject>

- (void) invariants;
- (id) asContractProxyingSubclass;

@end







