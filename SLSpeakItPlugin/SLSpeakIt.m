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
    if ([self.rawInputString rangeOfString:@"Create an integer variable. Call it "].location != NSNotFound) {
        self.lineStart = @"Create an integer variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create a float variable
    } else if ([self.rawInputString rangeOfString:@"Create a float variable. Call it "].location != NSNotFound) {
        self.lineStart = @"Create a float variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create a double variable
    } else if ([self.rawInputString rangeOfString:@"Create a double variable. Call it "].location != NSNotFound) {
        self.lineStart = @"Create a double variable. Call it ";
        [self setVariableNameAndValue];
        
    // case - create a string variable
    } else if ([self.rawInputString rangeOfString:@"Create a string variable. Call it "].location != NSNotFound) {
        self.lineStart = @"Create a string variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create an unsigned integer NSUInteger variable
    } else if ([self.rawInputString rangeOfString:@"Create an unsigned integer variable. Call it "].location != NSNotFound) {
        self.lineStart = @"Create an unsigned integer variable. Call it ";
        [self setVariableNameAndValue];
    
    // case - create an array
    } else if ([self.rawInputString rangeOfString:@"Create an array. Call it "].location != NSNotFound) {
        self.lineStart = @"Create an array. Call it ";
        [self setArrayOrSetName];
        
    // case - create a mutable array
    } else if ([self.rawInputString rangeOfString:@"Create a mutable array. Call it "].location != NSNotFound) {
        self.lineStart = @"Create a mutable array. Call it ";
        [self setArrayOrSetName];
        
    // case - create a set
    } else if ([self.rawInputString rangeOfString:@"Create a set. Call it "].location != NSNotFound) {
        self.lineStart = @"Create a set. Call it ";
        [self setArrayOrSetName];
    
    // case - create a mutable set
    } else if ([self.rawInputString rangeOfString:@"Create a mutable set. Call it "].location != NSNotFound) {
        self.lineStart = @"Create a mutable set. Call it ";
        [self setArrayOrSetName];
        
    // case - add to array or set
    } else if ([self.rawInputString rangeOfString:@"Put "].location != NSNotFound) {
        self.lineStart = @"Put ";
        [self addToArrayOrSet];
        
    // case - remove from array or set
    } else if ([self.rawInputString rangeOfString:@"Remove "].location != NSNotFound) {
        self.lineStart = @"Remove ";
        [self removeFromArrayOrSet];

    // case - get random object from array or set
    } else if ([self.rawInputString rangeOfString:@"Random item from collection "].location != NSNotFound) {
        self.lineStart = @"Random item from collection ";
        [self getRandomFromArrayOrSet];
        
    // case - log to console
    } else if ([self.rawInputString rangeOfString:@"Print "].location != NSNotFound) {
        self.lineStart = @"Print ";
        [self logToConsole];
    
    // case - check if variable or collection was declared
    } else if ([self.rawInputString rangeOfString:@"Did I declare "].location != NSNotFound) {
        self.lineStart = @"Did I declare ";
        [self declarationCheck];
        
    // case - delete warning
    } else if ([self.rawInputString rangeOfString:@"Delete warning"].location != NSNotFound) {
        self.lineStart = @"Delete warning";
        [self deleteWarning];
        
    // case - create a fast enumeration loop
    } else if ([self.rawInputString rangeOfString:@"Create a fast enumeration loop. For "].location != NSNotFound) {
        self.lineStart = @"Create a fast enumeration loop. For ";
        [self createFastEnumerationLoop];
    
    // case - undo last command
    } else if ([self.rawInputString rangeOfString:@"Undo"].location != NSNotFound) {
        self.lineStart = @"Undo";
        [self undoLastCommand];
        
//    // case - create a loop
//    } else if ([self.rawInputString rangeOfString:@"Create a loop"].location != NSNotFound) {
//        self.lineStart = @"Create a loop";
//        [self setLoopConditions];
        
//    // case - create an if statement
//    } else if ([self.rawInputString rangeOfString:@"Create an if statement"].location != NSNotFound) {
//        self.lineStart = @"Create an if statement";
//        [self createIfStatement];
//        
    // Do some math operations for ints, floats, doubles, etc.
    // Add an NSNumber variable type
    
    // Create an if statement. Condition: x < 5 etc.
    // Else if at close-bracket (if so, then get condition: etc.
    // Else at close-bracket (if so, then end and replace with code
    
    // Create a while loop. Condition: etc.
    // More difficult than originally anticipated.
    // But ready to consider it now that findReplacementRange and findWildcard are
    // modularized.
    
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
    if ([self.rawInputString rangeOfString:@" into collection "].location != NSNotFound) {
        // Get the object name to add
        self.markBegin = self.lineStart;
        self.markEnd = @" into collection ";
        [self findWildcardItemName];
        
        // Find out which array or set to put it in
        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
            self.markBegin = self.markEnd;
            self.markEnd = @". Next.\n";
            [self findSecondWildcardItemName];
            
            // Call a method to replace on-screen text with code
            if ([self.variablesArray containsObject:self.varName] && [self.collectionsArray containsObject:self.secondVarName]) {
                self.translatedCodeString = [NSString stringWithFormat:@"[%@ addObject:%@];\n\t", self.secondVarName, self.varName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ or the variable %@ does not exist yet.\n\t", self.secondVarName, self.varName];
                [self replaceLineWithTranslatedCodeString];
            }
        } else {
            NSLog(@"No array or set name detected");
        }
    } else {
        NSLog(@"No variable name detected");
    }
}

