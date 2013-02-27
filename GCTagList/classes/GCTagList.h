//
//  CGTagLabelList.h
//  GCTagLabelList
//
//  Created by Green on 13/2/7.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#ifndef GC_SUPPORT_ARC
    #if __has_feature(objc_arc)
        #define GC_SUPPORT_ARC 1
    #else
        #define GC_SUPPORT_ARC 0
    #endif
#endif

#ifndef GC_STRONG
    #if GC_SUPPORT_ARC
        #define GC_STRONG strong
    #else
        #define GC_STRONG retain
    #endif
#endif

#ifndef GC_WEAK
    #if GC_SUPPORT_ARC
        #define GC_WEAK weak
    #elif __has_feature(objc_arc)
        #define GC_WEAK unsafe_unretained
    #else
        #define GC_WEAK assign
    #endif
#endif

#if GC_SUPPORT_ARC
    #define GC_AUTORELEASE(exp) exp
    #define GC_RELEASE(exp) exp
    #define GC_RETAIN(exp) exp
#else
    #define GC_AUTORELEASE(exp) [exp autorelease]
    #define GC_RELEASE(exp) [exp release]
    #define GC_RETAIN(exp) [exp retain]
#endif

typedef NS_ENUM(NSInteger, GCTagLabelAccessoryType) {
    GCTagLabelAccessoryNone,
    GCTagLabelAccessoryCrossFont,
    GCTagLabelAccessoryArrowFont
};


@class GCTagList, GCTagLabel;
@protocol GCTagLabelListDelegate <NSObject>
@optional
/**
 * after reloadData, if the height of TagLabelList has changed, will call this method.
 */
- (void)tagList:(GCTagList *)taglist didChangedHeight:(CGFloat)newHeight;

/**
 * Tapped the TagLabel, will call this mehtod.
 */
- (void)tagList:(GCTagList *)taglist didSelectedLabelAtIndex:(NSInteger)index;

/**
 * Tapped the TagLabel's accessoryButton, will call this mehtod.
 */
- (void)tagList:(GCTagList *)tagList accessoryButtonTappedAtIndex:(NSInteger)index;
@end

@protocol GCTagLabelListDataSource <NSObject>

/**
 * how many count for taglist to display.
 */
- (NSInteger)numberOfTagLabelInTagList:(GCTagList*)tagList;

/**
 * the taglabel At index in the taglist.
 */
- (GCTagLabel*)tagList:(GCTagList*)tagList tagLabelAtIndex:(NSInteger)index;

@end

@interface GCTagList : UIView
@property (nonatomic, GC_WEAK) id<GCTagLabelListDelegate> delegate;
@property (nonatomic, GC_WEAK) id<GCTagLabelListDataSource> dataSource;
@property (assign) CGFloat firstRowLeftMargin;
/**
 * get a taglabel, if the reuse set has no taglabel, return nil.
 */
- (GCTagLabel*)dequeueReusableTagLabelWithIdentifier:(NSString*)identifier;

/**
 * show taglist's taglabel.
 */
- (void)reloadData;

/**
 * 
 */
- (void)deselectedLabelAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

@interface GCTagList (AbstractHeight)

/**
 * Only support TagLabelAccessoryType = GCTagLabelAccessoryNone.
 */
+ (CGFloat)heightInTagListWithFirstRowLeftMargin:(CGFloat)leftMargin
                                     tagListWith:(CGFloat)tagListWith
                                tagLabelMaxWidth:(CGFloat)tagLabelMaxWidth
                                    tagLabelText:(NSArray*)texts;
@end
