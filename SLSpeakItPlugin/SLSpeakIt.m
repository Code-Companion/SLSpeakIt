//
//  SLSpeakIt.m
//  SLSpeakItPlugin
//
//  Created by Transcend on 8/14/14.
//  Copyright (c) 2014 SunLoveSystems. All rights reserved.
//

#import "SLSpeakIt.h"

static SLSpeakIt *speaker = nil;

@implementation SLSpeakIt

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	[self speaker];
}

+ (SLSpeakIt *)speaker
{
    NSLog(@"Launching SLSpeakIt...");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        speaker = [[self alloc] init];
    });
    
    return speaker;
}

- (id)init
{
    if (self = [super init]) {
        [self addMenuItems];
    }
    return self;
}

- (void)addMenuItems {
    NSMenu *mainMenu = [NSApp mainMenu];
    
    NSMenuItem *editMenu = [mainMenu itemAtIndex:2];
    self.onOffSwitch = [[NSMenuItem alloc] initWithTitle:@"Start SpeakIt" action:@selector(didClickBeginSpeakIt:) keyEquivalent:@""];
    [self.onOffSwitch setTarget:self];
    [[editMenu submenu] addItem:self.onOffSwitch];
}

- (void)didClickBeginSpeakIt:(id)sender
{
    [self.onOffSwitch setTitle:@"Stop SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickStopSpeakIt:)];
    // Consider using NSUserDefaults for storing data between sessions
    self.variablesArray = [[NSMutableArray alloc] init];
    self.collectionsArray = [[NSMutableArray alloc] init];
    self.previousInputArray = [[NSMutableArray alloc] init];
    self.translatedCodeArray = [[NSMutableArray alloc] init];
    self.lineEnd = @". Next.\n";
    self.progMode = 0;
    NSLog(@"Started SpeakIt");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(didChangeText:)
                                                name:NSTextDidChangeNotification
                                              object:nil];
}

