/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "O2ViewerThumbnailsMatrix.h"
#import "DicomStudy.h"

@implementation O2ViewerThumbnailsMatrix // we overload NSMatrix, but this class isn't as capable as NSMatrix: we only support 1-column-wide matrixes! so, actually, this isn't a matrix, it's a list, but we still use NSMAtrix so we don't have to modify ViewerController

- (CGFloat)podCellHeight {
    return self.cellSize.height/2; // this probably will self.numberOfRowsbe changed
}

- (NSRect*)computeCellRectsForCells:(NSArray*)cells maxIndex:(NSInteger)maxIndex {
    NSSize cellSize = self.cellSize;
    CGFloat podCellHeight = self.podCellHeight;
    
    NSMutableData* rectsmd = [NSMutableData dataWithLength:sizeof(NSRect)*(maxIndex+1)];
    NSRect* rects = (NSRect*)rectsmd.mutableBytes;
    
    NSRect rect = NSMakeRect(0, 0, cellSize.width, 0);
    for (NSInteger i = 0; i <= maxIndex; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        O2ViewerThumbnailsMatrixRepresentedObject* oro = [cell representedObject];
        if ([oro.object isKindOfClass:[NSManagedObject class]] || oro.children.count) {
            rect.size.height = cellSize.height;
        } else rect.size.height = podCellHeight;
        
        rects[i] = rect;
        
        rect.origin.y += rect.size.height;
        rect.origin.y += self.intercellSpacing.height;
    }
    
    return rects;
}

- (void)mouseDown:(NSEvent*)event {
    // whis is where we should check for edit-clicks... but we don't need editing for the preview matrix

//    BOOL act = NO;
    NSEvent* lastMouse = event;

    do {
        NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        NSInteger row, column;
        
        [[self superview] autoscroll:lastMouse];
        [self lockFocus];
        
        if ([self getRow:&row column:&column forPoint:point]) {
            NSCell* cell = [self.cells objectAtIndex:row];
            
            NSRect cellFrame = [self cellFrameAtRow:row column:column];
            int currentState = cell.state;
            int nextState = cell.nextState;
            
            [cell highlight:YES withFrame:cellFrame inView:self];
            
            cell.state = nextState;
            
            [self selectCellAtRow:[self.cells indexOfObjectIdenticalTo:cell] column:0];
            if ([cell trackMouse:lastMouse inRect:cellFrame ofView:self untilMouseUp:NO]) {
                self.keyCell = cell;
                [cell highlight:NO withFrame:cellFrame inView:self];
                [self unlockFocus];
//                act = YES;
                break;
            }
            else {
                [cell setState:currentState];
                [cell highlight:NO withFrame:cellFrame inView:self];
            }
        }
        
        [self unlockFocus];
        [self.window flushWindow];
    
        event = [self.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask|NSPeriodicMask];
        if(event.type != NSPeriodic)
            lastMouse=event;
    } while (lastMouse.type != NSLeftMouseUp);

/*    if (act)
        if (event.clickCount == 2)
            [self sendDoubleAction];
        else [self sendAction];*/
    
    [[self window] flushWindow];
}

- (NSRect)cellFrameAtRow:(NSInteger)row column:(NSInteger)col {
    NSArray* cells = self.cells;
    
    if (row < 0 || row > self.numberOfRows-1)
        return NSZeroRect;
    
    NSRect* rects = [self computeCellRectsForCells:cells maxIndex:row];
    
    return rects[row];
}

- (BOOL)getRow:(NSInteger*)row column:(NSInteger*)col forPoint:(NSPoint)aPoint {
    *col = 0;
    
    NSArray* cells = self.cells;
    NSRect* rects = [self computeCellRectsForCells:cells maxIndex:self.numberOfRows-1];
    
    for (NSInteger i = 0; i < self.numberOfRows; ++i)
        if (NSPointInRect(aPoint, rects[i])) {
            *row = i;
            return YES;
        }
    
    return NO;
}

//- (void)highlightCell:(BOOL)flag atRow:(NSInteger)row column:(NSInteger)column { // .....
//    if (flag)
//        _highlightedRow = row;
//    else _highlightedRow = -1;
//}

- (void)sizeToCells {
    NSRect r = [self cellFrameAtRow:self.numberOfRows-1 column:0];
    [self setFrame:NSMakeRect(0, 0, r.origin.x+r.size.width, r.origin.y+r.size.height)];
   // [self.superview setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSArray* cells = self.cells;
    NSRect* rects = [self computeCellRectsForCells:cells maxIndex:self.numberOfRows-1];
    
    for (NSInteger i = 0; i < self.numberOfRows; ++i) {
        NSCell* cell = [cells objectAtIndex:i];
        [cell drawWithFrame:rects[i] inView:self];
    }
}

@end

@implementation O2ViewerThumbnailsMatrixRepresentedObject

@synthesize object = _object;
@synthesize children = _children;

+ (id)object:(id)object {
    return [self object:object children:nil];
}

+ (id)object:(id)object children:(NSArray*)children {
    O2ViewerThumbnailsMatrixRepresentedObject* oro = [[[[self class] alloc] init] autorelease];
    oro.object = object;
    oro.children = [[children copy] autorelease];
    return oro;
}

- (void)dealloc {
    self.object = nil;
    self.children = nil;
    [super dealloc];
}

@end


