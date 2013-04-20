//
//  CGTagLabelList.m
//  GCTagLabelList
//
//  Created by Green on 13/2/7.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "GCTagList.h"

#ifndef GC_BLOCK_WEAK
    #if GC_SUPPORT_ARC
        #define GC_BLOCK_WEAK __weak
    #else
        #define GC_BLOCK_WEAK
    #endif
#endif

#define LABEL_MARGIN 2.0f 
#define BOTTOM_MARGIN 5.0f 

#define GCLog(fmt, ...) NSLog((@"[GCLog]:"fmt), ##__VA_ARGS__)

@interface GCTagLabel (Private)
+ (CGRect)rectangleOfTagLabelWithText:(NSString*)textStr
                             maxWidth:(CGFloat)maxWidth
                        accessoryType:(GCTagLabelAccessoryType)type __deprecated;

+ (CGRect)rectangleOfTagLabelWithText:(NSString*)textStr
                        labelMaxWidth:(CGFloat)maxWidth
                            labelFont:(UIFont*)font
                        accessoryType:(GCTagLabelAccessoryType)type;

- (void)reSizeLabel;
@end

@interface GCTagList ()
@property (nonatomic, GC_STRONG) NSMutableSet* visibleSet;
@property (nonatomic, GC_STRONG) NSMutableDictionary* reuseSet;
@property (assign) CGFloat rowMaxWidth;
@property (assign) NSInteger nowSelected;

/**
 * add taglabel to resue set, if tag has not identifier, the tag will be release.
 */
- (void)addTagLabelToReuseSet:(GCTagLabel*)tag;

/**
 * if taglabel has accessoryButton, add Target will touchupindex for accessoryButton.
 */
- (void)addTappedTarget:(GCTagLabel*)tag;

- (void)handleTouchUpInsideTagAccessoryButton:(UIButton*)sender;

/**
 * if maxRow > 0, and the taglabel's row > maxRow, use this method to find the taglabel which one is the group label.
 */
- (GCTagLabel*)tagLabelForInterruptIndex:(NSInteger)startIndex;

/**
 * layout taglabel with range;
 */
- (void)layoutTagLabelsWithRange:(NSRange)range;

- (void)layoutTagLabelsWithRange:(NSRange)range animation:(BOOL)animated;

/**
 * if tag needs go the next row, return YES. 
 */
- (BOOL)needsGoToTheNextRowWidthFrame:(CGRect)frame preFrame:(CGRect)preFrame;

/**
 * get row of label located.
 */
- (NSInteger)rowOfLabelAtIndex:(NSInteger)indexOfTag;

/**
 * update taglist's frame.
 */
- (void)updateViewWithLastFrame:(CGRect)frame;
@end

@implementation GCTagList
#pragma mark - lifecycle
- (void)dealloc {
    self.visibleSet = nil;
    self.reuseSet = nil;
#if !GC_SUPPORT_ARC
    [super dealloc];
#endif
}

- (void)awakeFromNib {
    self.rowMaxWidth = CGRectGetWidth(self.frame);
    self.nowSelected = NSNotFound;
    self.firstRowLeftMargin = 0.f;
    self.backgroundColor = [UIColor clearColor];
    self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
    self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
}

- (id)init {
    self = [super init];
    if(self) {
        self.nowSelected = NSNotFound;
        self.firstRowLeftMargin = 0.f;
        self.rowMaxWidth = 0.f;
        self.backgroundColor = [UIColor clearColor];
        self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.rowMaxWidth = CGRectGetWidth(frame);
        self.nowSelected = NSNotFound;
        self.firstRowLeftMargin = 0.f;
        self.backgroundColor = [UIColor clearColor];
        self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
    }
    return self;
}

#pragma mark - Public mehtod
- (GCTagLabel*)dequeueReusableTagLabelWithIdentifier:(NSString *)identifier {
    GCTagLabel* tag = nil;
    
    NSMutableSet* tempSet = (NSMutableSet*)[self.reuseSet objectForKey:identifier];
    if(tempSet) {
        tag = GC_AUTORELEASE(GC_RETAIN([tempSet anyObject]));
        if(tag) {
            [tag setSelected:NO animation:NO];
            [tempSet removeObject:tag];
            [self.reuseSet setObject:tempSet forKey:identifier];
        }
    }
    return tag;
}

- (GCTagLabel*)tagLabelAtIndex:(NSInteger)index {
    GCTagLabel* tagLabel = nil;
    for (GCTagLabel* tempLabel in [self.visibleSet allObjects]) {
        NSInteger indexForTagLabel = [[tempLabel valueForKeyPath:@"index"] integerValue];
        if(index == indexForTagLabel) {
            tagLabel = tempLabel;
            break;
        }
    }
    return tagLabel;
}

- (void)reloadData {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    
    for (GCTagLabel* tag in self.subviews) {
        [tag removeFromSuperview];
        [self addTagLabelToReuseSet:tag];
    }
    NSInteger numberOfTagLabel = [self.dataSource numberOfTagLabelInTagList:self];
    NSRange range = NSMakeRange(0, numberOfTagLabel);
    [self layoutTagLabelsWithRange:range];
}

- (void)deselectedLabelAtIndex:(NSInteger)index animated:(BOOL)animated {
    self.nowSelected = NSNotFound;
    for (GCTagLabel* tagLabel in [self.visibleSet allObjects]) {
        if([[tagLabel valueForKeyPath:@"index"] integerValue] == index) {
            [tagLabel setSelected:NO animation:animated];
            break;
        }
    }
}

- (void)reloadTagLabelWithRange:(NSRange)range {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    
    [self reloadTagLabelWithRange:range withAnimation:NO];
}

