//
//  UIColor+Uitilies.m
//  GCTagList
//
//  Created by Chiou Green on 13/9/5.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "UIColor+Uitilies.h"

@implementation UIColor (Uitilies)

+ (UIColor *)colorWithString:(NSString *)colorString {
    colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    colorString = [colorString stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    switch ([colorString length]) {
        case 3: {
            NSString *red = [colorString substringWithRange:NSMakeRange(0, 1)];
            NSString *green = [colorString substringWithRange:NSMakeRange(1, 1)];
            NSString *blue = [colorString substringWithRange:NSMakeRange(2, 1)];
            colorString = [NSString stringWithFormat:@"%1$@%1$@%2$@%2$@%3$@%3$@ff", red, green, blue];
            break;
        }
        case 6:
            colorString = [colorString stringByAppendingString:@"ff"];
            break;
        case 8:
            break;
        default:
            NSLog(@"[UIColor+NSString]: color string has some thing wrong.");
            colorString = @"000000ff";
            break;
    }
    uint32_t rgba;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    [scanner scanHexInt:&rgba];
    return [UIColor colorWithRed:((rgba & 0xFF000000) >> 24) / 255.f
                           green:((rgba & 0x00FF0000) >> 16) / 255.f
                            blue:((rgba & 0x0000FF00) >> 8) / 255.f
                           alpha:((rgba & 0x000000FF)) / 255.f];
}

- (UIColor *)darken:(CGFloat)percent {
    percent = percent > 1 ? 1 : percent;
    percent = percent < 0 ? 0 : percent;
    
    CGFloat rgba[4];
    [self getRGBA:rgba];
    UIColor* darkerColor = [UIColor colorWithRed:MAX(rgba[0]-percent, 0)
                                           green:MAX(rgba[1]-percent, 0)
                                            blue:MAX(rgba[2]-percent, 0)
                                           alpha:rgba[3]];
    
    return darkerColor;
    
}

- (UIColor *)lighten:(CGFloat)percent {
    percent = percent > 1 ? 1 : percent;
    percent = percent < 0 ? 0 : percent;
    CGFloat rgba[4];
    [self getRGBA:rgba];
    UIColor* lighterColor = [UIColor colorWithRed:MIN(rgba[0]+percent, 1)
                                            green:MIN(rgba[1]+percent, 1)
                                             blue:MIN(rgba[2]+percent, 1)
                                            alpha:rgba[3]];
    
    return lighterColor;
}

- (void)getRGBA:(CGFloat*)rgba {
    CGColorSpaceModel colorModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    const CGFloat* colorComponents = CGColorGetComponents( self.CGColor );
    switch (colorModel)
    {
        case kCGColorSpaceModelMonochrome:
        {
            rgba[0] = colorComponents[0];
            rgba[1] = colorComponents[0];
            rgba[2] = colorComponents[0];
            rgba[3] = colorComponents[1];
            break;
        }
        case kCGColorSpaceModelRGB:
        {
            rgba[0] = colorComponents[0];
            rgba[1] = colorComponents[1];
            rgba[2] = colorComponents[2];
            rgba[3] = colorComponents[3];
            break;
        }
        default:
        {
            
#ifdef DEBUG
            NSLog(@"Unsupported model: %i", colorModel);
#endif
            rgba[0] = 0.0f;
            rgba[1] = 0.0f;
            rgba[2] = 0.0f;
            rgba[3] = 1.0f;
            break;
        }
    }
}

@end
