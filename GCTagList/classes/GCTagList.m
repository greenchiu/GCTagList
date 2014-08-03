//
//  CGTagLabelList.m
//  GCTagLabelList
//
//  Created by Green on 13/2/7.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "GCTagList.h"

#ifndef GC_BLOCK_WEAK
    #if __has_feature(objc_arc_weak)
        #define GC_BLOCK_WEAK __weak
    #elif __has_feature(objc_arc)
        #define GC_BLOCK_WEAK __unsafe_unretained
    #else
        #define GC_BLOCK_WEAK __block
    #endif
#endif

#define LABEL_MARGIN 2.0f
#define BOTTOM_MARGIN 5.0f 
#define ANIMATION_DELTA_Y_DISTANCE 10.f

#if DEBUG==1
#define GCLog(fmt, ...) NSLog((@"[GCLog]:"fmt), ##__VA_ARGS__)
#else
#define GCLog(fmt, ...) 
#endif

typedef struct {
    NSInteger nowRow;
    NSInteger maxRow;
} GCTagListRowRange ;

GCTagListRowRange GCTagListRowRangeMake(NSInteger nowRow, NSInteger maxRow) {
    GCTagListRowRange rowRange;
    rowRange.nowRow = nowRow;
    rowRange.maxRow = maxRow;
    return rowRange;
}

@interface GCTagList ()
@property (nonatomic, GC_STRONG) NSMutableSet *visibleSet;
@property (nonatomic, GC_STRONG) NSMutableDictionary *reuseSet;
@property (assign) CGFloat rowMaxWidth __deprecated;
@property (assign) NSInteger nowSelected;

- (BOOL)checkImplementDataSourceRequireMehtod;

/** add taglabel to resue set, if tag has not identifier, the tag will be release. */
- (void)addTagLabelToReuseSet:(GCTagLabel *)tag;

/** if taglabel has accessoryButton, add Target will touchupindex for accessoryButton. */
- (void)addTappedTarget:(GCTagLabel *)tag;

- (void)handleTouchUpInsideTagAccessoryButton:(UIButton *)sender;

/**
 * if maxRow > 0, and the taglabel's row > maxRow, use this method to find the taglabel which one is the group label.
 */
- (GCTagLabel *)tagLabelForInterruptIndex:(NSInteger)startIndex;

/** if tag needs go the next row, return YES. */
- (BOOL)needsGoToTheNextRowWidthFrame:(CGRect)frame preFrame:(CGRect)preFrame;

/** get row of label located. */
- (NSInteger)rowOfLabelAtIndex:(NSInteger)indexOfTag;

/** update taglist's frame. */
- (void)updateViewWithLastFrame:(CGRect)frame;

/** layout taglabel with range; */
- (void)layoutTagLabelsWithRange:(NSRange)range animation:(BOOL)animated;

- (CGRect)layoutAndGetLastFrameWithRange:(NSRange)range
                                rowRange:(GCTagListRowRange *)rowRange
                                animated:(BOOL)animated
                               lastFrame:(CGRect)lastframe;

- (GCTagLabel *)layoutSingleTag:(GCTagLabel *)tag
                        atIndex:(NSInteger)index
                       rowRange:(GCTagListRowRange *)rowRange
                    preTagFrame:(CGRect)preFrame;
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
    self.nowSelected = NSNotFound;
    self.firstRowLeftMargin = 0.f;
    self.backgroundColor = [UIColor clearColor];
    self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
    self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
    
    if(self.dataSource) {
        [self reloadData];
    }
}

- (id)init {
    self = [super init];
    if(self) {
        self.nowSelected = NSNotFound;
        self.firstRowLeftMargin = 0.f;
        self.backgroundColor = [UIColor clearColor];
        self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.nowSelected = NSNotFound;
        self.firstRowLeftMargin = 0.f;
        self.backgroundColor = [UIColor clearColor];
        self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
    }
    return self;
}

