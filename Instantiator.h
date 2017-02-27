//
//  Instantiator.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HMPart;
@class HMLevel;

NSArray *XMLtoDictionaries(NSString *path);
HMLevel *partsFromDictionaries(NSArray *dictionaries);
NSDictionary *buildMatrix(NSArray *dictionaries, int rows, int columns);
void wireMatrix(NSDictionary *map);
void recordUnderflow(HMPart *part);
void printUnderflowRecords();