- (void)didChangeText:(NSNotification *) notification {
    if ([[notification object] isKindOfClass:[NSTextView class]] && [[notification object] isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        self.textView = (NSTextView *)[notification object];
        
        self.rawInputString = self.textView.textStorage.string;
        NSLog(@"The raw input string is: %@", self.rawInputString);
        
        [self tryReplacingStringWithCode];
        NSLog(@"Translated code string is %@", self.translatedCodeString);
    }
}

#pragma mark - case identification

- (void)tryReplacingStringWithCode
{
    // case - create an integer variable
    if ([self.rawInputString rangeOfString:@"Create an integer variable. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create an integer variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create a float variable
    } else if ([self.rawInputString rangeOfString:@"Create a float variable. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a float variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create a double variable
    } else if ([self.rawInputString rangeOfString:@"Create a double variable. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a double variable. Call it ";
        [self setVariableNameAndValue];
        
    // case - create a string variable
    } else if ([self.rawInputString rangeOfString:@"Create a string variable. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a string variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create an unsigned integer NSUInteger variable
    } else if ([self.rawInputString rangeOfString:@"Create an unsigned integer variable. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create an unsigned integer variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create an array
    } else if ([self.rawInputString rangeOfString:@"Create an array. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create an array. Call it ";
        [self setArrayOrSetName];
        
    // case - create a mutable array
    } else if ([self.rawInputString rangeOfString:@"Create a mutable array. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a mutable array. Call it ";
        [self setArrayOrSetName];
        
    // case - create a set
    } else if ([self.rawInputString rangeOfString:@"Create a set. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a set. Call it ";
        [self setArrayOrSetName];
    
    // case - create a mutable set
    } else if ([self.rawInputString rangeOfString:@"Create a mutable set. Call it " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a mutable set. Call it ";
        [self setArrayOrSetName];
        
    // case - add to array or set
    } else if ([self.rawInputString rangeOfString:@"Put item " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Put item ";
        [self addToArrayOrSet];
        
    // case - remove from array or set
    } else if ([self.rawInputString rangeOfString:@"Remove " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Remove ";
        [self removeFromArrayOrSet];

    // case - get random object from array or set
    } else if ([self.rawInputString rangeOfString:@"Random item from collection " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSLog(@"Identified the lineStart Random item from collection ");
        self.lineStart = @"Random item from collection ";
        [self getRandomFromArrayOrSet];
        
    // case - log to console
    } else if ([self.rawInputString rangeOfString:@"Print " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Print ";
        [self logToConsole];
    
    // case - check if variable or collection was declared
    } else if ([self.rawInputString rangeOfString:@"Did I declare " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Did I declare ";
        [self declarationCheck];
        
    // case - delete warning
    } else if ([self.rawInputString rangeOfString:@"Delete warning" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Delete warning";
        [self deleteWarning];
        
    // case - create a fast enumeration loop
    } else if ([self.rawInputString rangeOfString:@"Create a fast enumeration loop. For " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a fast enumeration loop. For ";
        [self createFastEnumerationLoop];
    
    // case - undo last command
    } else if ([self.rawInputString rangeOfString:@"Undo" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Undo";
        [self undoLastCommand];
        
    // case - create a while loop
    } else if ([self.rawInputString rangeOfString:@"Create a while loop. While " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a while loop. While ";
        [self createConditionalStatement];
    
    // case - create a for loop
    } else if ([self.rawInputString rangeOfString:@"Create a for loop from start point " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create a for loop from start point ";
        [self createForLoop];
    
    // case - create an if statement
    } else if ([self.rawInputString rangeOfString:@"Create an if statement. If " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create an if statement. If ";
        [self createConditionalStatement];
    
    // case - create an else if statement
    } else if ([self.rawInputString rangeOfString:@"Create an else if statement. Else if " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create an else if statement. Else if ";
        [self createConditionalStatement];
    
    // case - create an else statement
    } else if ([self.rawInputString rangeOfString:@"Create an else statement" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Create an else statement";
        [self createElseStatement];
        
    // case - change prog mode
    } else if ([self.rawInputString rangeOfString:@"Change programming mode to " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Change programming mode to ";
        [self changeProgrammingMode];
        
    // case - reset variable value
    } else if ([self.rawInputString rangeOfString:@"Reset variable " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.lineStart = @"Reset variable ";
        [self resetVariableValue];
        
    // For else if and if statements,
    // move the cursor to after the last if bracket and insert new code there
    
    // Do some math operations for ints, floats, doubles, etc.
    // Add an NSNumber variable type
    
    // Next line -> does a newline \n
    // Previous line
    
    // Add a (void/bool/int/id/NSArray/etc.) method. Call it
    // Return functionality
    
    // default case
    } else {
        NSLog(@"No match of lineStart");
    }
}

// Ultimately move commands out to their own class file.
// Crashes if undo occurs while cursor is in the undo range. Move cursor before undo happens.
// It even crashes if not undoing the entire loop, just a command in the loop.

#pragma mark - code generation commands

- (void)addToArrayOrSet
{
    if ([self.rawInputString rangeOfString:@" into collection " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Get the object name to add
        self.varEqual = @" into collection ";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        
        // Find out which array or set to put it in
        if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.markBegin = self.markEnd;
            self.markEnd = self.lineEnd;
            self.secondVarName = [self findWildcardItemName];
            
            // Call a method to replace on-screen text with code
            if ([self.variablesArray containsObject:self.varName] && [self.collectionsArray containsObject:self.secondVarName]) {
                // Objective-C mode - test on 3/19
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"[%@ addObject:%@];\n\t", self.secondVarName, self.varName];
                    [self replaceLineWithTranslatedCodeString];
                // Swift mode - test on 3/19
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"%@.addObject(%@)", self.secondVarName, self.varName];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ or the variable %@ does not exist yet.\n\t", self.secondVarName, self.varName];
                [self replaceLineWithTranslatedCodeString];
            }
        } else {
            NSLog(@"No array or set name detected");
        }
    } else {
        NSLog(@"No variable name detected and method is %@", self.lineStart);
    }
}

- (void)createFastEnumerationLoop
{
    if ([self.rawInputString rangeOfString:@" in collection " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Get the item identifier for the loop
        self.varEqual = @" in collection ";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        
        // Get the collection name
        if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.markBegin = self.markEnd;
            self.markEnd = self.lineEnd;
            self.varName = [self findWildcardItemName];
            
            // Check for array existence and then replace on-screen text with code
            if ([self.collectionsArray containsObject:self.secondVarName]) {
                // not sure about adding this - don't think I need to, it's a generic identifier
                [self.variablesArray addObject:self.varName];
                self.translatedCodeString = [NSString stringWithFormat:@"for (id %@ in %@) {\n\t\t//placeholder\n\t}", self.varName, self.secondVarName];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The variable %@ or the collection %@ does not exist yet.\n\t", self.varName, self.secondVarName];
                [self replaceLineWithTranslatedCodeString];
            }
        } else {
            NSLog(@"Array or set not detected");
        }
    } else {
        NSLog(@"Item identifier not detected");
    }
}

- (void)createElseStatement
{
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.translatedCodeString = [NSString stringWithFormat:@"else {\n\t\t//placeholder\n\t}"];
        [self replaceLineWithTranslatedCodeString];
        [self deletePlaceholder];
    }
}

- (void)createForLoop
{
    // This method creates a for loop with certain bounds. For now, it uses a generic variable 'i'
    if ([self.rawInputString rangeOfString:@" to end point " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.varEqual = @" to end point ";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        
        if ([self.rawInputString rangeOfString:@", counting " options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.varEqual = @", counting ";
            self.markBegin = self.markEnd;
            self.markEnd = self.varEqual;
            self.secondVarName = [self findWildcardItemName];
            
            if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                self.markBegin = self.markEnd;
                self.markEnd = self.lineEnd;
                self.incrementDirection = [self findWildcardItemName];
                
                [self parseForLoopVariables];
                
                // This may create a small bug, keep it in mind and check it later
                // What if the last command was a warning that was not deleted?
                if ([self.translatedCodeString rangeOfString:@"// Warning: The collection "].location == NSNotFound) {
                    self.translatedCodeString = [NSString stringWithFormat:@"for (int i = %@; i %@; %@) {\n\t\t//placeholder\n\t}", self.varName, self.secondVarName, self.incrementDirection];
                } else {
                    NSLog(@"The collection referenced in the end point does not exist yet. Please create it before creating the loop.");
                }
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
                
            } else {
                NSLog(@"Increment direction not detected.");
            }
        } else {
            NSLog(@"End point not detected.");
        }
    } else {
        NSLog(@"Start point not detected.");
    }
}

- (void)createConditionalStatement
{
    // For now, varName should be a previously declared variable
    if ([self.rawInputString rangeOfString:@" variable is " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.varEqual = @" variable is ";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        
        // Find the condition operator
        [self findConditionOperator];
        
            // Find the condition limit
        if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                self.markBegin = self.conditionOperator;
                self.markEnd = self.lineEnd;
                [self findConditionLimit];

            } else {
                NSLog(@"Condition limit not detected.");
            }
        
    } else if ([self.rawInputString rangeOfString:@" exists. Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.varEqual = @" exists. Next.\n";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        if ([self.lineStart isEqualToString:@"Create an if statement. If "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"if (%@) {\n\t\t//placeholder\n\t}", self.varName];
            [self replaceLineWithTranslatedCodeString];
            [self deletePlaceholder];
        } else if ([self.lineStart isEqualToString:@"Create an else if statement. Else if "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"else if (%@) {\n\t\t//placeholder\n\t}", self.varName];
            [self replaceLineWithTranslatedCodeString];
            [self deletePlaceholder];
        } else if ([self.lineStart isEqualToString:@"Create a while loop. While "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"while (%@) {\n\t\t//placeholder\n\t}", self.varName];
            [self replaceLineWithTranslatedCodeString];
            [self deletePlaceholder];
        } else {
            // I don't think an else statement ever checks a condition. Leaving it out.
            NSLog(@"Else statements do not check a condition.");
        }
        
    } else if ([self.rawInputString rangeOfString:@" does not exist. Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.varEqual = @" does not exist. Next.\n";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        if ([self.lineStart isEqualToString:@"Create an if statement. If "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"if (!%@) {\n\t\t//placeholder\n\t}", self.varName];
            [self replaceLineWithTranslatedCodeString];
            [self deletePlaceholder];
        } else if ([self.lineStart isEqualToString:@"Create an else if statement. Else if "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"else if (!%@) {\n\t\t//placeholder\n\t}", self.varName];
            [self replaceLineWithTranslatedCodeString];
            [self deletePlaceholder];
        } else if ([self.lineStart isEqualToString:@"Create a while loop. While "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"while (!%@) {\n\t\t//placeholder\n\t}", self.varName];
            [self replaceLineWithTranslatedCodeString];
            [self deletePlaceholder];
        } else {
            // I don't think an else statement ever checks a condition. Leaving it out.
            NSLog(@"Else statements do not check a condition.");
        }
    
    } else {
        NSLog(@"If statement variable not detected");
    }
}


- (void)getRandomFromArrayOrSet
{
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSLog(@"Found Next command to begin transformation");
        self.markBegin = self.lineStart;
        self.markEnd = self.lineEnd;
        self.varName = [self findWildcardItemName];
        NSLog(@"self.varName is a collection called %@", self.varName);
        
        // Call a method to replace on-screen text with code
        if ([self.collectionsArray containsObject:self.varName]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSInteger index = arc4random() %% [%@ count];\n\tid randomObject = [%@ objectAtIndex:index];\n\t", self.varName, self.varName];
            NSLog(@"self.translatedCodeString is %@", self.translatedCodeString);
            self.translatedCodeString = [self.translatedCodeString stringByAppendingString:@"NSLog(@\"Random object selected is %@.\", randomObject);\n\t"];
            NSLog(@"self.translatedCodeString is %@", self.translatedCodeString);
            [self replaceLineWithTranslatedCodeString];
        } else {
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ does not exist yet.\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        }
    } else {
        NSLog(@"No array or set name detected");
    }
}

- (void)logToConsole
{
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Get the string to print
        self.markBegin = self.lineStart;
        self.markEnd = self.lineEnd;
        self.varName = [self findWildcardItemName];
        
        // Replace on-screen text with valid code
        self.translatedCodeString = [NSString stringWithFormat:@"NSLog(@\"%@\");\n\t", self.varName];
        [self replaceLineWithTranslatedCodeString];
    } else {
        NSLog(@"String to print not detected");
    }
}

- (void)removeFromArrayOrSet
{
    if ([self.rawInputString rangeOfString:@" from collection " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Get the object name to remove
        self.varEqual = @" from collection ";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        
        // Find out which array or set to remove it from
        if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.markBegin = self.markEnd;
            self.markEnd = self.lineEnd;
            self.secondVarName = [self findWildcardItemName];
            
            // Call a method to replace on-screen text with code
            if ([self.variablesArray containsObject:self.varName] && [self.collectionsArray containsObject:self.secondVarName]) {
                self.translatedCodeString = [NSString stringWithFormat:@"[%@ removeObject:%@];\n\t", self.secondVarName, self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ or the variable %@ does not exist yet.\n\t", self.secondVarName, self.varName];
                [self replaceLineWithTranslatedCodeString];
            }
        } else {
            NSLog(@"No array or set name detected");
        }
    } else {
        NSLog(@"No variable name detected and method is %@", self.lineStart);
    }
}

- (void)resetVariableValue
// Find a way to do type checking here on the variables - maybe store the variables WITH their type in variablesArray
// and then check on that
{
    if ([self.rawInputString rangeOfString:@" to new value " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Get the variable name to check
        self.markBegin = self.lineStart;
        self.markEnd = @" to new value ";
        self.varName = [self findWildcardItemName];
            
        // Get the new value for the variable
        if ([self.rawInputString rangeOfString:self.lineEnd options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
            // Get the new value
            self.markBegin = @" to new value ";
            self.markEnd = self.lineEnd;
            self.secondVarName = [self findWildcardItemName];
            
            // Check if that variable exists already
            if ([self.variablesArray containsObject:self.varName]) {
            
                // If the variable exists, call a method to replace on-screen text with code
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"%@ = %@;\n\t", self.varName, self.secondVarName];
                    [self replaceLineWithTranslatedCodeString];
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"%@ = %@\n\t", self.varName, self.secondVarName];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }
            
            // If it does not exist already, put a warning on-screen instead
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The variable %@ does not exist yet.\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            }
                
        } else {
            NSLog(@"New value of variable not found");
        }
        
    } else {
        NSLog(@"No new value detected for a variable");
    }
}

- (void)setArrayOrSetName
// This only creates empty collections; need a way to initialize collections with objects
// Also consider adding dictionaries here or in a separate command
{
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        // Find and set the array or set name
        self.markBegin = self.lineStart;
        self.markEnd = self.lineEnd;
        self.varName = [self findWildcardItemName];
        
        // Add the collection name to the collections array
        [self.collectionsArray addObject:self.varName];
        
        // Call a method to replace on-screen text with code
        if ([self.lineStart isEqualToString:@"Create an array. Call it "]) {
            if (self.progMode == 0) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSArray *%@ = [[NSArray alloc] init];\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else if (self.progMode == 1) {
                self.translatedCodeString = [NSString stringWithFormat:@"var %@ = []\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                NSLog(@"Check the progMode");
            }
            
        } else if ([self.lineStart isEqualToString:@"Create a mutable array. Call it "]) {
            if (self.progMode == 0) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSMutableArray *%@ = [[NSMutableArray alloc] init];\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else if (self.progMode == 1) {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: Swift does not support mutable arrays. Try an immutable array and then use arrayName.append() or arrayName += []\n\t"];
                [self replaceLineWithTranslatedCodeString];
            } else {
                NSLog(@"Check the progMode");
            }
            
        } else if ([self.lineStart isEqualToString:@"Create a set. Call it "]) {
            if (self.progMode == 0) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSSet *%@ = [[NSSet alloc] init];\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else if (self.progMode == 1) {
                // Consider adding a line of guidance that tells them to specify the set type between carets - or change the input to accept a type if in Swift mode
                self.translatedCodeString = [NSString stringWithFormat:@"var %@ = Set<insertTypeHere>()\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                NSLog(@"Check the progMode");
            }
            
        } else if ([self.lineStart isEqualToString:@"Create a mutable set. Call it "]) {
            if (self.progMode == 0) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSMutableSet *%@ = [[NSMutableSet alloc] init];\n\t", self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else if (self.progMode == 1) {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: Swift does not support mutable sets. Try an immutable set with the syntax \"var setName = Set<type>()\" and then use setName.insert()\n\t"];
                [self replaceLineWithTranslatedCodeString];
            } else {
                NSLog(@"Check the progMode");
            }
        }
        
    } else {
        NSLog(@"Array or set name not detected");
    }
}

- (void)setVariableNameAndValue
// You can't initialize empty variables yet, they must be declared with a value
{
    if ([self.rawInputString rangeOfString:@". Equal to " options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Find and set the variable name
        self.varEqual = @". Equal to ";
        self.markBegin = self.lineStart;
        self.markEnd = self.varEqual;
        self.varName = [self findWildcardItemName];
        
        // If the variable has a value, find and set it
        if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // Find a way to allow variables without initial values. If "Call it" is
            // followed by ". Next.\n" this should be a separate case.
            self.markBegin = self.markEnd;
            self.markEnd = self.lineEnd;
            self.secondVarName = [self findWildcardItemName];
            
            // Add the valid variable to the variables array
            [self.variablesArray addObject:self.varName];
            
            // Call a method to replace on-screen text with code
            if ([self.lineStart isEqualToString:@"Create an integer variable. Call it "]) {
                int variableValue = [self.secondVarName intValue];
                NSLog(@"Starting progMode analysis...");
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"int %@ = %d;\n\t", self.varName, variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"var %@ = %d\n\t", self.varName, variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }

            } else if ([self.lineStart isEqualToString:@"Create a float variable. Call it "]) {
                float variableValue = [self.secondVarName floatValue];
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"float %@ = %f;\n\t", self.varName, variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"var %@ = %f\n\t", self.varName, variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }
                
            } else if ([self.lineStart isEqualToString:@"Create a double variable. Call it "]) {
                double variableValue = [self.secondVarName doubleValue];
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"double %@ = %f;\n\t", self.varName, variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"var %@ = %f\n\t", self.varName, variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }
                
                
            } else if ([self.lineStart isEqualToString:@"Create a string variable. Call it "]) {
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"NSString *%@ = @\"%@\";\n\t", self.varName, self.secondVarName];
                    [self replaceLineWithTranslatedCodeString];
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"var %@ = \"%@\"\n\t", self.varName, self.secondVarName];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }
                
            } else if ([self.lineStart isEqualToString:@"Create an unsigned integer variable. Call it "]) {
                NSUInteger variableValue = [self.secondVarName intValue];
                if (self.progMode == 0) {
                    self.translatedCodeString = [NSString stringWithFormat:@"NSUInteger %@ = %lu;\n\t", self.varName, (unsigned long)variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else if (self.progMode == 1) {
                    self.translatedCodeString = [NSString stringWithFormat:@"var %@: UInt = %lu\n\t", self.varName, (unsigned long)variableValue];
                    [self replaceLineWithTranslatedCodeString];
                } else {
                    NSLog(@"Check the progMode");
                }
                
            } else {
                NSLog(@"Could not translate variable name into value of correct type");
            }
        } else {
            NSLog(@"Variable value not detected");
        }
    } else {
        NSLog(@"Variable not detected");
    }
}

#pragma mark - workflow methods

- (void)declarationCheck
{
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        NSLog(@"Variable or collection to check not identified");
    } else {
        // Get the variable or array name to check
        self.markBegin = self.lineStart;
        self.markEnd = self.lineEnd;
        self.varName = [self findWildcardItemName];
        
        // Look for a matching variable or array name
        if ([self.collectionsArray containsObject:self.varName] || [self.variablesArray containsObject:self.varName]) {
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: Not necessary. %@ exists.\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        } else {
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: %@ does not exist yet.\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        }
    }
}

- (void)deleteWarning
{
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.markBegin = @"// Warning: ";
        // do some string concatenation here? " warning" + self.lineEnd?
        self.markEnd = self.lineEnd;
        // self.markEnd = @" warning. Next.\n";
        [self findReplacementRange];

        // Delete the warning and the following "Delete warning" command.
        // The method replaceLineWithTranslatedCodeString ensures the warning string
        // is not added to the translated code array - but this may crash Undo if the warning
        // is NOT deleted by the user. Make Undo check for Warning and include it in the
        // delete if it encounters it. Also, Delete Warning always succeeds even inside
        // the for loop. Why does it work and Undo crashes?
        self.translatedCodeString = @"";
        [self.textView insertText:self.translatedCodeString replacementRange:self.replacementRange];
        
        // Reset to the new "last valid command" in case undo is used later.
        self.translatedCodeString = [self.translatedCodeArray lastObject];
    } else {
        NSLog(@"Warning deletion not confirmed");
    }
}

- (void)undoLastCommand
{
    // Undo is buggy if the user has deleted text with the mouse and then re-inserted it
    // Also within a for loop if any "Undo" commands are issued. Undo needs to be much more
    // robust.
    // Fixed in app - import fix to here
    if ([self.rawInputString rangeOfString:@". Next.\n" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Find the replacement range.
        self.markBegin = self.translatedCodeString;
        self.markEnd = self.lineEnd;
        // self.markEnd = @"Undo. Next.\n";
        [self findReplacementRange];
        // I think this line is a problem, what if there is not a match, like if
        // placeholder is in the translatedCodeArray? Check if deletePlaceholder updates
        // the translatedCodeArray. Also what if there is a warning left on the screen,
        // how does it deal with this?
        [self.translatedCodeArray removeObject:[self.translatedCodeArray lastObject]];
        
        // Delete the target command and the following "Undo" command.
        self.translatedCodeString = @"";
        [self.textView insertText:self.translatedCodeString replacementRange:self.replacementRange];
        
        // Reset to the new "last valid command" in case undo is used multiple times in a row.
        self.translatedCodeString = [self.translatedCodeArray lastObject];
    } else {
        NSLog(@"Undo not confirmed");
    }
}

- (void)changeProgrammingMode
{
    if ([self.rawInputString rangeOfString:self.lineEnd options:NSCaseInsensitiveSearch].location != NSNotFound) {
        // Find the name of the language to use (varName)
        self.markBegin = self.lineStart;
        self.markEnd = self.lineEnd;
        self.varName = [self findWildcardItemName];
        if ([self.varName rangeOfString:@"Objective-C" options:NSCaseInsensitiveSearch].location != NSNotFound && self.progMode != 0) {
            self.progMode = 0;
            self.translatedCodeString = [NSString stringWithFormat:@"// Changed programming mode to Objective-C.\n\t"];
            [self replaceLineWithTranslatedCodeString];
            NSLog(@"Changed programming mode to Objective-C");
            // Add functionality here to reset the previousInputArray
        } else if ([self.varName rangeOfString:@"Swift" options:NSCaseInsensitiveSearch].location != NSNotFound && self.progMode != 1) {
            self.progMode = 1;
            self.translatedCodeString = [NSString stringWithFormat:@"// Changed programming mode to Swift.\n\t"];
            [self replaceLineWithTranslatedCodeString];
            NSLog(@"Changed programming mode to Swift");
            // Add functionality here to reset the previousInputArray
        } else if ([self.varName rangeOfString:@"Objective-C" options:NSCaseInsensitiveSearch].location != NSNotFound && self.progMode == 0) {
            // Post a warning that the user is already using Objective-C
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: You are already using Objective-C.\n\t"];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.varName rangeOfString:@"Swift" options:NSCaseInsensitiveSearch].location != NSNotFound && self.progMode == 1) {
            // Post a warning that the user is already using Swift
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: You are already using Swift.\n\t"];
            [self replaceLineWithTranslatedCodeString];
        } else {
            // Post a warning that the plugin does not support that language yet.
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: That language is not an option yet."];
            [self replaceLineWithTranslatedCodeString];
        }
    }
}

#pragma mark - internal methods

- (void)deletePlaceholder
{
    // This is extremely hacky and will be replaced at some point. But it works for now.
    // Except now it crashes the undo function, because it is hacky. This needs to be fixed.
    // Fixed in app - import fix to here - may need to separate closed-bracket from first line of
    // conditionals since plugin is inline. Check
    if ([self.rawInputString rangeOfString:@"//placeholder"].location != NSNotFound) {
        self.markBegin =@"//place";
        self.markEnd = @"holder";
        [self findReplacementRange];
        self.translatedCodeString = @"";
        [self.textView setSelectedRange:self.replacementRange];
        [self.textView insertText:self.translatedCodeString replacementRange:self.replacementRange];
        
        // Reset to the last valid command in case undo is used.
        self.translatedCodeString = [self.translatedCodeArray lastObject];
    } else {
        NSLog(@"Placeholder not found.");
    }
}

- (void)findConditionLimit
{
    self.secondVarName = [self findWildcardItemName];
    
    if ([self.variablesArray containsObject:self.varName]) {
        if ([self.secondVarName rangeOfString:@"integer " options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.varEqual = @"integer ";
            self.markBegin = self.varEqual;
            self.markEnd = self.lineEnd;
            self.conditionLimit = [self findWildcardItemName];
            int variableValue = [self.conditionLimit intValue];
            // Can this kind of stuff be abstracted away somewhere? Maybe set while /
            // if / else if as options and then insert them with a flag with one
            // statement to set the translatedCodeString
            if ([self.lineStart isEqualToString:@"Create a while loop. While "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ %@ %d) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (%@ %@ %d) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (%@ %@ %d) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            }
            
        } else if ([self.secondVarName rangeOfString:@"float " options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.varEqual = @"float ";
            self.markBegin = self.varEqual;
            self.markEnd = self.lineEnd;
            self.conditionLimit = [self findWildcardItemName];
            float variableValue = [self.conditionLimit floatValue];
            if ([self.lineStart isEqualToString:@"Create a while loop. While "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ %@ %f) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (%@ %@ %f) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (%@ %@ %f) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            }
            
        } else if ([self.secondVarName rangeOfString:@"double " options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.varEqual = @"double ";
            self.markBegin = self.varEqual;
            self.markEnd = self.lineEnd;
            self.conditionLimit = [self findWildcardItemName];
            double variableValue = [self.conditionLimit doubleValue];
            if ([self.lineStart isEqualToString:@"Create a while loop. While "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ %@ %f) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (%@ %@ %f) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (%@ %@ %f) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator, variableValue];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            }
            
        } else if ([self.secondVarName rangeOfString:@"string " options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.varEqual = @"string ";
            self.markBegin = self.varEqual;
            self.markEnd = self.lineEnd;
            self.conditionLimit = [self findWildcardItemName];
            // I think this is not right, the self.conditionOperator is == or != so check this
            // should it be conditionLimit in the check instead?
            if ([self.lineStart isEqualToString:@"Create a while loop. While "] && [self.conditionOperator isEqualToString:@"equal to"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ isEqualToString:%@) {\n\t\t//placeholder\n\t}", self.varName, self.conditionLimit];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create a while loop. While "] && [self.conditionOperator isEqualToString:@"not equal to"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ isEqualToString:%@) {\n\t\t//placeholder\n\t}", self.varName, self.conditionLimit];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "] && [self.conditionOperator isEqualToString:@"equal to"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (%@ isEqualToString:%@) {\n\t\t//placeholder\n\t}", self.varName, self.conditionLimit];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "] && [self.conditionOperator isEqualToString:@"not equal to"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (!(%@ isEqualToString:%@) {\n\t\t//placeholder\n\t}", self.varName, self.conditionLimit];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an else if statement. Else if "] && [self.conditionOperator isEqualToString:@"equal to"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (%@ isEqualToString:%@) {\n\t\t//placeholder\n\t}", self.varName, self.conditionLimit];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an else if statement. Else if "] && [self.conditionOperator isEqualToString:@"not equal to"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (!(%@ isEqualToString:%@) {\n\t\t//placeholder\n\t}", self.varName, self.conditionLimit];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else {
                NSLog(@"Strings need 'equal to' or 'not equal to' conditionals in this program");
            }
            
        } else if ([self.secondVarName rangeOfString:@"bool " options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.varEqual = @"bool ";
            self.markBegin = self.varEqual;
            self.markEnd = self.lineEnd;
            self.conditionLimit = [self findWildcardItemName];
            if ([self.lineStart isEqualToString:@"Create a while loop. While "] && [self.conditionLimit isEqualToString:@"yes"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ %@ YES) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create a while loop. While "] && [self.conditionLimit isEqualToString:@"no"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"while (%@ %@ NO) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "] && [self.conditionLimit isEqualToString:@"yes"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (%@ %@ YES) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an if statement. If "] && [self.conditionLimit isEqualToString:@"no"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"if (%@ %@ NO) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator];
            } else if ([self.lineStart isEqualToString:@"Create an else if statement. Else if "] && [self.conditionLimit isEqualToString:@"yes"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (%@ %@ YES) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else if ([self.lineStart isEqualToString:@"Create an else if statement. Else if "] && [self.conditionLimit isEqualToString:@"no"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"else if (%@ %@ NO) {\n\t\t//placeholder\n\t}", self.varName, self.conditionOperator];
                [self replaceLineWithTranslatedCodeString];
                [self deletePlaceholder];
            } else {
                NSLog(@"Could not distinguish 'yes' or 'no'");
            }        // self.varName = self.wildcardItemName;

        } else {
            NSLog(@"Loop condition limit not identified.");
        }
        
    } else {
        self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The variable %@ does not exist yet. For now, please declare it first with an initial value.\n\t", self.varName];
        [self replaceLineWithTranslatedCodeString];
    }
}

- (void)findConditionOperator
{
    // This method finds the operator within a loop or if-else conditional
    if ([self.rawInputString rangeOfString:@"not equal to" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.conditionOperator = @"!=";
    } else if ([self.rawInputString rangeOfString:@"less than or equal to" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.conditionOperator = @"<=";
    } else if ([self.rawInputString rangeOfString:@"greater than or equal to" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.conditionOperator = @">=";
    } else if ([self.rawInputString rangeOfString:@"equal to" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.conditionOperator = @"==";
    } else if ([self.rawInputString rangeOfString:@"less than" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.conditionOperator = @"<";
    } else if ([self.rawInputString rangeOfString:@"greater than" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.conditionOperator = @">";
    } else {
        NSLog(@"Condition operator not detected");
    }
}

- (void)findReplacementRange
{
    // This method returns a general replacement range that can be used in other methods
    NSRange replacementStartRange = [self.rawInputString rangeOfString:self.markBegin options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    NSRange replacementEndRange = [self.rawInputString rangeOfString:self.markEnd options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    NSUInteger replacementLength = (replacementEndRange.location + self.markEnd.length) - (replacementStartRange.location);
    self.replacementRange = NSMakeRange(replacementStartRange.location, replacementLength);
}

- (NSString *)findWildcardItemName
{
    // This method returns a general wildcard that can be assigned to any local or global
    // variable name
    NSRange varStartRange = [self.rawInputString rangeOfString:self.markBegin options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    NSRange varEndRange = [self.rawInputString rangeOfString:self.markEnd options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    NSUInteger varLength = (varEndRange.location) - (varStartRange.location + self.markBegin.length);
    self.wildcardItemName = [self.rawInputString substringWithRange:NSMakeRange((varStartRange.location + self.markBegin.length), varLength)];
    return self.wildcardItemName;
}

- (void)parseForLoopVariables
{
    // Based on the increment direction (up or down), transform the end point variable
    // into a condition operator plus the appropriate variable. This method allows use of
    // [array count] as an end point, if the array has been declared.
    // Consider checking strings not with isEqualToString (case sensitive) but with
    // if ([self.incrementDirection caseInsensitiveCompare:@"String"]==NSOrderedSame)
    if ([self.incrementDirection isEqualToString:@"up"]) {
        if ([self.secondVarName rangeOfString:@" count" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.secondVarName = [self.secondVarName substringToIndex:[self.secondVarName length] - 6];
            if ([self.collectionsArray containsObject:self.secondVarName]) {
                self.secondVarName = [NSString stringWithFormat:@"< [%@ count]", self.secondVarName];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ does not exist yet.\n\t", self.secondVarName];
                NSLog(@"translatedCodeString is %@", self.translatedCodeString);
            }
        } else if ([self.secondVarName rangeOfString:@", inclusive" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.secondVarName = [self.secondVarName substringToIndex:[self.secondVarName length] - 11];
            self.secondVarName = [NSString stringWithFormat:@"<= %@", self.secondVarName];
        } else {
            self.secondVarName = [NSString stringWithFormat:@"< %@", self.secondVarName];
        }
    } else if ([self.incrementDirection isEqualToString:@"down"]) {
        if ([self.secondVarName rangeOfString:@" count" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.secondVarName = [self.secondVarName substringToIndex:[self.secondVarName length] - 6];
            if ([self.collectionsArray containsObject:self.secondVarName]) {
                self.secondVarName = [NSString stringWithFormat:@"> [%@ count]", self.secondVarName];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ does not exist yet.\n\t", self.secondVarName];
                NSLog(@"translatedCodeString is %@", self.translatedCodeString);
            }
        } else if ([self.secondVarName rangeOfString:@", inclusive" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            self.secondVarName = [self.secondVarName substringToIndex:[self.secondVarName length] - 11];
            self.secondVarName = [NSString stringWithFormat:@">= %@", self.secondVarName];
        } else {
            self.secondVarName = [NSString stringWithFormat:@"> %@", self.secondVarName];
        }
    } else {
        NSLog(@"Could not parse the increment direction.");
    }
    
    // Now transform the increment direction into valid code
    if ([self.incrementDirection isEqualToString:@"up"]) {
        self.incrementDirection = @"i++";
    } else if ([self.incrementDirection isEqualToString:@"down"]) {
        self.incrementDirection = @"i--";
    } else {
        NSLog(@"Could not parse the increment direction.");
    }
}

- (void)replaceLineWithTranslatedCodeString
{
    // First we get the user's original input as a range in textStorage, so we can replace it with code.
    NSLog(@"self.lineStart in replacement method is %@", self.lineStart);
    NSRange lineRangeStart = [self.rawInputString rangeOfString:self.lineStart options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    NSLog(@"self.lineEnd in replacement method is %@", self.lineEnd);
    NSRange lineRangeEnd = [self.rawInputString rangeOfString:self.lineEnd options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    NSUInteger lineRangeLength = (lineRangeEnd.location+7) - (lineRangeStart.location);
    NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
    
    // We store the user's original input in an array in case we need it.
    // I'm not sure how useful this really is, do we need it or just the translatedCodeArray
    // which should be sufficient
    // It turns out this IS useful for replays, do not get rid of it
    self.previousInput = [self.rawInputString substringWithRange:replacementRange];
    [self.previousInputArray addObject:self.previousInput];
    NSLog(@"self.previousInput is now %@", self.previousInput);
    // Then we replace the text on-screen with valid code and add the code to an array
    // of commands issued so far.
    [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
    if ([self.translatedCodeString rangeOfString:@"// Warning: "].location == NSNotFound) {
        [self.translatedCodeArray addObject:self.translatedCodeString];
    }
}

#pragma mark - closedown methods

- (void)didClickStopSpeakIt:(id)sender
{
    self.rawInputString = nil;
    self.previousInput = nil;
    self.previousInputArray = nil;
    self.translatedCodeString = nil;
    self.lineStart = nil;
    self.lineEnd = nil;
    self.varEqual = nil;
    // Consider storing array contents in NSUserDefaults here
    [self.onOffSwitch setTitle:@"Start SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickBeginSpeakIt:)];
    NSLog(@"Stopped SpeakIt");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
