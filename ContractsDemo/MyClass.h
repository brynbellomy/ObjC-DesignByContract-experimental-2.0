//
//  MyClass.h  
//  ObjC-DesignByContracts-2.0  
//
//  Created by bryn austin bellomy on 8.29.12.  
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.  
//

#import "ObjC-DesignByContract.h"

@interface MyClass : NSObject <Contracts>

- (NSString *) myName:(NSString *)something;

@property (nonatomic, copy, readwrite) NSString *dog;

@end

