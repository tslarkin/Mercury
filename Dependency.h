//
//  Dependency.h
//  Hernix
//
//  Created by Timothy Larkin on 4/5/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>

// This is an actor who performs a dependency analysis in two forms.
@interface Dependency : NSObject {
}

// Returns a list of components in rate phase dependency order.
- (NSArray*)orderComponents:(NSArray*) p;
// Returns a list of lists. Each sublist contains a set
// of components that can be asynchronously updated in
// the rate phase.
-(NSArray*)concurrentOrdering:(NSArray*)p;

@end
