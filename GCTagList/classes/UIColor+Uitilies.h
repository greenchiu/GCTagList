//
//  UIColor+Uitilies.h
//  GCTagList
//
//  Created by Chiou Green on 13/9/5.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

//  reference https://github.com/nicklockwood/ColorUtils

#import <UIKit/UIKit.h>

@interface UIColor (Uitilies)
+ (UIColor *)colorWithString:(NSString*)colorString;
- (UIColor *)darken:(CGFloat)percent;
- (UIColor *)lighten:(CGFloat)percent;
@end
