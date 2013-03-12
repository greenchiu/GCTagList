//
//  GCTagLabel.m
//  GCTagLabelList
//
//  Created by Green on 13/2/8.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "GCTagLabel.h"

#define DEFAULT_LABEL_BACKGROUND_COLOR [UIColor lightGrayColor]
#define DEFAULT_LABEL_TEXT_COLOR [UIColor blackColor]
#define LABEL_CORNER_RADIUS 12.f
#define LABEL_FONT_SIZE 13.f
#define HORIZONTAL_PADDING 7.0f
#define VERTICAL_PADDING 3.0f
#define ACCESSORYVIEW_WIDTH 24.f
#define ACCESSORY_SIZE CGSizeMake(40, 40)

CGFloat const LabelDefaultFontSize = LABEL_FONT_SIZE;
CGFloat const LabelHorizontalPadding = HORIZONTAL_PADDING;
CGFloat const LabelVerticalPadding = VERTICAL_PADDING;

NSString* imageFontNameForType(GCTagLabelAccessoryType type) {
    NSString* imageFontName;
    
    switch (type) {
        case GCTagLabelAccessoryArrowFont:
            imageFontName = @"CGTagLabelList.bundle/blue_arrow";
            break;
        case GCTagLabelAccessoryCrossFont:
            imageFontName = @"CGTagLabelList.bundle/blue_close";
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
        case GCTagLabelAccessoryArrowFont:
            imageFontLeftInset = 10;
            break;
        case GCTagLabelAccessoryCrossFont:
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
    return GC_AUTORELEASE([[GCTagLabel alloc] initReuseIdentifier:identifier]);
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
        self.label.textAlignment = UITextAlignmentCenter;
        self.label.textColor = self.labelTextColor;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.font = [UIFont fontWithName:@"HelveticaNeue" size:LABEL_FONT_SIZE];
        [self addSubview:self.label];
    }
    
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
    
    CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]
                       constrainedToSize:self.fitSize
                           lineBreakMode:NSLineBreakByWordWrapping];
    textSize.height += VERTICAL_PADDING * 2;
    //===========
    CGFloat deviationValue = type != GCTagLabelAccessoryNone ? 24 : 0;
    BOOL needCorrection =( (textSize.width + deviationValue + HORIZONTAL_PADDING * 2) > self.maxWidth );
    if(needCorrection) {
        textSize.width = self.maxWidth - HORIZONTAL_PADDING * 2 - deviationValue ;
    }
    
    
    CGRect labelFrame;
    labelFrame.origin = CGPointMake(HORIZONTAL_PADDING, 0);
    
    if(type != GCTagLabelAccessoryNone) {
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
    self.label.textAlignment = needCorrection ? UITextAlignmentLeft : UITextAlignmentCenter;
    self.label.frame = labelFrame;
    self.label.text = text;
    
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

@end
