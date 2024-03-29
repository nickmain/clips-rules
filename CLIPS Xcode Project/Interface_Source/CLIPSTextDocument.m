//
//  CLIPSTextDocument.m
//  CLIPSEditor
//
//  Created by Gary Riley on 2/14/06.
//

#import "CLIPSTextDocument.h"
#import "CLIPSTerminalController.h"
#import "AppController.h"
#import "CLIPSEnvironment.h"
#import "CLIPSTextView.h"

#import <CLIPS/clips.h>

@implementation CLIPSTextDocument

/*********/
/* init: */
/*********/
- (id) init
  {   
   self = [super init];
   if (self) 
     {          
      hiliteColor = [[NSDictionary alloc] initWithObjectsAndKeys: [NSColor selectedTextBackgroundColor], NSBackgroundColorAttributeName, nil];
     }

   return self;
  }

/************/    
/* dealloc: */
/************/    
- (void) dealloc
  {
  }

/*****************/
/* awakeFromNib: */
/*****************/
- (void) awakeFromNib
  {
   /*=====================================================================*/
   /* The action "cog" menu is implemented by using a button with the cog */
   /* icon (which can't display a menu) that sends an action message to a */
   /* hidden NSPopButton that displays the menu. Normally a button takes  */
   /* effect when the mouse button is released, but in this case we want  */
   /* the menu to display immediately when the mouse button goes down.    */
   /*=====================================================================*/
   
   [popupActivator sendActionOn: NSEventMaskLeftMouseDown];
         
   /*======================================================*/
   /* Places a few pixels of white space between the edges */
   /* of the window and the rectangle in which the text is */
   /* displayed in the terminal window.                    */
   /*======================================================*/
   
   NSSize theSize = { 5, 5 };
   [textView setTextContainerInset: theSize];
   
   /*===========================================*/
   /* Disable automatic text substitution (such */
   /* as replacing quotes with curly quotes).   */
   /*===========================================*/
   
   [textView setEnabledTextCheckingTypes: 0];

   /*==================================*/
   /* Set up the horizontal scrollbar. */
   /*==================================*/   
     
   NSScrollView *textScrollView = [textView enclosingScrollView];

   [textScrollView setHasHorizontalScroller: YES];
   [textScrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
   
   [textView setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
   [textView setHorizontallyResizable: YES];
   [textView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
   
   [[textView textContainer] setContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)];
   [[textView textContainer] setWidthTracksTextView: NO];
  }

/*************************************************************/    
/* windowDidBecomeMain: When the window is the main window,  */
/*   the action 'cog' menu needs its normal unpressed image. */
/**************************************************************/    
- (void) windowDidBecomeMain: (NSNotification *) aNotification
  {
   [popupActivator setImage:[NSImage imageNamed:@"CogUp.tiff"]];
  }
  
/**************************************************************/    
/* windowDidResignMain: When the window is no longer the main */
/*   window, the action 'cog' menu needs to be greyed.        */
/**************************************************************/    
- (void) windowDidResignMain: (NSNotification *) aNotification
  {
   [popupActivator setImage:[NSImage imageNamed:@"CogGreyed.tiff"]];
  }

/**************************/
/* resetBackgroundColour: */
/**************************/
- (void) resetBackgroundColour: (id) sender
  {
   [[textView layoutManager] removeTemporaryAttribute: NSBackgroundColorAttributeName forCharacterRange: NSRangeFromString(sender)];
  }

/*******************************/
/* textViewDidChangeSelection: */
/*******************************/
- (void) textViewDidChangeSelection: (NSNotification *) aNotification
  {
   NSRange selectionRange;
   NSUInteger cursorLocation;
   unichar characterToCheck;
   unsigned short nestingDepth;
   NSString *theText = [textView string];
   NSUserDefaults *theValues;
   
   /*==============================================================*/
   /* Check the defaults to see if parentheses should be balanced. */
   /*==============================================================*/
   
   theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    
   if (! [[theValues valueForKey: @"editorBalanceParens"] boolValue]) 
     { return; } 
      
   /*================================================*/
   /* A forward delete will not balance parentheses. */
   /*================================================*/
   
   if ([textView balancingDisabled])
     { return;}

   /*================================================*/
   /* Don't balance parentheses if there is no text. */
   /*================================================*/
   
   if ([theText length] == 0)
     { return; }

   /*=================================*/
   /* Retrieve the current selection. */
   /*=================================*/
          
   selectionRange = [textView selectedRange];

   /*=============================================================*/
   /* Don't balance if there are one or more characters selected. */
   /*=============================================================*/

   if (selectionRange.length != 0) return;
   
   /*======================*/
   /* Where is the cursor? */
   /*======================*/
    
   cursorLocation = selectionRange.location;
   
   if (cursorLocation == 0) return;
   
   cursorLocation--;
   
   /*===============================================*/
   /* What is the character at the cursor location? */
   /*===============================================*/
    
   characterToCheck = [theText characterAtIndex: cursorLocation];

   /*======================================*/
   /* We only balance a right parenthesis. */
   /*======================================*/
   
   if (characterToCheck != ')') return;
   
   /*======================================================================*/
   /* The nesting depth will start at zero. Each time a ')' is encountered */
   /* the nesting depth is incremented by one and each time a '(' is       */
   /* encountered the nesting depth is decremented by one. If a '(' is     */
   /* encountered when the nesting depth is zero (the starting value), the */
   /* matching parenthesis has been found.                                 */
   /*======================================================================*/
   
   nestingDepth = 0;

   /*==================================================*/
   /* Start looking for the matching left parenthesis. */
   /*==================================================*/
      
   while (cursorLocation--) 
     {
      characterToCheck = [theText characterAtIndex: cursorLocation];
      if (characterToCheck == '(') 
        {
         if (nestingDepth == 0) 
           {
            [[textView layoutManager] addTemporaryAttributes: hiliteColor forCharacterRange: NSMakeRange(cursorLocation, 1)];
		    [self performSelector: @selector(resetBackgroundColour:) withObject: NSStringFromRange(NSMakeRange(cursorLocation, 1)) afterDelay: 0.12];
		    return;
		   }
         else
		   { nestingDepth--; }
	    }
      else if (characterToCheck == ')') 
        { nestingDepth++; }
     }
  }

/**************************************/
/* textViewDidChangeTypingAttributes: */
/**************************************/
- (NSDictionary<NSAttributedStringKey, id> *) textView: (NSTextView *) theTextView
                          shouldChangeTypingAttributes: (NSDictionary<NSString *,id> *) oldTypingAttributes
                                          toAttributes: (NSDictionary<NSAttributedStringKey, id> *) newTypingAttributes
  {
   NSFont *theFont = [newTypingAttributes valueForKey: NSFontAttributeName];
   
   NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
   [style setDefaultTabInterval: 3.0 * theFont.maximumAdvancement.width];
   [style setTabStops: [NSArray array]];
   
   theTextView.defaultParagraphStyle = style;
   
   NSMutableDictionary *addedTabs = [NSMutableDictionary dictionaryWithDictionary: newTypingAttributes];
   [addedTabs setObject: style forKey: NSParagraphStyleAttributeName];
   
   [[theTextView textStorage] addAttributes: addedTabs range: NSMakeRange(0, [[[theTextView textStorage] string] length])];

   return addedTabs;
  }
                                           
/***********/
/* string: */
/***********/
- (NSString *) string
  {
   return string;
  }

/**************/
/* setString: */
/**************/
- (void) setString: (NSString *) value
  {
   string = value;
  }

/*****************/
/* updateString: */
/*****************/  
- (void) updateString
  {
   [self setString: [textView string]];
  }

/***************/
/* updateView: */
/***************/
- (void) updateView
  {
   [textView setString: [self string]];
  }

/******************/
/* windowNibName: */
/******************/
- (NSString *) windowNibName
  {
   return @"CLIPSTextDocument";
  }

/*******************************/
/* windowControllerDidLoadNib: */
/*******************************/
- (void) windowControllerDidLoadNib: (NSWindowController *) aController
  {
   [super windowControllerDidLoadNib: aController];
   
   if (! string)
     { [self setString:@""]; }
     
   [self updateView];
  }

/*********************/
/* dataOfType:error: */
/*********************/
- (NSData *) dataOfType: (NSString *) typeName
                  error: (NSError * _Nullable *) outError
   {
    [self updateString];
   
    return [string dataUsingEncoding: NSUTF8StringEncoding allowLossyConversion:YES];
   }

/******************************/
/* readFromData:ofType:error: */
/******************************/
- (BOOL) readFromData: (NSData *) data
               ofType: (NSString *) typeName
                error: (NSError * _Nullable *) outError
  {
   NSString *aString;

   aString = [[NSString alloc] initWithData:data
                               encoding: NSUTF8StringEncoding];
       
   if (aString == nil)
     { return NO; }
     
   [self setString: aString];
   [self updateView];
   
   return YES;
  }

/*********************/
/* validateMenuItem: */
/*********************/
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
  {
   /*=========================================================*/
   /* The "Load Selection" and "Batch Selection" commands are */
   /* only available if there is a selection in the window.   */
   /*=========================================================*/
   
   if (([menuItem action] == @selector(loadSelection:)) ||
       ([menuItem action] == @selector(batchSelection:)))
     {
      NSRange selectedRange = [textView selectedRange];
      
      if (selectedRange.length < 1) return NO;
      
      return YES;
     }
   else if ([menuItem action] == @selector(loadBuffer:))
     { return YES; }

   return [super validateMenuItem: menuItem];
  }
  
/*%%%%%%%%%%%%%%%%*/
/* Action Methods */
/*%%%%%%%%%%%%%%%%*/

/*****************************************************/
/* loadSelection: Handles the Load Selection action. */
/*****************************************************/
- (IBAction) loadSelection: (id) sender
  {
#if (! RUN_TIME) && (! BLOAD_ONLY)
   AppController *theDelegate = [NSApp delegate];
   char *theString, *convString;
   NSUInteger length;
   NSString *entireString = [textView string];
   
   /*============================================*/
   /* There must be a selection for this action. */
   /*============================================*/

   NSRange selectedRange = [textView selectedRange];
   if (selectedRange.length < 1) return;
   
   /*=============================*/
   /* Retrieve the selected text. */
   /*=============================*/
            
   NSString *theSelection = [entireString substringWithRange: selectedRange];
   
   /*==============================*/
   /* Move the text to a C string. */
   /*==============================*/
   
   Environment *theEnvironment = [[theDelegate mainEnvironment] environment];

   length = [theSelection lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
   
   theString = (char *) gm2(theEnvironment,length + 1);

   convString = (char *) [theSelection UTF8String];
   strcpy(theString,convString);

   /*=================================================*/
   /* Bring the attached CLIPS terminal to the front. */
   /*=================================================*/
      
   [[[theDelegate mainTerminal] window] makeKeyAndOrderFront: self];
   
   /*=====================*/
   /* Load the selection. */
   /*=====================*/
   
   WriteString(theEnvironment,STDOUT,"Loading Selection...\n");
   FlushCommandString(theEnvironment);
   
   OpenTextSource(theEnvironment,"aecompiletext",theString,0,(unsigned) length); // TBD Make the name unique
   SetPrintWhileLoading(theEnvironment,true);
   LoadConstructsFromLogicalName(theEnvironment,"aecompiletext");
   SetPrintWhileLoading(theEnvironment,false);
   CloseStringSource(theEnvironment,"aecompiletext");
   
   rm(theEnvironment,theString,(unsigned int) length+1);
   PrintPrompt(theEnvironment);
#endif
  }
  
/*******************************************************/
/* batchSelection: Handles the Batch Selection action. */
/*******************************************************/
- (IBAction) batchSelection: (id) sender
  {
   AppController *theDelegate = [NSApp delegate];
   char *theString, *convString;
   NSUInteger length;
   NSString *entireString = [textView string];
   
   /*============================================*/
   /* There must be a selection for this action. */
   /*============================================*/

   NSRange selectedRange = [textView selectedRange];
   if (selectedRange.length < 1) return;
   
   /*=============================*/
   /* Retrieve the selected text. */
   /*=============================*/
            
   NSString *theSelection = [entireString substringWithRange: selectedRange];
   
   /*==============================*/
   /* Move the text to a C string. */
   /*==============================*/
   
   Environment *theEnvironment = [[theDelegate mainEnvironment] environment];

   length = [theSelection lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
   
   theString = (char *) gm2(theEnvironment,length + 1);
   
   convString = (char *) [theSelection UTF8String];
   strcpy(theString,convString);

   /*=================================================*/
   /* Bring the attached CLIPS terminal to the front. */
   /*=================================================*/
      
   [[[theDelegate mainTerminal] window] makeKeyAndOrderFront: self];

   /*==========================*/
   /* Batch the selected text. */
   /*==========================*/
      
   OpenStringBatch(theEnvironment,"batchtext",theString,false); // TBD generate unique name
  }

/************************************************/
/* loadBuffer: Handles the Load Buffer command. */
/************************************************/
- (IBAction) loadBuffer: (id) sender
  {
#if (! RUN_TIME) && (! BLOAD_ONLY)
   AppController *theDelegate = [NSApp delegate];
   char *theString, *convString;
   NSUInteger length;
   NSString *entireString = [textView string];
      
   /*==============================*/
   /* Move the text to a C string. */
   /*==============================*/
   
   Environment *theEnvironment = [[theDelegate mainEnvironment] environment];

   length = [entireString lengthOfBytesUsingEncoding: NSUTF8StringEncoding];

   theString = (char *) gm2(theEnvironment,length + 1);

   convString = (char *) [entireString UTF8String];
   strcpy(theString,convString);

   /*=================================================*/
   /* Bring the attached CLIPS terminal to the front. */
   /*=================================================*/
      
   [[[theDelegate mainTerminal] window] makeKeyAndOrderFront: self];
  
   /*==================*/
   /* Load the buffer. */
   /*==================*/
   
   WriteString(theEnvironment,STDOUT,"Loading Buffer...\n");
   FlushCommandString(theEnvironment);
   
   OpenTextSource(theEnvironment,"aecompiletext",theString,0,(unsigned) length); // TBD Make the name unique
   SetPrintWhileLoading(theEnvironment,true);
   LoadConstructsFromLogicalName(theEnvironment,"aecompiletext");
   SetPrintWhileLoading(theEnvironment,false);
   CloseStringSource(theEnvironment,"aecompiletext");
   
   rm(theEnvironment,theString,(unsigned int) length+1);
   PrintPrompt(theEnvironment);
#endif
  }

/*****************************************/
/* balance: Handles the Balance command. */
/*****************************************/
- (IBAction) balance: (id) sender
  {
   NSRange selectionRange;
   NSUInteger leftMiddle, rightMiddle, textLength;
   unichar characterToCheck;
   int count, leftCount, rightCount;
   NSUInteger i;
   BOOL endReached;
   NSString *theText = [textView string];
   
   /*====================================*/
   /* Can't balance if there is no text. */
   /*====================================*/
   
   if ([theText length] == 0)
     {
      NSBeep(); 
      return;
     }

   /*=================================*/
   /* Retrieve the current selection. */
   /*=================================*/
          
   selectionRange = [textView selectedRange];
       
   /*=============================================================*/
   /* Get information about the current selection to be balanced. */
   /*=============================================================*/

   leftMiddle = selectionRange.location;
   rightMiddle = selectionRange.location + selectionRange.length;
   textLength = [theText length]; /* TBD UTF-8 */
 
   /*===================================*/
   /* If the selection is empty then... */
   /*===================================*/

   if (leftMiddle == rightMiddle)
     {
      /*============================================*/
      /* If '(' is to the right of the cursor, then */
      /* all balancing should occur to the right.   */
      /*============================================*/

      if ((leftMiddle < textLength) && ([theText characterAtIndex: leftMiddle] == '('))
        { 
         [self balanceIt: theText
               leftMiddle: leftMiddle
               rightMiddle: leftMiddle + 1
               leftCount: 1
               rightCount: 0
               textLength: textLength];
        }

      /*================================================*/
      /* Else if ')' is to the left of the cursor, then */
      /* all balancing should occur to the left.        */
      /*================================================*/

      else if ((leftMiddle > 0) ? ([theText characterAtIndex: (leftMiddle - 1)] == ')') : 0)
        { 
         if (leftMiddle < 2)
           {
            NSBeep();
            return;
           }
  
         [self balanceIt: theText
               leftMiddle: leftMiddle - 2
               rightMiddle: leftMiddle
               leftCount: 0
               rightCount: -1
               textLength: textLength];
        }

      /*====================================================*/
      /* Else balancing occurs to left and right of cursor. */
      /*====================================================*/

      else
        { 
         [self balanceIt: theText
               leftMiddle: leftMiddle - 1
               rightMiddle: rightMiddle
               leftCount: 0
               rightCount: 0
               textLength: textLength];
        }
     }
     
   /*===================================================*/
   /* Otherwise the selection is non-empty therefore... */
   /*===================================================*/

   else
     {
      /*===============================================*/
      /* Determine the number of right parentheses ')' */
      /* that need to be balanced from the left side.  */
      /*===============================================*/

      count = 0;
      leftCount = 0;

      for (i = leftMiddle ; i < rightMiddle ; i++)
        {
         characterToCheck = [theText characterAtIndex: i];

         if (characterToCheck == '(') count++;
         else if (characterToCheck == ')') count--;
         if (count < leftCount) leftCount = count;
        }

      /*===============================================*/
      /* Determine the number of left parentheses '('  */
      /* that need to be balanced from the right side. */
      /*===============================================*/

      count = 0;
      rightCount = 0;

      for (endReached = NO, i = rightMiddle - 1 ; ! endReached ;)
        {
         characterToCheck = [theText characterAtIndex: i];

         if (characterToCheck == '(') count++;
         else if (characterToCheck == ')') count--;
         if (count > rightCount) rightCount = count;
         
         if (i == leftMiddle) endReached = YES;
         else i--;
        }

      /*==============================================*/
      /* Balance to the left and right of the cursor. */
      /*==============================================*/
      
      [self balanceIt: theText
            leftMiddle: ((leftMiddle == 0) ? 0 : leftMiddle - 1)
            rightMiddle: rightMiddle
            leftCount: leftCount
            rightCount: rightCount
            textLength: textLength];
     }
  }

/********************************************************/
/* balanceIt: Balances a selection of text by extending */
/* it to the left and right until the number of left    */
/* and right parentheses is balanced.                   */
/********************************************************/
- (void) balanceIt: (NSString *) theText
         leftMiddle: (NSUInteger) leftMiddle
         rightMiddle: (NSUInteger) rightMiddle
         leftCount: (int) leftCount
         rightCount: (int) rightCount
         textLength: (NSUInteger) textLength
  {
   unichar characterToCheck;
   BOOL beginningReached = NO;
   
   /*==========================================================*/
   /* Balance the left side of the text by moving left and up. */
   /*==========================================================*/

   while (leftCount <= 0)
     {
      if (beginningReached)
        {
         NSBeep();
         return;
        }
        
      characterToCheck = [theText characterAtIndex: leftMiddle];
      
      if (characterToCheck == '(') leftCount++;
      else if (characterToCheck == ')') leftCount--;
      
      if (leftCount <= 0)
        {
         if (leftMiddle > 0) leftMiddle--;
         else beginningReached = YES;
        }
     }
     
   /*==============================================================*/
   /* Balance the right side of the text by moving right and down. */
   /*==============================================================*/

   while (rightCount >= 0)
     {
      if (rightMiddle >= textLength)
        {
         NSBeep();
         return;
        }

      characterToCheck = [theText characterAtIndex: rightMiddle];

      if (characterToCheck == '(') rightCount++;
      else if (characterToCheck == ')') rightCount--;

      rightMiddle++;  
     }
     
   /*=============================================*/
   /* Set the current selection to balanced text. */
   /*=============================================*/
   
   NSRange theRange = { leftMiddle, rightMiddle - leftMiddle };
   
   [textView setSelectedRange: theRange];   

   /*=====================================*/
   /* Make sure the selection is visible. */
   /*=====================================*/

   [textView scrollRangeToVisible: theRange]; 
  }

/*****************************************/
/* comment: Handles the Comment command. */
/*****************************************/
- (IBAction) comment: (id) sender
  {
   NSRange selectionRange, rangeOfLine, tempRange;
   unsigned int numberOfLines = 0, i;
   NSUInteger tempLocation, maxSelectedRange;
   NSUInteger locationOfFirstLine, locationOfLastLine;
   NSString *theText = [textView string];
      
   /*==============================================*/
   /* Retrieve the current selection and determine */
   /* the location of the beginning and end.       */
   /*==============================================*/
          
   selectionRange = [textView selectedRange];
   tempLocation = selectionRange.location;
   maxSelectedRange = NSMaxRange(selectionRange);
   
   /*=====================================*/
   /* Determine the beginning location of */
   /* the first line to be commented.     */
   /*=====================================*/
   
   tempRange.location = tempLocation;
   tempRange.length = 0;
   locationOfFirstLine = [theText lineRangeForRange: tempRange].location;
  
   /*=============================================*/
   /* Count the number of lines in the selection. */
   /*=============================================*/

   do
     {
      tempRange.location = tempLocation;
      tempRange.length = 0;
	  tempLocation = NSMaxRange([theText lineRangeForRange: tempRange]);
	  numberOfLines++;
	 } 
   while (tempLocation < maxSelectedRange);

   /*=========================================================*/
   /* Remember the location of the end of the last line, then */
   /* reset the temporary location back to the first line.    */
   /*=========================================================*/
       
   locationOfLastLine = tempLocation;
   tempLocation = selectionRange.location;

   /*=======================================================*/
   /* Iterate over each line adding a ';' at the beginning. */
   /*=======================================================*/
   
   for (i = 0; i < numberOfLines; i++)
     {
      /*==============================================*/
      /* Determine the beginning and end of the line. */
      /*==============================================*/
      
      tempRange.location = tempLocation;
      tempRange.length = 0;
	  rangeOfLine = [theText lineRangeForRange: tempRange];

      /*======================================*/
      /* Comment character should be inserted */
      /* at the beginning of the line.        */
      /*======================================*/
      
      tempRange.location = rangeOfLine.location;
      tempRange.length = 0;
      
      /*==============================================================*/
      /* Add the comment character. Using shouldChangeTextInRange and */
      /* didChangeText are necessary to support undoing this action.  */
      /*==============================================================*/
      
	  if ([textView shouldChangeTextInRange: tempRange replacementString: @";"]) 
		{ 		 
         [textView replaceCharactersInRange: tempRange withString: @";"];
		 [textView didChangeText];
        }
        
      /*========================*/
      /* Move to the next line. */
      /*========================*/

      tempRange.location = tempLocation;
      tempRange.length = 0;
	  tempLocation = NSMaxRange([theText lineRangeForRange: tempRange]);
     }

   /*=======================================================*/
   /* If there was a selection when the comment command was */
   /* invoked, extend it to completely include all of the   */
   /* lines in which comment characters were added.         */
   /*=======================================================*/
   
   if (selectionRange.length > 0)
  	 { 
      tempRange.location = locationOfFirstLine;
      tempRange.length = (locationOfLastLine - locationOfFirstLine) + numberOfLines;
      [textView setSelectedRange: tempRange];
     }
  }
  
/*********************************************/
/* uncomment: Handles the Uncomment command. */
/*********************************************/
- (IBAction) uncomment: (id) sender
  {
   NSRange selectionRange, rangeOfLine, tempRange;
   unsigned int numberOfLines = 0, i;
   unsigned int numberOfCharactersDeleted = 0;
   NSUInteger tempLocation, maxSelectedRange;
   NSUInteger locationOfFirstLine, locationOfLastLine;
   NSString *theText = [textView string];
      
   /*==============================================*/
   /* Retrieve the current selection and determine */
   /* the location of the beginning and end.       */
   /*==============================================*/
          
   selectionRange = [textView selectedRange];
   tempLocation = selectionRange.location;
   maxSelectedRange = NSMaxRange(selectionRange);
   
   /*=====================================*/
   /* Determine the beginning location of */
   /* the first line to be commented.     */
   /*=====================================*/
   
   tempRange.location = tempLocation;
   tempRange.length = 0;
   locationOfFirstLine = [theText lineRangeForRange: tempRange].location;
  
   /*=============================================*/
   /* Count the number of lines in the selection. */
   /*=============================================*/

   do
     {
      tempRange.location = tempLocation;
      tempRange.length = 0;
	  tempLocation = NSMaxRange([theText lineRangeForRange: tempRange]);
	  numberOfLines++;
	 } 
   while (tempLocation < maxSelectedRange);

   /*=========================================================*/
   /* Remember the location of the end of the last line, then */
   /* reset the temporary location back to the first line.    */
   /*=========================================================*/
       
   locationOfLastLine = tempLocation;
   tempLocation = selectionRange.location;

   /*=======================================================*/
   /* Iterate over each line adding a ';' at the beginning. */
   /*=======================================================*/
   
   for (i = 0; i < numberOfLines; i++)
     {
      /*==============================================*/
      /* Determine the beginning and end of the line. */
      /*==============================================*/
      
      tempRange.location = tempLocation;
      tempRange.length = 0;
	  rangeOfLine = [theText lineRangeForRange: tempRange];

      if ([theText characterAtIndex: rangeOfLine.location] == ';')
        {
         /*=====================================*/
         /* Comment character should be removed */
         /* from the beginning of the line.     */
         /*=====================================*/
      
         tempRange.location = rangeOfLine.location;
         tempRange.length = 1;
         
         /*=================================================================*/
         /* Remove the comment character. Using shouldChangeTextInRange and */
         /* didChangeText are necessary to support undoing this action.     */
         /*=================================================================*/
      
	     if ([textView shouldChangeTextInRange: tempRange replacementString: @""]) 
		   { 		 
            [textView replaceCharactersInRange: tempRange withString: @""];
		    [textView didChangeText];
            numberOfCharactersDeleted++;
           }
        } 
        
      /*========================*/
      /* Move to the next line. */
      /*========================*/

      tempRange.location = tempLocation;
      tempRange.length = 0;
	  tempLocation = NSMaxRange([theText lineRangeForRange: tempRange]);
     }

   /*===============================================*/
   /* Beep if there weren't any characters deleted. */
   /*===============================================*/
   
   if (numberOfCharactersDeleted == 0)
     {
      NSBeep();
      return;
     }
     
   /*=======================================================*/
   /* If there was a selection when the comment command was */
   /* invoked, extend it to completely include all of the   */
   /* lines in which comment characters were added.         */
   /*=======================================================*/
   
   if (selectionRange.length > 0)
  	 { 
      tempRange.location = locationOfFirstLine;
      tempRange.length = (locationOfLastLine - locationOfFirstLine) - numberOfCharactersDeleted;
      [textView setSelectedRange: tempRange];
     }
  }

@end