- (void)createFastEnumerationLoop
{
    if ([self.rawInputString rangeOfString:@" in collection "].location != NSNotFound) {
        // Get the item identifier for the loop
        self.markBegin = self.lineStart;
        self.markEnd = @" in collection ";
        [self findWildcardItemName];
        
        // Get the collection name
        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
            self.markBegin = self.markEnd;
            self.markEnd = @". Next.\n";
            [self findSecondWildcardItemName];
            
            // Check for array existence and then replace on-screen text with code
            if ([self.collectionsArray containsObject:self.secondVarName]) {
                [self.variablesArray addObject:self.varName];
                self.translatedCodeString = [NSString stringWithFormat:@"for (id %@ in %@) {\n\t\t//placeholder\n\t}", self.varName, self.secondVarName];
                [self replaceLineWithTranslatedCodeString];
                // This is extremely hacky and will be replaced at some point, but it works for
                // right now, except when undo is used. This needs to be fixed.
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

- (void)getRandomFromArrayOrSet
{
    if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
        self.markBegin = self.lineStart;
        self.markEnd = @". Next.\n";
        [self findWildcardItemName];
        
        // Call a method to replace on-screen text with code
        if ([self.collectionsArray containsObject:self.varName]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSInteger index = arc4random() %% [%@ count];\n\tid randomObject = [%@ objectAtIndex:index];\n\t", self.varName, self.varName];
            self.translatedCodeString = [self.translatedCodeString stringByAppendingString:@"NSLog(@\"Random object selected is %@.\", randomObject);\n\t"];
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
    if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
        // Get the string to print
        self.markBegin = self.lineStart;
        self.markEnd = @". Next.\n";
        [self findWildcardItemName];
        
        // Replace on-screen text with valid code
        self.translatedCodeString = [NSString stringWithFormat:@"NSLog(@\"%@\");\n\t", self.varName];
        [self replaceLineWithTranslatedCodeString];
    } else {
        NSLog(@"String to print not detected");
    }
}

- (void)removeFromArrayOrSet
{
    if ([self.rawInputString rangeOfString:@" from collection "].location != NSNotFound) {
        // Get the object name to remove
        self.markBegin = self.lineStart;
        self.markEnd = @" from collection ";
        [self findWildcardItemName];
        
        // Find out which array or set to remove it from
        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
            self.markBegin = self.markEnd;
            self.markEnd = @". Next.\n";
            [self findSecondWildcardItemName];
            
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
        NSLog(@"No variable name detected");
    }
}

- (void)resetVariableValue
{
    
}

- (void)setArrayOrSetName
{
    if ([self.rawInputString rangeOfString:@". Next."].location != NSNotFound) {
        
        // Find and set the array or set name
        self.markBegin = self.lineStart;
        self.markEnd = @". Next.\n";
        [self findWildcardItemName];
        
        // Add the collection name to the collections array
        [self.collectionsArray addObject:self.varName];
        
        // Call a method to replace on-screen text with code
        if ([self.lineStart isEqualToString:@"Create an array. Call it "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSArray *%@ = [[NSArray alloc] init];\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a mutable array. Call it "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSMutableArray *%@ = [[NSMutableArray alloc] init];\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a set. Call it "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSSet *%@ = [[NSSet alloc] init];\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a mutable set. Call it "]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSMutableSet *%@ = [[NSMutableSet alloc] init];\n\t", self.varName];
            [self replaceLineWithTranslatedCodeString];
        }
        
    } else {
        NSLog(@"Array name not detected");
    }
}

- (void)setVariableNameAndValue
{
    if ([self.rawInputString rangeOfString:@". Equal to "].location != NSNotFound) {
        // Find and set the variable name
        self.markBegin = self.lineStart;
        self.markEnd = @". Equal to ";
        [self findWildcardItemName];
        
        // If the variable has a value, find and set it
        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
            // Find a way to allow variables without initial values. If "Call it" is
            // followed by ". Next.\n" this should be a separate case.
            self.markBegin = self.markEnd;
            self.markEnd = @". Next.\n";
            [self findSecondWildcardItemName];
            [self.variablesArray addObject:self.varName];
            
            // Call a method to replace on-screen text with code
            if ([self.lineStart isEqualToString:@"Create an integer variable. Call it "]) {
                int variableValue = [self.secondVarName intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"int %@ = %d;\n\t", self.varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a float variable. Call it "]) {
                float variableValue = [self.secondVarName floatValue];
                self.translatedCodeString = [NSString stringWithFormat:@"float %@ = %f;\n\t", self.varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a double variable. Call it "]) {
                double variableValue = [self.secondVarName doubleValue];
                self.translatedCodeString = [NSString stringWithFormat:@"double %@ = %f;\n\t", self.varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a string variable. Call it "]) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSString *%@ = @\"%@\";\n\t", self.varName, self.secondVarName];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create an unsigned integer variable. Call it "]) {
                NSUInteger variableValue = [self.secondVarName intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"NSUInteger %@ = %lu;\n\t", self.varName, (unsigned long)variableValue];
                [self replaceLineWithTranslatedCodeString];
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

//- (void)setLoopConditions
//{
//    if ([self.rawInputString rangeOfString:@". Condition "].location != NSNotFound) {
//        // Get the variable to operate on
//        NSRange varStartRange = [self.rawInputString rangeOfString:@". Condition " options:NSBackwardsSearch];
//        NSRange varEndRange;
//        if ([self.rawInputString rangeOfString:@" equal to "].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@" equal to " options:NSBackwardsSearch];
//        } else if ([self.rawInputString rangeOfString:@" less than "].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@" less than " options:NSBackwardsSearch];
//        } else if ([self.rawInputString rangeOfString:@" greater than "].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@" greater than " options:NSBackwardsSearch];
//        } else if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//        } else {
//            NSLog(@"Did not detect variable name");
//        }
//        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+12);
//        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+12, varLength)];
//        NSLog(@"varName is %@", varName);
//        
//        // Get the value that the variable is compared to
//        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
//            NSRange valStartRange;
//            NSRange valEndRange;
//            NSUInteger valLength;
//            NSString *value = nil;
//            // add "not equal to" here as another if case
//            if ([self.rawInputString rangeOfString:@" equal to "].location != NSNotFound) {
//                valStartRange = [self.rawInputString rangeOfString:@" equal to " options:NSBackwardsSearch];
//                valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//                valLength = (valEndRange.location) - (valStartRange.location+10);
//                value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+10, valLength)];
//                if ([self.rawInputString rangeOfString:@"integer"].location != NSNotFound) {
//                    int variableValue = [value intValue];
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %d) {\n", varName, variableValue];
//                    [self replaceLineWithTranslatedCodeString];
//                } else if ([self.rawInputString rangeOfString:@"float"].location != NSNotFound) {
//                    float variableValue = [value floatValue];
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %f) {\n", varName, variableValue];
//                    [self replaceLineWithTranslatedCodeString];
//                } else if ([self.rawInputString rangeOfString:@"double"].location != NSNotFound) {
//                    double variableValue = [value doubleValue];
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %f) {\n", varName, variableValue];
//                    [self replaceLineWithTranslatedCodeString];
//                } else if (([self.rawInputString rangeOfString:@"YES"].location != NSNotFound) || ([self.rawInputString rangeOfString:@"NO"].location != NSNotFound)) {
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %@) {\n", varName, value];
//                    [self replaceLineWithTranslatedCodeString];
//                } else {
//                    NSLog(@"Could not replace text with code");
//                }
//            } else if ([self.rawInputString rangeOfString:@" less than "].location != NSNotFound) {
//                valStartRange = [self.rawInputString rangeOfString:@" less than " options:NSBackwardsSearch];
//                valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//                valLength = (valEndRange.location) - (valStartRange.location+11);
//                value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+11, valLength)];
//            } else if ([self.rawInputString rangeOfString:@" greater than "].location != NSNotFound) {
//                valStartRange = [self.rawInputString rangeOfString:@" greater than " options:NSBackwardsSearch];
//                valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//                valLength = (valEndRange.location) - (valStartRange.location+14);
//                value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+14, valLength)];
//            } else {
//                NSLog(@"Could not set valStartRange");
//            }
//        }
//    }
//}

//- (void)createIfStatement
//{
//    // Get the condition
//    if ([self.rawInputString rangeOfString:@"Condition "].location != NSNotFound) {
//        NSRange conditionStartRange = [self.rawInputString rangeOfString:@"Condition " options:NSBackwardsSearch];
//        NSRange conditionEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//        NSUInteger conditionLength = (conditionEndRange.location) - (conditionStartRange.location+10);
//        NSString *condition
//    }
//}


#pragma mark - workflow methods

- (void)declarationCheck
{
    if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
        NSLog(@"Variable or collection to check not identified");
    } else {
        // Get the variable or array name to check
        self.markBegin = self.lineStart;
        self.markEnd = @". Next.\n";
        [self findWildcardItemName];
        
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
    if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
        self.markBegin = @"// Warning: ";
        self.markEnd = @" warning. Next.\n";
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
    if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
        // Find the replacement range.
        self.markBegin = self.translatedCodeString;
        self.markEnd = @"Undo. Next.\n";
        [self findReplacementRange];
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

#pragma mark - internal methods

- (void)deletePlaceholder
{
    // This is extremely hacky and will be replaced at some point. But it works for now.
    // Except now it crashes the undo function, because it is hacky. This needs to be fixed.
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

- (void)findReplacementRange
{
    NSRange replacementStartRange = [self.rawInputString rangeOfString:self.markBegin options:NSBackwardsSearch];
    NSRange replacementEndRange = [self.rawInputString rangeOfString:self.markEnd options:NSBackwardsSearch];
    NSUInteger replacementLength = (replacementEndRange.location + self.markEnd.length) - (replacementStartRange.location);
    // replace this with self.replacementRange when sure it won't mess anything else up
    self.replacementRange = NSMakeRange(replacementStartRange.location, replacementLength);
}

- (void)findWildcardItemName
{
    NSRange varStartRange = [self.rawInputString rangeOfString:self.markBegin options:NSBackwardsSearch];
    NSRange varEndRange = [self.rawInputString rangeOfString:self.markEnd options:NSBackwardsSearch];
    NSUInteger varLength = (varEndRange.location) - (varStartRange.location + self.markBegin.length);
    self.varName = [self.rawInputString substringWithRange:NSMakeRange((varStartRange.location + self.markBegin.length), varLength)];
}

// There's definitely a better way to do this - refactor later
- (void)findSecondWildcardItemName
{
    NSRange varStartRange = [self.rawInputString rangeOfString:self.markBegin options:NSBackwardsSearch];
    NSRange varEndRange = [self.rawInputString rangeOfString:self.markEnd options:NSBackwardsSearch];
    NSUInteger varLength = (varEndRange.location) - (varStartRange.location + self.markBegin.length);
    self.secondVarName = [self.rawInputString substringWithRange:NSMakeRange((varStartRange.location + self.markBegin.length), varLength)];
}

- (void)replaceLineWithTranslatedCodeString
{
    // First we get the user's original input as a range in textStorage, so we can replace it with code.
    NSRange lineRangeStart = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
    NSRange lineRangeEnd = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
    NSUInteger lineRangeLength = (lineRangeEnd.location+7) - (lineRangeStart.location);
    NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
    
    // We store the user's original input in an array in case we need it.
    self.previousInput = [self.rawInputString substringWithRange:replacementRange];
    [self.previousInputArray addObject:self.previousInput];
    
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