- (void)reloadTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    
    NSInteger sIndex = range.location;
    NSInteger eIndex = sIndex + range.length;
    
    for (int i = sIndex; i < eIndex; i++) {
        GCTagLabel* tag = [self tagLabelAtIndex:i];
        if(tag) {
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
    }
    
    [self layoutTagLabelsWithRange:range
                         animation:animated];
    
}

- (void)deleteTagLabelWithRange:(NSRange)range {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    [self deleteTagLabelWithRange:range withAnimation:NO];
}

- (void)deleteTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    
    NSInteger oldCount = [self.visibleSet count];
    
    for (int i = 0; i < range.length; i++) {
        NSInteger index = i + range.location;
        GCTagLabel* tag = [self tagLabelAtIndex:index];
        
        if(tag) {
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
    }
    
    NSMutableArray* tempAry = [NSMutableArray arrayWithCapacity:oldCount-range.length];
    for (int i = range.location+range.length; i < oldCount; i++) {
        GCTagLabel* tag = [self tagLabelAtIndex:i];
        [tempAry addObject:tag];
    }
    
    for (int i = 0; i < tempAry.count; i++) {
        NSInteger newIndex = range.location + i;
        GCTagLabel* tag = [tempAry objectAtIndex:i];
        [tag setValue:[NSString stringWithFormat:@"%d", newIndex] forKeyPath:@"index"];
    }
    
    
    NSInteger totalCount = [self.dataSource numberOfTagLabelInTagList:self];
    NSRange reloadRange = NSMakeRange(range.location, totalCount - range.location);
    NSInteger maxRow = 0, nowRow = [self rowOfLabelAtIndex:range.location-1];
    if([self.dataSource respondsToSelector:@selector(maxNumberOfRowAtTagList:)]) {
        maxRow = [self.dataSource maxNumberOfRowAtTagList:self];
    }
    
    CGRect frame = [self layoutAndGetLastFrameWithRange:reloadRange
                                               rowRange:NSMakeRange(nowRow, maxRow)
                                               animated:animated
                                              lastFrame:CGRectNull];
    
    [self updateViewWithLastFrame:frame];
    
}

- (void)insertTagLabelWithRagne:(NSRange)range {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    
    [self insertTagLabelWithRagne:range withAnimation:NO];
}

- (void)insertTagLabelWithRagne:(NSRange)range withAnimation:(BOOL)animated {
    if(![self checkImplementDataSourceRequireMehtod])
        return;
    
    
    NSInteger oldCount = [self.visibleSet count];
    
    NSMutableArray* tempAry = [NSMutableArray arrayWithCapacity:oldCount-range.length];
    for (int i = range.location; i < oldCount; i++) {
        [tempAry addObject:[self tagLabelAtIndex:i]];
    }
    
    NSInteger sIndex = range.location + range.length;
    for (int i = 0; i < tempAry.count; i++) {
        NSInteger newIndex = sIndex + i;
        GCTagLabel* tag = [tempAry objectAtIndex:i];
        [tag setValue:[NSString stringWithFormat:@"%d", newIndex] forKeyPath:@"index"];
    }
    
    [self layoutTagLabelsWithRange:range animation:animated];
}

#pragma mark - override
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView* temp = [super hitTest:point withEvent:event];
    if(temp == self) {
        return nil;
    }
    return temp;
}

#pragma mark -
#pragma mark Private
- (BOOL)checkImplementDataSourceRequireMehtod {
    if(!self.dataSource ||
       ![self.dataSource respondsToSelector:@selector(numberOfTagLabelInTagList:)] ||
       ![self.dataSource respondsToSelector:@selector(tagList:tagLabelAtIndex:)])
        return NO;
    
    return YES;
}

- (void)addTagLabelToReuseSet:(GCTagLabel*)tag {
    if(tag.reuseIdentifier) {
        NSString* string = [NSString stringWithString:tag.reuseIdentifier];
        NSMutableSet* tempSet = self.reuseSet[string];
        if(!tempSet) {
            tempSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        }
        [tempSet addObject:tag];
        [self.visibleSet minusSet:tempSet];
        [self.reuseSet setObject:tempSet forKey:string];
    }
}

- (void)addTappedTarget:(GCTagLabel*)tag {
    if(tag.accessoryType != GCTagLabelAccessoryNone) {
        UIButton* accessoryButton = [tag valueForKeyPath:@"accessoryButton"];
        if(accessoryButton.allTargets.count == 0) {
            [accessoryButton addTarget:self
                                action:@selector(handleTouchUpInsideTagAccessoryButton:)
                      forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)handleTouchUpInsideTagAccessoryButton:(UIButton*)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(tagList:accessoryButtonTappedAtIndex:)]) {
        NSInteger index = [[(GCTagLabel*)[sender superview] valueForKeyPath:@"index"] integerValue];
        [self.delegate tagList:self accessoryButtonTappedAtIndex:index];
    }
}

- (GCTagLabel*)tagLabelForInterruptIndex:(NSInteger)startIndex {
    
    GCTagLabelAccessoryType groupType = GCTagLabelAccessoryNone;
    if([self.dataSource respondsToSelector:@selector(accessoryTypeForGroupTagLabel)]) {
        groupType = [self.dataSource accessoryTypeForGroupTagLabel];
    }
    
    GCTagLabel* tag = nil;
    CGRect rect = CGRectZero;
    for (int i = startIndex; i > 0; i--) {
        tag = [self tagLabelAtIndex:i];
        if(!tag)
            continue;
        
        rect = (i-1)>=0 ? [self tagLabelAtIndex:(i-1)].frame : CGRectZero;
        NSString* tempText;
        if([self.delegate respondsToSelector:@selector(tagList:labelTextForGroupTagLabel:)]) {
            tempText = [self.delegate tagList:self labelTextForGroupTagLabel:i];
        } else {
            tempText = @"others";
        }
        
        CGRect tempRect = [GCTagLabel rectangleOfTagLabelWithText:tempText
                                                    labelMaxWidth:tag.maxWidth
                                                        labelFont:[tag valueForKeyPath:@"label.font"]
                                                    accessoryType:groupType];
        
        BOOL isNeedGoNextRow = [self needsGoToTheNextRowWidthFrame:tempRect preFrame:rect];
        if (isNeedGoNextRow) {
            [self addTagLabelToReuseSet:tag];
            [tag removeFromSuperview];
            tag = nil;
            continue;
        }
        rect = tag.frame;
        [tag setLabelText:tempText accessoryType:groupType];
        [tag reSizeLabel];
        [self addTappedTarget:tag];
        
        CGRect frame = tag.frame;
        frame.origin = rect.origin;
        tag.frame = frame;
        break;
    }
    return tag;
}

