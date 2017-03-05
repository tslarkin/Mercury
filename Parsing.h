//
//  Parsing.h
//  Hernix
//
//  Created by Timothy Larkin on 8/20/08.
//  Copyright 2008 Cornell University. All rights reserved.
//

// #import <Cocoa/Cocoa.h>
#import "Value.h"

// Parse a Value from a character buffer.
// If you don't know Lex and Yacc, don't bother trying to understand
// how this works. If you do know Lex and Yacc, or Flex and Bison,
// this will be trivial.
unsigned valueParse(const char *buf, Value *value, char *errorStr);


