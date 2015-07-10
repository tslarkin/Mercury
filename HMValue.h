//
//  HMValue.h
//  Hermes
//
//  Created by Timothy Larkin on 11/11/06.
//  Copyright 2006 AbstractTools. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HMValue : NSManagedObject {

}

- (NSManagedObject *)port;
- (void)setPort:(NSManagedObject *)value;
- (BOOL)validatePort: (id *)valueRef error:(NSError **)outError;

- (id)defaultValue;
- (void)setValue:(id)value;
- (id)value;
- (BOOL)isRemoteValue;
- (NSString*)transformedValue;
- (void)reverseTransformValue:(NSString*)string;

@end
