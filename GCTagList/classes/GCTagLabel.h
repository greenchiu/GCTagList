//
//  GCTagLabel.h
//  GCTagLabelList
//
//  Created by Green on 13/2/8.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCTagList.h"

extern CGFloat const LabelDefaultFontSize;
extern CGFloat const LabelHorizontalPadding;
extern CGFloat const LabelVerticalPadding;

@interface GCTagLabel : UIView

@property (nonatomic, readonly, copy) NSString* reuseIdentifier;

@property (nonatomic, GC_STRONG) UIColor *labelTextColor;

@property (nonatomic, GC_STRONG) UIColor *labelBackgroundColor;

@property (assign) GCTagLabelAccessoryType accessoryType;

@property (readonly) BOOL selected;

/**
 * 
 */
@property (assign) CGSize fitSize;

/**
 * Limit TagLabel's max width, default is CGRectGetWidth([UIScreen mainScreen].bounds)
 */
@property (assign) CGFloat maxWidth;

+ (GCTagLabel*)tagLabelWithReuseIdentifier:(NSString*)identifier;

- (id)initReuseIdentifier:(NSString*)identifier;

- (void)setLabelText:(NSString*)text accessoryType:(GCTagLabelAccessoryType)type;

- (void)setSelected:(BOOL)selected animation:(BOOL)animated;
@end
