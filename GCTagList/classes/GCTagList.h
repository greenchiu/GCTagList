//
//  CGTagLabelList.h
//  GCTagLabelList
//
//  Created by Green on 13/2/7.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define gctaglist_version @"1.1"
#define update_date @"2013.04.21 12:18 +0800"

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
    GCTagLabelAccessoryCrossSign,
    GCTagLabelAccessoryArrowSign
};

@class GCTagList, GCTagLabel;

#pragma mark -
#pragma mark GCTagListDelegate
@protocol GCTagListDelegate <NSObject>
@optional
/**
 * 在reloadData, 如果TagList的高度有改變, 這個Mehtod會被觸發.
 * after reloadData, if the height of TagList has changed, will call this method.
 */
- (void)tagList:(GCTagList *)taglist didChangedHeight:(CGFloat)newHeight;

/**
 * 當點選TagLabel, 這個Method會被觸發.
 * Tapped the TagLabel, will call this mehtod.
 */
- (void)tagList:(GCTagList *)taglist didSelectedLabelAtIndex:(NSInteger)index;

/**
 * 點擊TagLabel's accessoryButton, 這個Method會被觸發.
 * Tapped the TagLabel's accessoryButton, will call this mehtod.
 */
- (void)tagList:(GCTagList *)tagList accessoryButtonTappedAtIndex:(NSInteger)index;

/**
 * 如果有實作<GCTagLabelListDataSource>的maxNumberOfRowAtTagList, 且發生需省略後續的TagLabel時會被觸發.
 * if implement protocol <GCTagLabelListDataSource> method 'maxNumberOfRowAtTagList' and the taglist's rows is more than the maxRow, this method will be call.
 * 
 * @retVal NSString the text for the TagLabel of theMaxRow's last one.
 */
- (NSString*)tagList:(GCTagList *)tagList labelTextForGroupTagLabel:(NSInteger)interruptIndex;
@end

#pragma mark -
#pragma mark GCTagListDataSource
@protocol GCTagListDataSource <NSObject>
/**
 * 在TagList中有多少個TagLabel.
 * how many count for taglist to display.
 */
- (NSInteger)numberOfTagLabelInTagList:(GCTagList*)tagList;

/**
 * 在TagList中的TagLabel.
 * the taglabel At index in the taglist.
 */
- (GCTagLabel*)tagList:(GCTagList*)tagList tagLabelAtIndex:(NSInteger)index;

@optional
/**
 * TagList最多幾行.
 * the max row at taglist.
 */
- (NSInteger)maxNumberOfRowAtTagList:(GCTagList*)tagList;

/**
 * TagList最後一行的最後一個TagLabel(Group TagLabel)的AccessoryType.
 * accessory type of the group taglabel.
 */
- (GCTagLabelAccessoryType)accessoryTypeForGroupTagLabel;
@end

#pragma mark -
#pragma mark GCTagList
@interface GCTagList : UIView
@property (nonatomic, GC_WEAK) id<GCTagListDelegate> delegate;
@property (nonatomic, GC_WEAK) id<GCTagListDataSource> dataSource;
@property (assign) CGFloat firstRowLeftMargin;

/**
 * 取得一個可以被Reuse的TagLabel實體, 如果沒有則回傳nil.
 * get a taglabel, if the reuse set has no taglabel, return nil.
 */
- (GCTagLabel*)dequeueReusableTagLabelWithIdentifier:(NSString*)identifier;

/**
 * 取得taglist第index位置上的taglabel
 * get taglabel at index of the taglist.
 */
- (GCTagLabel*)tagLabelAtIndex:(NSInteger)index;

/**
 * 載入TagLabel並顯示TagList.
 * show taglist's taglabel.
 */
- (void)reloadData;

/**
 * 取消選取TagLabel.
 * deselected TagLabel.
 */
- (void)deselectedLabelAtIndex:(NSInteger)index animated:(BOOL)animated;

/**
 *  reload taglabel with range.
 */
- (void)reloadTagLabelWithRange:(NSRange)range;

/**
 *  delete taglabel with range.
 */
- (void)deleteTagLabelWithRange:(NSRange)range;

/**
 *  insert taglabel with range.
 */
- (void)insertTagLabelWithRange:(NSRange)range;

- (void)reloadTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated;
- (void)deleteTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated;
- (void)insertTagLabelWithRange:(NSRange)range withAnimation:(BOOL)animated;

@end

@interface GCTagList (AbstractHeight)
/**
 * Only support TagLabelAccessoryType = GCTagLabelAccessoryNone.
 */
+ (NSInteger)rowOfTagListWithFirstRowLeftMargin:(CGFloat)leftMargin
                                    tagListWith:(CGFloat)tagListWith
                               tagLabelMaxWidth:(CGFloat)tagLabelMaxWidth
                                   tagLabelText:(NSArray*)texts;

/**
 * 取得高度
 * get height of rows.
 */
+ (CGFloat)heightOfRows:(NSInteger)numberOfRow;
@end

#pragma mark -
#pragma mark GCTagLabel
extern CGFloat const LabelDefaultFontSize;
extern CGFloat const LabelHorizontalPadding;
extern CGFloat const LabelVerticalPadding;

@interface GCTagLabel : UIView
@property (nonatomic, readonly, copy) NSString* reuseIdentifier;
@property (nonatomic, GC_STRONG) UIColor *labelTextColor;
@property (nonatomic, GC_STRONG) UIColor *startGradientColor;
@property (nonatomic, GC_STRONG) UIColor *endGradientColor;


@property (assign) GCTagLabelAccessoryType accessoryType;
@property (assign) BOOL selectedEnabled; // if YES, the taglabel could show selected state. default is YES.
@property (readonly) BOOL selected;
@property (assign) CGSize fitSize;

/**
 * let the maxWidth equal to the taglist's width,
 * default is YES.
 */
@property (assign) BOOL maxWidthFitToListWidth;

/**
 * Limit TagLabel's max width, default is CGRectGetWidth([UIScreen mainScreen].bounds)
 */
@property (assign) CGFloat maxWidth;
+ (GCTagLabel*)tagLabelWithReuseIdentifier:(NSString*)identifier;
- (id)initReuseIdentifier:(NSString*)identifier;
- (void)setLabelText:(NSString*)text accessoryType:(GCTagLabelAccessoryType)type;
- (void)setSelected:(BOOL)selected animation:(BOOL)animated;
@end

@interface UIColor (Uitilies)
+ (UIColor*)colorWithString:(NSString*)colorString;
- (UIColor*)darken:(CGFloat)percent;
- (UIColor*)lighten:(CGFloat)percent;
@end
