//
//  Dependency.h
//  Hernix
//
//  Created by Timothy Larkin on 4/5/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Dependency : NSObject {
}

- (NSArray*)orderComponents:(NSArray*) p;
-(NSArray*)concurrentOrdering:(NSArray*)p;

@end