#pragma mark - Public mehtod
- (GCTagLabel *)dequeueReusableTagLabelWithIdentifier:(NSString *)identifier {
    GCTagLabel *tag = nil;
    
    NSMutableSet *tempSet = (NSMutableSet*)[self.reuseSet objectForKey:identifier];
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

- (GCTagLabel *)tagLabelAtIndex:(NSInteger)index {
    GCTagLabel *tagLabel = nil;
    for (GCTagLabel *tempLabel in [self.visibleSet allObjects]) {
        NSInteger indexForTagLabel = [[tempLabel valueForKeyPath:@"index"] integerValue];
        if(index == indexForTagLabel) {
            tagLabel = tempLabel;
            break;
        }
    }
    return tagLabel;
}

- (void)reloadData {
    if (![self checkImplementDataSourceRequireMehtod]) {
        return;
    }
    
    for (GCTagLabel *tag in self.subviews) {
        [tag removeFromSuperview];
        [self addTagLabelToReuseSet:tag];
    }
    
    NSInteger numberOfTagLabel = [self.dataSource numberOfTagLabelInTagList:self];
    NSRange range = NSMakeRange(0, numberOfTagLabel);
    [self layoutTagLabelsWithRange:range animation:NO];
}

- (void)deselectedLabelAtIndex:(NSInteger)index animated:(BOOL)animated {
    self.nowSelected = NSNotFound;
    for (GCTagLabel *tagLabel in [self.visibleSet allObjects]) {
        if ([[tagLabel valueForKeyPath:@"index"] integerValue] == index) {
            [tagLabel setSelected:NO animation:animated];
            break;
        }
    }
}

- (void)reloadTagLabelWithRange:(NSRange)range {
    [self reloadTagLabelWithRange:range withAnimation:NO];
}

- (void)reloadTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated {
    if (![self checkImplementDataSourceRequireMehtod]) {
        return;
    }
    
    NSInteger sIndex = range.location;
    NSInteger eIndex = sIndex + range.length;
    
    for (NSInteger i = sIndex; i < eIndex; i++) {
        GCTagLabel *tag = [self tagLabelAtIndex:i];
        if (tag) {
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
    }
    
    [self layoutTagLabelsWithRange:range
                         animation:animated];
    
}

- (void)deleteTagLabelWithRange:(NSRange)range {
    [self deleteTagLabelWithRange:range withAnimation:NO];
}

- (void)deleteTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated {
    if (![self checkImplementDataSourceRequireMehtod]) {
        return;
    }
    
    NSInteger oldCount = [self.visibleSet count];
    
    for (int i = 0; i < range.length; i++) {
        NSInteger index = i + range.location;
        GCTagLabel *tag = [self tagLabelAtIndex:index];
        
        if (tag) {
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
    }
    
    NSMutableArray *tempAry = [NSMutableArray arrayWithCapacity:oldCount-range.length];
    for (NSInteger i = range.location+range.length; i < oldCount; i++) {
        GCTagLabel *tag = [self tagLabelAtIndex:i];
        [tempAry addObject:tag];
    }
    
    for (int i = 0; i < tempAry.count; i++) {
        NSInteger newIndex = range.location + i;
        GCTagLabel *tag = [tempAry objectAtIndex:i];
        [tag setValue:[NSString stringWithFormat:@"%ld", (long)newIndex] forKeyPath:@"index"];
    }
    
    
    NSInteger totalCount = [self.dataSource numberOfTagLabelInTagList:self];
    NSRange reloadRange = NSMakeRange(range.location, totalCount - range.location);
    NSInteger maxRow = 0, nowRow;
    nowRow = [self rowOfLabelAtIndex:range.location-1];
    if ([self.dataSource respondsToSelector:@selector(maxNumberOfRowAtTagList:)]) {
        maxRow = [self.dataSource maxNumberOfRowAtTagList:self];
    }
    GCTagListRowRange rowRagne = GCTagListRowRangeMake(nowRow, maxRow);
    CGRect frame = [self layoutAndGetLastFrameWithRange:reloadRange
                                               rowRange:&rowRagne
                                               animated:animated
                                              lastFrame:CGRectNull];
    
    [self updateViewWithLastFrame:frame];
    
}

- (void)insertTagLabelWithRange:(NSRange)range {
    [self insertTagLabelWithRange:range withAnimation:NO];
}

- (void)insertTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated {
    if (![self checkImplementDataSourceRequireMehtod]) {
        return;
    }
    
    NSInteger oldCount = [self.visibleSet count];
    
    NSMutableArray *tempAry = [NSMutableArray arrayWithCapacity:0];
    for (NSInteger i = range.location; i < oldCount; i++) {
        [tempAry addObject:[self tagLabelAtIndex:i]];
    }
    
    NSInteger sIndex = range.location + range.length;
    for (int i = 0; i < tempAry.count; i++) {
        NSInteger newIndex = sIndex + i;
        GCTagLabel *tag = [tempAry objectAtIndex:i];
        [tag setValue:[NSString stringWithFormat:@"%ld", (long)newIndex] forKeyPath:@"index"];
    }
    
    [self layoutTagLabelsWithRange:range animation:animated];
}

#pragma mark - override
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView* temp = [super hitTest:point withEvent:event];
    if(temp == self) {
        return nil;
    }
    return temp;
}

#pragma mark -
#pragma mark Private
- (BOOL)checkImplementDataSourceRequireMehtod {
    if (![self.dataSource respondsToSelector:@selector(numberOfTagLabelInTagList:)] ||
        ![self.dataSource respondsToSelector:@selector(tagList:tagLabelAtIndex:)])
        return NO;
    
    return YES;
}

- (void)addTagLabelToReuseSet:(GCTagLabel *)tag {
    if (tag.reuseIdentifier) {
        NSString *string = [NSString stringWithString:tag.reuseIdentifier];
        NSMutableSet *tempSet = self.reuseSet[string];
        if (!tempSet) {
            tempSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        }
        [tempSet addObject:tag];
        [self.visibleSet minusSet:tempSet];
        [self.reuseSet setObject:tempSet forKey:string];
    }
}

- (void)addTappedTarget:(GCTagLabel *)tag {
    if (tag.accessoryType != GCTagLabelAccessoryNone) {
        UIButton *accessoryButton = [tag valueForKeyPath:@"accessoryButton"];
        if (accessoryButton.allTargets.count == 0) {
            [accessoryButton addTarget:self
                                action:@selector(handleTouchUpInsideTagAccessoryButton:)
                      forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)handleTouchUpInsideTagAccessoryButton:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(tagList:accessoryButtonTappedAtIndex:)]) {
        NSInteger index = [[(GCTagLabel *)[sender superview] valueForKeyPath:@"index"] integerValue];
        [self.delegate tagList:self accessoryButtonTappedAtIndex:index];
        sender.highlighted = NO;
    }
}

- (GCTagLabel *)tagLabelForInterruptIndex:(NSInteger)startIndex {
    
    GCTagLabelAccessoryType groupType = GCTagLabelAccessoryNone;
    if([self.dataSource respondsToSelector:@selector(accessoryTypeForGroupTagLabel)]) {
        groupType = [self.dataSource accessoryTypeForGroupTagLabel];
    }
    
    GCTagLabel *tag = nil;
    CGRect rect = CGRectZero;
    for (NSInteger i = startIndex; i > 0; i--) {
        tag = [self tagLabelAtIndex:i];
        if (!tag) {
            continue;
        }
        
        rect = (i-1)>=0 ? [self tagLabelAtIndex:(i-1)].frame : CGRectZero;
        NSString *tempText;
        if ([self.delegate respondsToSelector:@selector(tagList:labelTextForGroupTagLabel:)]) {
            tempText = [self.delegate tagList:self labelTextForGroupTagLabel:i];
        }
        else {
            tempText = @"others";
        }
        
        CGRect tempRect = [GCTagLabel rectangleOfTagLabelWithText:tempText
                                                    labelMaxWidth:tag.maxWidth
                                                        labelFont:[tag valueForKeyPath:@"label.font"]
                                                    accessoryType:groupType];
        
        if (i-1 == 0) {
            tempRect.origin.x = self.firstRowLeftMargin;
        }
        
        BOOL isNeedGoNextRow = [self needsGoToTheNextRowWidthFrame:tempRect preFrame:rect];
        if (isNeedGoNextRow) {
            [self addTagLabelToReuseSet:tag];
            [tag removeFromSuperview];
            tag = nil;
            continue;
        }
        rect = tag.frame;
        [tag setLabelText:tempText accessoryType:groupType];
        [tag performSelector:@selector(resizeLabel)];
        [self addTappedTarget:tag];
        
        CGRect frame = tag.frame;
        frame.origin = rect.origin;
        tag.frame = frame;
        break;
    }
    return tag;
}

- (BOOL)needsGoToTheNextRowWidthFrame:(CGRect)frame preFrame:(CGRect)preFrame {
    BOOL isNeed = NO;
    CGFloat leftMargin = CGRectGetWidth(preFrame) == 0.f ? self.firstRowLeftMargin : 0;
    CGFloat labelMargin = CGRectGetWidth(preFrame) == 0.f ? 0 : LABEL_MARGIN;
    CGFloat occupyWidth = leftMargin + preFrame.origin.x +
    preFrame.size.width + CGRectGetWidth(frame) + labelMargin;
    
    CGFloat rowMaxWidth = CGRectGetWidth(self.frame);
    isNeed = rowMaxWidth < occupyWidth;
    return isNeed;
}

- (NSInteger)rowOfLabelAtIndex:(NSInteger)indexOfTag {
    NSInteger row = 1;
    
    if(indexOfTag < 0) {
        return row;
    }
    
    GCTagLabel *tag = [self tagLabelAtIndex:indexOfTag];
    CGFloat occupyHeight = CGRectGetHeight(tag.frame)+tag.frame.origin.y;
    
    NSInteger tempRow = 1;
    CGFloat h = [GCTagList heightOfRows:tempRow font:self.labelFont];
    while (h <= occupyHeight) {
        tempRow++;
        h = [GCTagList heightOfRows:tempRow font:self.labelFont];
    }
    
    row = tempRow;
    return row;
}

- (void)updateViewWithLastFrame:(CGRect)frame {
    CGFloat totalHeight = CGRectGetHeight(frame) + frame.origin.y;
    
    if (CGRectGetHeight(self.frame) == totalHeight) {
        return;
    }
    
    frame = self.frame;
    frame.size.height = totalHeight;
    self.frame = frame;
    
    if ([self.delegate respondsToSelector:@selector(tagList:didChangedHeight:)]) {
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
    if ([self.dataSource respondsToSelector:@selector(maxNumberOfRowAtTagList:)]) {
        maxRow = [self.dataSource maxNumberOfRowAtTagList:self];
    }
    
    if (startIndex > 0) {
        nowRow = [self rowOfLabelAtIndex:startIndex-1];
    }
    
    GCTagLabelAccessoryType groupType = GCTagLabelAccessoryNone;
    if([self.dataSource respondsToSelector:@selector(accessoryTypeForGroupTagLabel)]) {
        groupType = [self.dataSource accessoryTypeForGroupTagLabel];
    }
    
    NSMutableArray *animationTags;
    NSMutableArray *values;
    if (animated) {
        animationTags = [NSMutableArray arrayWithCapacity:range.length];
        values = [NSMutableArray arrayWithCapacity:range.length];
    }
    
    GCTagListRowRange rowRagne = GCTagListRowRangeMake(nowRow, maxRow);
    CGRect preTagLabelFrame = CGRectZero;
    CGFloat rowMaxWidth = CGRectGetWidth(self.frame);
    for (NSInteger i = startIndex; i < endIndex; i++) {
        /**
         * if there is previous label, get the previous's frame.
         */
        if(CGRectEqualToRect(preTagLabelFrame, CGRectZero)) {
            preTagLabelFrame = i - 1 >= 0 ? [self tagLabelAtIndex:i-1].frame : CGRectZero;
        }
        GCTagLabel *tag = [self.dataSource tagList:self tagLabelAtIndex:i];
        if (animated) {
            tag.alpha = 0;
        }
        
        if (tag.maxWidthFitToListWidth) {
            tag.maxWidth = rowMaxWidth;
        }
        
        // set the font for tag's label.
        if (self.labelFont) {
            [tag setValue:self.labelFont forKeyPath:@"label.font"];
        }
        
        [tag performSelector:@selector(resizeLabel)];
        [tag setValue:[NSString stringWithFormat:@"%ld",(long)i] forKeyPath:@"index"];
        
        [self addTappedTarget:tag];
        tag = [self layoutSingleTag:tag
                            atIndex:i
                           rowRange:&rowRagne
                        preTagFrame:preTagLabelFrame];
        
        [self addSubview:tag];
        
        CGRect viewFrame = tag.frame;
        
        if (animated) {
            [values addObject:[NSValue valueWithCGRect:viewFrame]];
            viewFrame.origin.y -= ANIMATION_DELTA_Y_DISTANCE;
            tag.frame = viewFrame;
            viewFrame.origin.y += ANIMATION_DELTA_Y_DISTANCE;
            [animationTags addObject:tag];
        }
        
        [self.visibleSet addObject:tag];
        preTagLabelFrame = viewFrame;
        if ( rowRagne.maxRow > 0 && rowRagne.nowRow > rowRagne.maxRow) {
            break;
        }
    }
    
    if (animated) {
        [UIView animateWithDuration:0.33f animations:^ {
            for (int i = 0; i < values.count ; i++) {
                CGRect frame = [[values objectAtIndex:i] CGRectValue];
                GCTagLabel *tag = [animationTags objectAtIndex:i];
                tag.frame = frame;
                tag.alpha = 1.f;
            }
        }];
    }
    
    if (endIndex < numberOfTagLabel) {
        NSRange layoutRange = NSMakeRange(endIndex, numberOfTagLabel - endIndex);
        preTagLabelFrame = [self layoutAndGetLastFrameWithRange:layoutRange
                                                       rowRange:&rowRagne
                                                       animated:animated
                                                      lastFrame:preTagLabelFrame];
    }
    
    for (NSString *key in [self.reuseSet allKeys]) {
        NSMutableSet *set = [self.reuseSet objectForKey:key];
        [set minusSet:self.visibleSet];
        [self.reuseSet setObject:set forKey:key];
    }
    
    [self updateViewWithLastFrame:preTagLabelFrame];
}

- (CGRect)layoutAndGetLastFrameWithRange:(NSRange)range
                                rowRange:(GCTagListRowRange *)rowRange
                                animated:(BOOL)animated
                               lastFrame:(CGRect)lastframe {
    NSInteger total = range.location + range.length;
    /**
     * maxRow default 0, it means not limit maxRow.
     */
    if(rowRange->nowRow > rowRange->maxRow && rowRange->maxRow > 0) {
        for (NSInteger i = range.location; i < total ; i++) {
            GCTagLabel *tag = [self tagLabelAtIndex:i];
            [tag removeFromSuperview];
            [self addTagLabelToReuseSet:tag];
        }
        return range.location > 0 ? [self tagLabelAtIndex:range.location-1].frame : CGRectZero;
    }
    
    CGRect viewFrame, preframe = lastframe;
    NSInteger currentIndex = range.location;
    
    NSMutableArray *moveTag = [NSMutableArray array];
    
    for (NSInteger i = currentIndex; i < total ; i++) {
        
        if (i == currentIndex && CGRectEqualToRect(lastframe, CGRectNull)) {
            preframe = i - 1 >= 0 ? [self tagLabelAtIndex:i-1].frame : CGRectZero;
        }
        else if(i > currentIndex) {
            preframe = [[[moveTag lastObject] objectForKey:@"frame"] CGRectValue];
        }
        
        GCTagLabel *tag = [self tagLabelAtIndex:i];
        viewFrame = tag.frame;
        
        if (i == currentIndex) {
            CGFloat dy = ABS(viewFrame.origin.y - preframe.origin.y);
            if (dy == ANIMATION_DELTA_Y_DISTANCE) {
                viewFrame.origin.y = preframe.origin.y;
            }
        }
        
        tag = [self layoutSingleTag:tag
                            atIndex:i
                           rowRange:rowRange
                        preTagFrame:preframe];
        
        CGRect tmpRect = tag.frame;
        if(animated) {
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSValue valueWithCGRect:tmpRect], @"frame",
                                  tag, @"target"
                                  , nil];
        
            [moveTag addObject:dict];
            tag.frame = viewFrame;
            viewFrame = tmpRect;
        }
        viewFrame = tmpRect;
        
        preframe = viewFrame;
        if (rowRange->maxRow > 0 && rowRange->nowRow > rowRange->maxRow) {
            break;
        }
    }
    
    if(!animated) {
        for (NSDictionary *dict in moveTag) {
            GCTagLabel *tag = [dict objectForKey:@"target"];
            tag.frame = [[dict objectForKey:@"frame"] CGRectValue];
        }
    }
    else {
        [UIView animateWithDuration:.33f
                         animations:^{
                             for (NSDictionary *dict in moveTag) {
                                 GCTagLabel *tag = [dict objectForKey:@"target"];
                                 tag.frame = [[dict objectForKey:@"frame"] CGRectValue];
                             }
                         }];
    }
    
    if(CGRectEqualToRect(preframe, CGRectNull)) {
        preframe = currentIndex > 0 ? [self tagLabelAtIndex:currentIndex-1].frame : CGRectZero;
    }
    
    return preframe;
}

- (GCTagLabel *)layoutSingleTag:(GCTagLabel *)tag
                        atIndex:(NSInteger)index
                       rowRange:(GCTagListRowRange *)rowRange
                    preTagFrame:(CGRect)preFrame {
    CGRect viewFrame = tag.frame;
    
    BOOL needsGoNextRow = [self needsGoToTheNextRowWidthFrame:viewFrame
                                                     preFrame:preFrame];
    
    CGFloat leftMargin = CGRectGetWidth(preFrame) == 0.f ? self.firstRowLeftMargin : 0;
    CGFloat labelMargin = CGRectGetWidth(preFrame) == 0.f ? 0 : LABEL_MARGIN;
    if (needsGoNextRow) {
        rowRange->nowRow ++;
        if (CGRectGetWidth(preFrame) > 0.f && rowRange->maxRow > 0) {
            if (rowRange->nowRow > rowRange->maxRow)  {
                [tag removeFromSuperview];
                [self addTagLabelToReuseSet:tag];
                tag = nil;
                tag = [self tagLabelForInterruptIndex:index];
                viewFrame = tag.frame;
            }
            else {
                viewFrame.origin = CGPointMake(0,
                                               preFrame.origin.y +
                                               CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
            }
        }
        else {
            viewFrame.origin = CGPointMake(0,
                                           preFrame.origin.y +
                                           CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
        }
    } else {
        viewFrame.origin = CGPointMake(leftMargin + preFrame.origin.x + preFrame.size.width + labelMargin ,
                                       preFrame.origin.y);
    }
    tag.frame = viewFrame;
    return tag;
}

#pragma mark -
#pragma mark UITouch
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        NSInteger nowSelected = NSNotFound;
        CGPoint point = [aTouch locationInView:self];
        for (GCTagLabel *tagLabel in [self.visibleSet allObjects]) {
            NSInteger indexForTagLabel = [[tagLabel valueForKeyPath:@"index"] integerValue];
            if (indexForTagLabel == self.nowSelected && self.nowSelected!=NSNotFound) {
                [tagLabel setSelected:NO animation:NO];
                self.nowSelected = NSNotFound;
                if (nowSelected != NSNotFound) {
                    self.nowSelected = nowSelected;
                    break;
                }
            }
            
            
            if (CGRectContainsPoint(tagLabel.frame, point)) {
                nowSelected = indexForTagLabel;
                [tagLabel setSelected:YES animation:NO];
                if (self.delegate && [self.delegate respondsToSelector:@selector(tagList:didSelectedLabelAtIndex:)]) {
                    [self.delegate tagList:self
                   didSelectedLabelAtIndex:nowSelected];
                }
                
                if (self.nowSelected==NSNotFound) {
                    self.nowSelected = nowSelected;
                    break;
                }
            }
        }
    }
}
@end

@implementation GCTagList (AbstractHeight)
+ (NSInteger)rowOfTagListWithFirstRowLeftMargin:(CGFloat)leftMargin
                                    tagListWith:(CGFloat)tagListWith
                               tagLabelMaxWidth:(CGFloat)tagLabelMaxWidth
                                   tagLabelText:(NSArray *)texts {
    NSInteger row = 1;
    CGRect preLabelFrame = CGRectZero;
    for (NSString *text in texts) {
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
    return [self heightOfRows:numberOfRow
                         font:[UIFont systemFontOfSize:LabelDefaultFontSize]];
}

+ (CGFloat)heightOfRows:(NSInteger)numberOfRow font:(UIFont *)font {
    NSString *text = @"I'm Sample.";
    
    if (!font) {
        font = [UIFont systemFontOfSize:LabelDefaultFontSize];
    }
    CGSize textSize = [text sizeWithFont:font
                       constrainedToSize:CGSizeMake(9999, 9999)
                           lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = (textSize.height+LabelVerticalPadding*2)*numberOfRow;
    height += (BOTTOM_MARGIN * (numberOfRow-1));
    return height;
}
@end