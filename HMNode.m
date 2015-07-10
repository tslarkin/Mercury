//
//  HMNode.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMNode.h"


@implementation HMNode

- (HMNode*)superior
{
	return nil;
}

- (NSString*)fullPath
{
	HMNode *superior = [self superior];
	NSString *path;
	if (superior && [superior superior]) {
		path = [superior fullPath];
	}
	else {
		path = @"/";
	}
	return [path stringByAppendingFormat:@"%@/", [self name]];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"%@ %@", [super description], [self fullPath]];
}

//=========================================================== 
//  nodeID 
//=========================================================== 
- (NSString *)nodeID
{
    return nodeID; 
}
- (void)setNodeID:(NSString *)aNodeID
{
    if (nodeID != aNodeID) {
        [aNodeID retain];
        [nodeID release];
        nodeID = aNodeID;
    }
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setName:nil];
    [self setNodeID:nil];
    [super dealloc];
}

//=========================================================== 
//  name 
//=========================================================== 
- (NSString *)name
{
	if (!name) {
		return [[[self class] className] uppercaseString];
	}
    return name; 
}
- (void)setName:(NSString *)aName
{
    if (name != aName) {
        [aName retain];
        [name release];
        name = aName;
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key
{
	
}

@end