- (void)layoutTagLabelsWithRange:(NSRange)range {
    NSInteger numberOfTagLabel = [self.dataSource numberOfTagLabelInTagList:self];
    NSInteger startIndex = range.location;
    NSInteger endIndex = startIndex + range.length;
    
    
    if(endIndex > numberOfTagLabel) {
        GCLog(@"the range is error.");
        return;
    }
    
    
    NSInteger maxRow = 0, nowRow = 1;
    if([self.dataSource respondsToSelector:@selector(maxNumberOfRowAtTagList:)]) {
        maxRow = [self.dataSource maxNumberOfRowAtTagList:self];
    }
    
    if (startIndex > 0) {
        nowRow = [self rowOfLabelAtIndex:startIndex-1];
    }
    
    GCTagLabelAccessoryType groupType = GCTagLabelAccessoryNone;
    if([self.dataSource respondsToSelector:@selector(accessoryTypeForGroupTagLabel)]) {
        groupType = [self.dataSource accessoryTypeForGroupTagLabel];
    }
    
    
    CGRect preTagLabelFrame = CGRectZero;
    for (int i = startIndex; i < endIndex; i++) {
        /**
         * if there is previous label, get the previous's frame.
         */
        if(CGRectEqualToRect(preTagLabelFrame, CGRectZero)) {
            preTagLabelFrame = i - 1 >= 0 ? [self tagLabelAtIndex:i-1].frame : CGRectZero;
        }
        GCTagLabel* tag = (([self.dataSource tagList:self tagLabelAtIndex:i]));
        
        if(tag.maxWidthFitToListWidth)
            tag.maxWidth = CGRectGetWidth(self.frame);
        
        [tag reSizeLabel];
        [tag setValue:[NSString stringWithFormat:@"%d",i] forKeyPath:@"index"];
        
        [self addTappedTarget:tag];
        CGRect viewFrame = tag.frame;
        
        BOOL needsGoNextRow = [self needsGoToTheNextRowWidthFrame:viewFrame
                                                          preFrame:preTagLabelFrame];
        
        CGFloat leftMargin = CGRectGetWidth(preTagLabelFrame) == 0.f ? self.firstRowLeftMargin : 0;
        CGFloat labelMargin = CGRectGetWidth(preTagLabelFrame) == 0.f ? 0 : LABEL_MARGIN;
        if (needsGoNextRow) {
            if(CGRectGetWidth(preTagLabelFrame) > 0.f && maxRow > 0) {
                nowRow ++;
                if(nowRow > maxRow)  {
                    [self addTagLabelToReuseSet:tag];
                    tag = nil;
                    tag = [self tagLabelForInterruptIndex:i];
                    viewFrame = tag.frame;
                } else {
                    viewFrame.origin = CGPointMake(0,
                                                   preTagLabelFrame.origin.y +
                                                   CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
                }
            }
            else {
                viewFrame.origin = CGPointMake(0,
                                               preTagLabelFrame.origin.y +
                                               CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
            }
        } else {
            viewFrame.origin = CGPointMake(leftMargin + preTagLabelFrame.origin.x + preTagLabelFrame.size.width + labelMargin ,
                                           preTagLabelFrame.origin.y);
        }
        tag.frame = viewFrame;
        [self addSubview:tag];
        [self.visibleSet addObject:tag];
        preTagLabelFrame = viewFrame;
        if(maxRow > 0 && nowRow > maxRow) {
            break;
        }
    }
    
    
    if(endIndex < numberOfTagLabel) {
        NSRange layoutRange = NSMakeRange(endIndex, numberOfTagLabel - endIndex);
        preTagLabelFrame = [self layoutAndGetLastFrameWithRange:layoutRange
                                                       rowRange:NSMakeRange(nowRow, maxRow)
                                                       animated:NO
                                                      lastFrame:preTagLabelFrame];
    }
    
    for (NSString* key in [self.reuseSet allKeys]) {
        NSMutableSet *set = [self.reuseSet objectForKey:key];
        [set minusSet:self.visibleSet];
        [self.reuseSet setObject:set forKey:key];
    }
    
    [self updateViewWithLastFrame:preTagLabelFrame];
}

- (BOOL)needsGoToTheNextRowWidthFrame:(CGRect)frame preFrame:(CGRect)preFrame {
    BOOL isNeed = NO;
    CGFloat leftMargin = CGRectGetWidth(preFrame) == 0.f ? self.firstRowLeftMargin : 0;
    CGFloat labelMargin = CGRectGetWidth(preFrame) == 0.f ? 0 : LABEL_MARGIN;
    CGFloat occupyWidth = leftMargin + preFrame.origin.x +
    preFrame.size.width + CGRectGetWidth(frame) + labelMargin;
    isNeed = self.rowMaxWidth < occupyWidth;
    return isNeed;
}

- (CGRect)layoutAndGetLastFrameWithRange:(NSRange)range rowRange:(NSRange)rowRange __deprecated {
    
    NSInteger maxRow = rowRange.length, nowRow = rowRange.location;
    NSInteger total = range.location + range.length;
    /**
     * maxRow default 0, it means not limit maxRow.
     */
    if(nowRow > maxRow && maxRow > 0) {
        for (int i = range.location; i < total ; i++) {
            GCTagLabel* tag = [self tagLabelAtIndex:i];
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
        return range.location > 0 ? [self tagLabelAtIndex:range.location-1].frame : CGRectZero;
    }
    
    CGRect viewFrame, preframe;
    NSInteger currentIndex = range.location;
    preframe = currentIndex > 0 ? [self tagLabelAtIndex:currentIndex-1].frame : CGRectZero;
    
    
    for (int i = range.location; i < total ; i++) {
        preframe = i - 1 >= 0 ? [self tagLabelAtIndex:i-1].frame : CGRectZero;
        GCTagLabel* tag = [self tagLabelAtIndex:i];
        viewFrame = tag.frame;
        BOOL needsGoNextRow = [self needsGoToTheNextRowWidthFrame:viewFrame
                                                         preFrame:preframe];
        
        CGFloat leftMargin = CGRectGetWidth(preframe) == 0.f ? self.firstRowLeftMargin : 0;
        CGFloat labelMargin = CGRectGetWidth(preframe) == 0.f ? 0 : LABEL_MARGIN;
        if (needsGoNextRow) {
            if(CGRectGetWidth(preframe) > 0.f && maxRow > 0) {
                nowRow ++;
                if(nowRow > maxRow)  {
                    [self addTagLabelToReuseSet:tag];
                    tag = nil;
                    tag = [self tagLabelForInterruptIndex:i];
                    viewFrame = tag.frame;
                } else {
                    viewFrame.origin = CGPointMake(0,
                                                   preframe.origin.y +
                                                   CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
                }
            }
            else {
                viewFrame.origin = CGPointMake(0,
                                               preframe.origin.y +
                                               CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
            }
        } else {
            viewFrame.origin = CGPointMake(leftMargin + preframe.origin.x + preframe.size.width + labelMargin ,
                                           preframe.origin.y);
        }
        tag.frame = viewFrame;
        preframe = viewFrame;
    }
    
    return preframe;
}

- (NSInteger)rowOfLabelAtIndex:(NSInteger)indexOfTag {
    NSInteger row = 1;
    
    if(indexOfTag < 0) {
        return row;
    }
    
    GCTagLabel* tag = [self tagLabelAtIndex:indexOfTag];
    CGFloat occupyHeight = CGRectGetHeight(tag.frame)+tag.frame.origin.y;
    
    NSInteger tempRow = 1;
    CGFloat h = [GCTagList heightOfRows:tempRow];
    while (h != occupyHeight) {
        tempRow++;
        h = [GCTagList heightOfRows:tempRow];
    }
    
    row = tempRow;
    return row;
}

- (void)updateViewWithLastFrame:(CGRect)frame {
    CGFloat totalHeight = CGRectGetHeight(frame) + frame.origin.y;
    
    if(CGRectGetHeight(self.frame) == totalHeight)
        return;
    
    frame = self.frame;
    frame.size.height = totalHeight;
    self.frame = frame;
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(tagList:didChangedHeight:)]) {
        [self.delegate tagList:self didChangedHeight:totalHeight];
    }
}

#pragma mark - (Animation)
- (void)layoutTagLabelsWithRange:(NSRange)range animation:(BOOL)animated {
    NSInteger numberOfTagLabel = [self.dataSource numberOfTagLabelInTagList:self];
    NSInteger startIndex = range.location;
    NSInteger endIndex = startIndex + range.length;
    
    
    if(endIndex > numberOfTagLabel) {
        GCLog(@"the range is error.");
        return;
    }
    
    
    NSInteger maxRow = 0, nowRow = 1;
    if([self.dataSource respondsToSelector:@selector(maxNumberOfRowAtTagList:)]) {
        maxRow = [self.dataSource maxNumberOfRowAtTagList:self];
    }
    
    if (startIndex > 0) {
        nowRow = [self rowOfLabelAtIndex:startIndex-1];
    }
    
    GCTagLabelAccessoryType groupType = GCTagLabelAccessoryNone;
    if([self.dataSource respondsToSelector:@selector(accessoryTypeForGroupTagLabel)]) {
        groupType = [self.dataSource accessoryTypeForGroupTagLabel];
    }
    
    NSMutableArray* animationTags;
    NSMutableArray* values;
    if(animated) {
        animationTags = [NSMutableArray arrayWithCapacity:range.length];
        values = [NSMutableArray arrayWithCapacity:range.length];
    }
    
    CGRect preTagLabelFrame = CGRectZero;
    for (int i = startIndex; i < endIndex; i++) {
        /**
         * if there is previous label, get the previous's frame.
         */
        if(CGRectEqualToRect(preTagLabelFrame, CGRectZero)) {
            preTagLabelFrame = i - 1 >= 0 ? [self tagLabelAtIndex:i-1].frame : CGRectZero;
        }
        GCTagLabel* tag = (([self.dataSource tagList:self tagLabelAtIndex:i]));
        if(animated) {
            tag.alpha = 0;
        }
        if(tag.maxWidthFitToListWidth)
            tag.maxWidth = CGRectGetWidth(self.frame);
        
        [tag reSizeLabel];
        [tag setValue:[NSString stringWithFormat:@"%d",i] forKeyPath:@"index"];
        
        [self addTappedTarget:tag];
        CGRect viewFrame = tag.frame;
        
        BOOL needsGoNextRow = [self needsGoToTheNextRowWidthFrame:viewFrame
                                                         preFrame:preTagLabelFrame];
        
        CGFloat leftMargin = CGRectGetWidth(preTagLabelFrame) == 0.f ? self.firstRowLeftMargin : 0;
        CGFloat labelMargin = CGRectGetWidth(preTagLabelFrame) == 0.f ? 0 : LABEL_MARGIN;
        if (needsGoNextRow) {
            if(CGRectGetWidth(preTagLabelFrame) > 0.f && maxRow > 0) {
                nowRow ++;
                if(nowRow > maxRow)  {
                    [self addTagLabelToReuseSet:tag];
                    tag = nil;
                    tag = [self tagLabelForInterruptIndex:i];
                    viewFrame = tag.frame;
                } else {
                    viewFrame.origin = CGPointMake(0,
                                                   preTagLabelFrame.origin.y +
                                                   CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
                }
            }
            else {
                viewFrame.origin = CGPointMake(0,
                                               preTagLabelFrame.origin.y +
                                               CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
            }
        } else {
            viewFrame.origin = CGPointMake(leftMargin + preTagLabelFrame.origin.x + preTagLabelFrame.size.width + labelMargin ,
                                           preTagLabelFrame.origin.y);
        }
        tag.frame = viewFrame;
        [self addSubview:tag];
        
        if(animated) {
            [values addObject:[NSValue valueWithCGRect:viewFrame]];
            viewFrame.origin.y -= 10;
            tag.frame = viewFrame;
            viewFrame.origin.y += 10;
            [animationTags addObject:tag];
        }
        
        [self.visibleSet addObject:tag];
        preTagLabelFrame = viewFrame;
        if(maxRow > 0 && nowRow > maxRow) {
            break;
        }
    }
    
    if(animated) {
        [UIView animateWithDuration:0.33f animations:^ {
            for (int i = 0; i < values.count ; i++) {
                CGRect frame = [[values objectAtIndex:i] CGRectValue];
                GCTagLabel* tag = [animationTags objectAtIndex:i];
                tag.frame = frame;
                tag.alpha = 1.f;
            }
        }];
    }
    
    if(endIndex < numberOfTagLabel) {
        NSRange layoutRange = NSMakeRange(endIndex, numberOfTagLabel - endIndex);
        preTagLabelFrame = [self layoutAndGetLastFrameWithRange:layoutRange
                                                       rowRange:NSMakeRange(nowRow, maxRow)
                                                       animated:animated
                                                      lastFrame:preTagLabelFrame];
    }
    
    for (NSString* key in [self.reuseSet allKeys]) {
        NSMutableSet *set = [self.reuseSet objectForKey:key];
        [set minusSet:self.visibleSet];
        [self.reuseSet setObject:set forKey:key];
    }
    
    
    [self updateViewWithLastFrame:preTagLabelFrame];
}

- (CGRect)layoutAndGetLastFrameWithRange:(NSRange)range
                                rowRange:(NSRange)rowRange
                                animated:(BOOL)animated
                               lastFrame:(CGRect)lastframe {
    
    NSInteger maxRow = rowRange.length, nowRow = rowRange.location;
    NSInteger total = range.location + range.length;
    /**
     * maxRow default 0, it means not limit maxRow.
     */
    if(nowRow > maxRow && maxRow > 0) {
        for (int i = range.location; i < total ; i++) {
            GCTagLabel* tag = [self tagLabelAtIndex:i];
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
        return range.location > 0 ? [self tagLabelAtIndex:range.location-1].frame : CGRectZero;
    }
    
    CGRect viewFrame, preframe = lastframe;
    NSInteger currentIndex = range.location;
    
    NSMutableArray* moveTag = [NSMutableArray array];
    
    for (int i = currentIndex; i < total ; i++) {
        
        if (i == currentIndex && CGRectEqualToRect(lastframe, CGRectNull)) {
            preframe = i - 1 >= 0 ? [self tagLabelAtIndex:i-1].frame : CGRectZero;
        } else if(i > currentIndex) {
            preframe = [[[moveTag lastObject] objectForKey:@"frame"] CGRectValue];
        }
        
        GCTagLabel* tag = [self tagLabelAtIndex:i];
        viewFrame = tag.frame;
        
        if (i == currentIndex) {
            CGFloat dy = ABS(viewFrame.origin.y - preframe.origin.y);
            if(dy == 10.f) {
                viewFrame.origin.y = preframe.origin.y;
            }
        }
        
        BOOL needsGoNextRow = [self needsGoToTheNextRowWidthFrame:viewFrame
                                                         preFrame:preframe];
        
        CGFloat leftMargin = CGRectGetWidth(preframe) == 0.f ? self.firstRowLeftMargin : 0;
        CGFloat labelMargin = CGRectGetWidth(preframe) == 0.f ? 0 : LABEL_MARGIN;
        if (needsGoNextRow) {
            if(CGRectGetWidth(preframe) > 0.f && maxRow > 0) {
                nowRow ++;
                if(nowRow > maxRow)  {
                    [self addTagLabelToReuseSet:tag];
                    tag = nil;
                    tag = [self tagLabelForInterruptIndex:i];
                    viewFrame = tag.frame;
                } else {
                    viewFrame.origin = CGPointMake(0,
                                                   preframe.origin.y +
                                                   CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
                }
            }
            else {
                viewFrame.origin = CGPointMake(0,
                                               preframe.origin.y +
                                               CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
            }
        } else {
            viewFrame.origin = CGPointMake(leftMargin + preframe.origin.x + preframe.size.width + labelMargin ,
                                           preframe.origin.y);
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSValue valueWithCGRect:viewFrame], @"frame",
                             tag, @"target"
                             , nil];
        
        [moveTag addObject:dict];
        
        preframe = viewFrame;
    }
    
    if(!animated) {
        for (NSDictionary *dict in moveTag) {
            GCTagLabel* tag = [dict objectForKey:@"target"];
            tag.frame = [[dict objectForKey:@"frame"] CGRectValue];
        }
    } else {
        [UIView animateWithDuration:.33f
                         animations:^{
                             for (NSDictionary *dict in moveTag) {
                                 GCTagLabel* tag = [dict objectForKey:@"target"];
                                 tag.frame = [[dict objectForKey:@"frame"] CGRectValue];
                             }
                         }];
    }
    
    if(CGRectEqualToRect(preframe, CGRectNull)) {
        preframe = currentIndex > 0 ? [self tagLabelAtIndex:currentIndex-1].frame : CGRectZero;
    }
    
    return preframe;
}

#pragma mark -
#pragma mark UITouch
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* aTouch = [touches anyObject];
    if(aTouch.tapCount == 1) {
        NSInteger nowSelected = NSNotFound;
        CGPoint point = [aTouch locationInView:self];
        for (GCTagLabel* tagLabel in [self.visibleSet allObjects]) {
            NSInteger indexForTagLabel = [[tagLabel valueForKeyPath:@"index"] integerValue];
            if(indexForTagLabel == self.nowSelected && self.nowSelected!=NSNotFound) {
                [tagLabel setSelected:NO animation:NO];
                self.nowSelected = NSNotFound;
                if(nowSelected != NSNotFound) {
                    self.nowSelected = nowSelected;
                    break;
                }
            }
            
            
            if(CGRectContainsPoint(tagLabel.frame, point)) {
                nowSelected = indexForTagLabel;
                [tagLabel setSelected:YES animation:NO];
                if(self.delegate && [self.delegate respondsToSelector:@selector(tagList:didSelectedLabelAtIndex:)]) {
                    [self.delegate tagList:self
                   didSelectedLabelAtIndex:nowSelected];
                }
                if(self.nowSelected==NSNotFound) {
                    
                    self.nowSelected = nowSelected;
                    break;
                }
            }
        }
    }
}
@end

@implementation GCTagList (AbstractHeight)
+ (CGFloat)heightInTagListWithFirstRowLeftMargin:(CGFloat)leftMargin
                                     tagListWith:(CGFloat)tagListWith
                                tagLabelMaxWidth:(CGFloat)tagLabelMaxWidth
                                    tagLabelText:(NSArray *)texts {
    CGFloat height = 0;
    CGRect preLabelFrame = CGRectZero;
    for (NSString* text in texts) {
        CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:LabelDefaultFontSize]
                           constrainedToSize:CGSizeMake(9999, 9999)
                               lineBreakMode:NSLineBreakByWordWrapping];
        textSize.width += LabelHorizontalPadding * 2;
        textSize.height += LabelVerticalPadding * 2;
        BOOL needCorrection =( (textSize.width ) > tagLabelMaxWidth );
        if(needCorrection) {
            textSize.width = tagLabelMaxWidth;
        }
        CGRect tagLabelFrame;
        tagLabelFrame.origin = CGPointZero;
        tagLabelFrame.size = textSize;
        
        leftMargin = CGRectGetWidth(preLabelFrame) == 0.f ? leftMargin : 0;
        if (leftMargin + preLabelFrame.origin.x + preLabelFrame.size.width + CGRectGetWidth(tagLabelFrame) + LABEL_MARGIN
            > tagListWith) {
            tagLabelFrame.origin = CGPointMake(0, preLabelFrame.origin.y + CGRectGetHeight(tagLabelFrame) + BOTTOM_MARGIN);
        } else {
            tagLabelFrame.origin = CGPointMake(leftMargin + preLabelFrame.origin.x + preLabelFrame.size.width + LABEL_MARGIN , preLabelFrame.origin.y);
        }
        preLabelFrame = tagLabelFrame;
    }
    height = CGRectGetHeight(preLabelFrame) + preLabelFrame.origin.y;
    
    return height;
}


+ (NSInteger)rowOfTagListWithFirstRowLeftMargin:(CGFloat)leftMargin
                                    tagListWith:(CGFloat)tagListWith
                               tagLabelMaxWidth:(CGFloat)tagLabelMaxWidth
                                   tagLabelText:(NSArray*)texts {
    NSInteger row = 1;
    CGRect preLabelFrame = CGRectZero;
    for (NSString* text in texts) {
        CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:LabelDefaultFontSize]
                           constrainedToSize:CGSizeMake(9999, 9999)
                               lineBreakMode:NSLineBreakByWordWrapping];
        textSize.width += LabelHorizontalPadding * 2;
        textSize.height += LabelVerticalPadding * 2;
        BOOL needCorrection =( (textSize.width ) > tagLabelMaxWidth );
        if(needCorrection) {
            textSize.width = tagLabelMaxWidth;
        }
        CGRect tagLabelFrame;
        tagLabelFrame.origin = CGPointZero;
        tagLabelFrame.size = textSize;
        
        leftMargin = CGRectGetWidth(preLabelFrame) == 0.f ? leftMargin : 0;
        if (leftMargin + preLabelFrame.origin.x + preLabelFrame.size.width + CGRectGetWidth(tagLabelFrame) + LABEL_MARGIN
            > tagListWith) {
            tagLabelFrame.origin = CGPointMake(0, preLabelFrame.origin.y + CGRectGetHeight(tagLabelFrame) + BOTTOM_MARGIN);
            row++;
        } else {
            tagLabelFrame.origin = CGPointMake(leftMargin + preLabelFrame.origin.x + preLabelFrame.size.width + LABEL_MARGIN , preLabelFrame.origin.y);
        }
        preLabelFrame = tagLabelFrame;
    }
    
    return row;
}

+ (CGFloat)heightOfRows:(NSInteger)numberOfRow {
    NSString* text = @"I'm Sample.";
    CGSize textSize = [text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:LabelDefaultFontSize]
                       constrainedToSize:CGSizeMake(9999, 9999)
                           lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = (textSize.height+LabelVerticalPadding*2)*numberOfRow;
    height += (BOTTOM_MARGIN * (numberOfRow-1));
    return height;
}
@end

#pragma mark -
#pragma mark ===GCTagLabel===

#define DEFAULT_LABEL_BACKGROUND_COLOR [UIColor lightGrayColor]
#define DEFAULT_LABEL_TEXT_COLOR [UIColor blackColor]
#define LABEL_CORNER_RADIUS 12.f
#define LABEL_FONT_SIZE 13.f
#define HORIZONTAL_PADDING 7.0f
#define VERTICAL_PADDING 3.0f
#define ACCESSORYVIEW_WIDTH 24.f
#define ACCESSORY_SIZE CGSizeMake(40, 40)

#pragma mark -
CGFloat const LabelDefaultFontSize = LABEL_FONT_SIZE;
CGFloat const LabelHorizontalPadding = HORIZONTAL_PADDING;
CGFloat const LabelVerticalPadding = VERTICAL_PADDING;

NSString* imageFontNameForType(GCTagLabelAccessoryType type) {
    NSString* imageFontName;
    
    switch (type) {
        case GCTagLabelAccessoryArrowSign:
            imageFontName = @"CGTagList.bundle/blue_arrow.png";
            break;
        case GCTagLabelAccessoryCrossSign:
            imageFontName = @"CGTagList.bundle/blue_close.png";
            break;
        default:
            imageFontName = nil;
            break;
    }
    
    return imageFontName;
}

CGFloat imageFontLeftInsetForType(GCTagLabelAccessoryType type) {
    CGFloat imageFontLeftInset = 0;
    
    switch (type) {
        case GCTagLabelAccessoryArrowSign:
            imageFontLeftInset = 10;
            break;
        case GCTagLabelAccessoryCrossSign:
            imageFontLeftInset = 9;
            break;
        default:
            imageFontLeftInset = 0;
            break;
    }
    
    return imageFontLeftInset;
}

@interface GCTagLabel () {
    BOOL _selected;
}
@property (nonatomic, GC_STRONG) CAGradientLayer *gradientLayer;
@property (nonatomic, GC_STRONG) UILabel* label;
@property (nonatomic, GC_STRONG) UIButton* accessoryButton;
@property (nonatomic, GC_STRONG) NSString* privateReuseIdentifier;
@property (assign) NSInteger index;
@end

@implementation GCTagLabel

+ (GCTagLabel*)tagLabelWithReuseIdentifier:(NSString *)identifier {
    GCTagLabel *tag = GC_AUTORELEASE([[GCTagLabel alloc] initReuseIdentifier:identifier]);
    return tag;
}

- (void)dealloc {
    // public property
    self.labelBackgroundColor = nil;
    self.labelTextColor = nil;
    
    // private property
    self.gradientLayer = nil;
    self.label = nil;
    self.accessoryButton = nil;
    self.privateReuseIdentifier = nil;
#if !GC_SUPPORT_ARC
    [super dealloc];
#endif
}

- (id)initReuseIdentifier:(NSString *)identifier {
    self = [super init];
    if(self) {
        _selected = NO;
        self.maxWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        self.maxWidthFitToListWidth = YES;
        self.selectedEnabled = YES;
        self.privateReuseIdentifier = identifier;
        self.fitSize = CGSizeMake(self.maxWidth, 1500);
        self.labelTextColor = DEFAULT_LABEL_TEXT_COLOR;
        self.labelBackgroundColor = DEFAULT_LABEL_BACKGROUND_COLOR;
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.cornerRadius = LABEL_CORNER_RADIUS;
        self.gradientLayer.borderWidth = .8f;
        [self.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return self;
}

- (void)setLabelText:(NSString *)text accessoryType:(GCTagLabelAccessoryType)type {
    self.backgroundColor = [UIColor clearColor];
    self.accessoryType = type;
    
    if(!self.label) {
        self.label = GC_AUTORELEASE([[UILabel alloc] init]);
        self.label.textAlignment = 1;
        self.label.textColor = self.labelTextColor;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.font = [UIFont fontWithName:@"HelveticaNeue" size:LABEL_FONT_SIZE];
        [self addSubview:self.label];
    }
    self.label.text = text;
    
    if(type == GCTagLabelAccessoryNone) {
        [self.accessoryButton removeFromSuperview];
        self.accessoryButton = nil;
    } else if (type != GCTagLabelAccessoryNone && !self.accessoryButton) {
        self.accessoryButton = GC_AUTORELEASE([[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)]);
        [self.accessoryButton setImage:[UIImage imageNamed:imageFontNameForType(type)]
                              forState:UIControlStateNormal];
        self.accessoryButton.imageEdgeInsets = UIEdgeInsetsMake(0,
                                                                imageFontLeftInsetForType(type),
                                                                0,
                                                                0);
        self.accessoryButton.imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.accessoryButton];
    }
}

- (NSString*)reuseIdentifier {
    return self.privateReuseIdentifier;
}

- (void)setSelected:(BOOL)selected animation:(BOOL)animated{
    _selected = selected;
    if(!self.selectedEnabled) {
        return;
    }
    NSArray* colorsArray = !selected ?
    [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[self.labelBackgroundColor CGColor], nil] :
    [NSArray arrayWithObjects:(id)[DEFAULT_LABEL_BACKGROUND_COLOR CGColor], (id)[self.labelBackgroundColor CGColor], nil] ;
    
    if(!animated) {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        self.gradientLayer.colors = colorsArray;
        [CATransaction commit];
    } else {
        [CATransaction begin];
        [CATransaction setAnimationDuration:.3f];
        self.gradientLayer.colors = colorsArray;
        [CATransaction commit];
    }
}

- (void)didMoveToSuperview {
    if(![self.superview isKindOfClass:[GCTagList class]]) {
        CGRect rect = self.frame;
        [self reSizeLabel];
        CGRect frame = self.frame;
        frame.origin = rect.origin;
        self.frame = frame;
    }
}

@end

@implementation GCTagLabel (Private)
+ (CGRect)rectangleOfTagLabelWithText:(NSString*)textStr
                             maxWidth:(CGFloat)maxWidth
                        accessoryType:(GCTagLabelAccessoryType)type {
    CGSize textSize = [textStr sizeWithFont:[UIFont systemFontOfSize:LabelDefaultFontSize]
                          constrainedToSize:CGSizeMake(9999, 9999)
                              lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat deviationValue = type != GCTagLabelAccessoryNone ? 24 : 0;
    BOOL needCorrection =( (textSize.width + deviationValue + LabelHorizontalPadding * 2) > maxWidth );
    if(needCorrection) {
        textSize.width = maxWidth - LabelHorizontalPadding * 2 - deviationValue ;
    }
    
    
    CGRect labelFrame;
    labelFrame.origin = CGPointMake(LabelHorizontalPadding, 0);
    CGRect buttonFrame = CGRectZero;
    if(type != GCTagLabelAccessoryNone) {
        CGPoint buttonPoint = CGPointZero;
        
        buttonPoint.x = textSize.width + LabelHorizontalPadding;
        if(!needCorrection)
            buttonPoint.x -= 9;
        buttonPoint.y = (textSize.height - 24) / 2 ;
        
        buttonFrame = CGRectMake(0, 0, 24, 24);
        buttonFrame.origin = buttonPoint;
    }
    labelFrame.size = textSize;
    
    CGFloat viewWidth;
    if(!CGRectEqualToRect(buttonFrame, CGRectZero))
        viewWidth = buttonFrame.origin.x + CGRectGetWidth(buttonFrame);
    else
        viewWidth = labelFrame.origin.x + CGRectGetWidth(labelFrame);
    
    viewWidth += LabelHorizontalPadding;
    //===========
    CGRect viewFrame = CGRectZero;
    viewFrame.size.width = viewWidth;
    viewFrame.size.height = textSize.height;
    return viewFrame;
}

+ (CGRect)rectangleOfTagLabelWithText:(NSString*)textStr
                        labelMaxWidth:(CGFloat)maxWidth
                            labelFont:(UIFont*)font
                        accessoryType:(GCTagLabelAccessoryType)type {
    CGSize textSize = [textStr sizeWithFont:font
                          constrainedToSize:CGSizeMake(9999, 9999)
                              lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat deviationValue = type != GCTagLabelAccessoryNone ? 24 : 0;
    BOOL needCorrection =( (textSize.width + deviationValue + LabelHorizontalPadding * 2) > maxWidth );
    if(needCorrection) {
        textSize.width = maxWidth - LabelHorizontalPadding * 2 - deviationValue ;
    }
    
    
    CGRect labelFrame;
    labelFrame.origin = CGPointMake(LabelHorizontalPadding, 0);
    CGRect buttonFrame = CGRectZero;
    if(type != GCTagLabelAccessoryNone) {
        CGPoint buttonPoint = CGPointZero;
        
        buttonPoint.x = textSize.width + LabelHorizontalPadding;
        if(!needCorrection)
            buttonPoint.x -= 9;
        buttonPoint.y = (textSize.height - 24) / 2 ;
        
        buttonFrame = CGRectMake(0, 0, 24, 24);
        buttonFrame.origin = buttonPoint;
    }
    labelFrame.size = textSize;
    
    CGFloat viewWidth;
    if(!CGRectEqualToRect(buttonFrame, CGRectZero))
        viewWidth = buttonFrame.origin.x + CGRectGetWidth(buttonFrame);
    else
        viewWidth = labelFrame.origin.x + CGRectGetWidth(labelFrame);
    
    viewWidth += LabelHorizontalPadding;
    //===========
    CGRect viewFrame = CGRectZero;
    viewFrame.size.width = viewWidth;
    viewFrame.size.height = textSize.height;
    return viewFrame;
}

- (void)reSizeLabel {
    CGSize textSize = [self.label.text sizeWithFont:self.label.font
                       constrainedToSize:self.fitSize
                           lineBreakMode:NSLineBreakByWordWrapping];
    textSize.height += VERTICAL_PADDING * 2;
    //===========
    CGFloat deviationValue = self.accessoryType != GCTagLabelAccessoryNone ? 24 : 0;
    BOOL needCorrection =( (textSize.width + deviationValue + HORIZONTAL_PADDING * 2) > self.maxWidth );
    if(needCorrection) {
        textSize.width = self.maxWidth - HORIZONTAL_PADDING * 2 - deviationValue ;
    }
    
    
    CGRect labelFrame;
    labelFrame.origin = CGPointMake(HORIZONTAL_PADDING, 0);
    
    if(self.accessoryType != GCTagLabelAccessoryNone) {
        CGPoint buttonPoint = CGPointZero;
        
        buttonPoint.x = textSize.width + HORIZONTAL_PADDING;
        if(!needCorrection)
            buttonPoint.x -= 9;
        buttonPoint.y = (textSize.height - 24) / 2 ;
        
        CGRect buttonFrame = self.accessoryButton.frame;
        buttonFrame.origin = buttonPoint;
        self.accessoryButton.frame = buttonFrame;
    }
    labelFrame.size = textSize;
    self.label.textAlignment = needCorrection ? 0 : 1;
    self.label.frame = labelFrame;
    
    CGFloat viewWidth;
    if(self.accessoryButton)
        viewWidth = self.accessoryButton.frame.origin.x + CGRectGetWidth(self.accessoryButton.frame);
    else
        viewWidth = self.label.frame.origin.x + CGRectGetWidth(self.label.frame);
    
    viewWidth += HORIZONTAL_PADDING;
    //===========
    CGRect viewFrame = CGRectZero;
    viewFrame.size.width = viewWidth;
    viewFrame.size.height = textSize.height;
    self.frame = viewFrame;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    self.gradientLayer.frame = self.bounds;
    self.gradientLayer.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[self.labelBackgroundColor CGColor], nil];
    self.gradientLayer.borderColor = self.labelBackgroundColor.CGColor;
    [CATransaction commit];
}

@end