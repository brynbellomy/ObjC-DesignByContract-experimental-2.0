//
//  MyClass.h
//  langtest
//
//  Created by bryn austin bellomy on 8.29.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "Contracts2.h"

@interface MyClass : NSObject <Contracts>
  - (NSString *) myName:(NSString *)something;
  @property (nonatomic, copy, readwrite) NSString *dog;
@end

@interface ContractsProxy (MyClass)
  @property (nonatomic, copy, readwrite) NSString *dog;
@end


@interface Contract_ProxyingSubclass_MyClass : MyClass
  @property (nonatomic, copy, readwrite) NSString *dog;
@end

