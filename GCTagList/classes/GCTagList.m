//
//  CGTagLabelList.m
//  GCTagLabelList
//
//  Created by Green on 13/2/7.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "GCTagList.h"
#import "GCTagLabel.h"

#define LABEL_MARGIN 2.0f 
#define BOTTOM_MARGIN 5.0f 

@interface GCTagList ()
@property (nonatomic, GC_STRONG) NSMutableSet* visibleSet;
@property (nonatomic, GC_STRONG) NSMutableDictionary* reuseSet;
@property (assign) CGFloat rowMaxWidth;
@property (assign) NSInteger nowSelected;
@end

@implementation GCTagList

- (void)dealloc {
    self.visibleSet = nil;
    self.reuseSet = nil;
    
#if !GC_SUPPORT_ARC
    [super dealloc];
#endif
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.nowSelected = NSNotFound;
        self.firstRowLeftMargin = 0.f;
        self.rowMaxWidth = CGRectGetWidth(frame);
        self.backgroundColor = [UIColor clearColor];
        self.visibleSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
        self.reuseSet = GC_AUTORELEASE([[NSMutableDictionary alloc] init]);
    }
    return self;
}

- (GCTagLabel*)dequeueReusableTagLabelWithIdentifier:(NSString *)identifier {
    GCTagLabel* tag = nil;
    
    NSMutableSet* tempSet = (NSMutableSet*)[self.reuseSet objectForKey:identifier];
    if(tempSet) {
        tag = [tempSet anyObject];
        if(tag) {
            [tag setSelected:NO animation:NO];
            [tempSet removeObject:tag];
        }
    }
    return tag;
}

- (void)reloadData {
    if(!self.dataSource ||
       ![self.dataSource respondsToSelector:@selector(numberOfTagLabelInTagList:)] ||
       ![self.dataSource respondsToSelector:@selector(tagList:tagLabelAtIndex:)])
        return;
    
    for (GCTagLabel* tag in self.subviews) {
        [tag removeFromSuperview];
        [self.visibleSet removeObject:tag];
        if(tag.reuseIdentifier) {
            NSMutableSet* tempSet = self.reuseSet[tag.reuseIdentifier];
            if(!tempSet) {
                tempSet = GC_AUTORELEASE([[NSMutableSet alloc] init]);
            }
            [tempSet addObject:tag];
            [self.reuseSet setObject:tempSet forKey:tag.reuseIdentifier];
        }
    }
    
    NSInteger numberOfTagLabel = [self.dataSource numberOfTagLabelInTagList:self];
    
    CGRect preTagLabelFrame = CGRectZero;
    CGFloat totalHeight = 0;
    for (int i = 0; i < numberOfTagLabel; i++) {
        GCTagLabel* tag = [self.dataSource tagList:self tagLabelAtIndex:i];
        //======
        [self.visibleSet addObject:tag];
        //======
        [tag setValue:[NSString stringWithFormat:@"%d",i] forKeyPath:@"index"];
        if(tag.accessoryType != GCTagLabelAccessoryNone) {
            UIButton* accessoryButton = [tag valueForKeyPath:@"accessoryButton"];
            [accessoryButton addTarget:self
                                action:@selector(handleTouchUpInsideTagAccessoryButton:)
                      forControlEvents:UIControlEventTouchUpInside];
        }
        //======
        CGRect viewFrame = tag.frame;
        CGFloat leftMargin = CGRectGetWidth(preTagLabelFrame) == 0.f ? self.firstRowLeftMargin : 0;
        CGFloat labelMargin = CGRectGetWidth(preTagLabelFrame) == 0.f ? 0 : LABEL_MARGIN;
        if (leftMargin + preTagLabelFrame.origin.x + preTagLabelFrame.size.width + CGRectGetWidth(viewFrame) + leftMargin
            > self.rowMaxWidth) {
            viewFrame.origin = CGPointMake(0, preTagLabelFrame.origin.y + CGRectGetHeight(viewFrame) + BOTTOM_MARGIN);
        } else {
            viewFrame.origin = CGPointMake(leftMargin + preTagLabelFrame.origin.x + preTagLabelFrame.size.width + labelMargin , preTagLabelFrame.origin.y);
        }
        
        tag.frame = viewFrame;
        [self addSubview:tag];
        
        preTagLabelFrame = viewFrame;
    }
    totalHeight = CGRectGetHeight(preTagLabelFrame) + preTagLabelFrame.origin.y;
    
    if(CGRectGetHeight(self.frame) == totalHeight)
        return;
    
    CGRect frame = self.frame;
    frame.size.height = totalHeight;
    self.frame = frame;
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(tagList:didChangedHeight:)]) {
        [self.delegate tagList:self didChangedHeight:totalHeight];
    }

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


#pragma mark -
#pragma mark Private
- (void)handleTouchUpInsideTagAccessoryButton:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(tagList:accessoryButtonTappedAtIndex:)]) {
        NSInteger index = [[(GCTagLabel*)[sender superview] valueForKeyPath:@"index"] integerValue];
        [self.delegate tagList:self accessoryButtonTappedAtIndex:index];
    }
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

@end
