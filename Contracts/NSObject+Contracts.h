//
//  NSObject+Contracts.h
//  ObjC-DesignByContracts-2.0
//
//  Created by bryn austin bellomy on 9.4.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contracts2.h"

@protocol Contracts;

@interface NSObject (Contracts) <Contracts>

- (id) asContractProxyingSubclass;
- (void) invariants;
- (ContractsPhase) Contracts__SetCurrentPhase:(ContractsPhase)phase;

@end

