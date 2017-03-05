//
//  HMNode.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 The node is the foundation class for all Hermes
 components. A node has a unique id, and a name,
 which is not guaranteed to be unique.
 
 The fullPath method returns the node name prefixed
 by the node names of the parents up to the root.
*/

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

