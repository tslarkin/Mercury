//
//  HMNode.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMNode : NSObject {
	NSString *nodeID;
	NSString *name;
}

- (NSString *)nodeID;
- (void)setNodeID:(NSString *)aNodeID;
- (NSString *)name;
- (void)setName:(NSString *)aName;

- (HMNode*)superior;
- (NSString*)fullPath;

@end

