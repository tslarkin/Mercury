//
//  HMFile.h
//  Hernix
//
//  Created by Timothy Larkin on 4/5/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMPart.h"


@interface HMFile : HMPart {
	FILE *file;
	BOOL eof;
}

@end
