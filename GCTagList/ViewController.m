//
//  ViewController.m
//  GCTagList
//
//  Created by Green on 13/2/27.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "ViewController.h"
#import "GCTagList.h"

#define ARY @[@"Mark Wu", @"Green Chiu", @"Eikiy Chang", @"Gina Sun", @"Jeremy Chang", @"Sandra Hsu"]

@interface ViewController () <GCTagListDataSource, GCTagListDelegate>
@property (nonatomic, retain) NSMutableArray* tagNames;
@end

@implementation ViewController

- (void)loadView {
    self.tagNames = [NSMutableArray arrayWithArray:ARY];
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     * the firstRowLeftMargin default is zero.
     * the xib did not support the inspector to set custom view's property, so 
     * if you need this setting, set it and call reloadData after.
     */
    self.nibTagList.firstRowLeftMargin = 30.f;
    
    /**
     * labelfont default is nil, if you want change the font,
     * you could use this property, this could keep the font with your taglabel.  
     * use this property with xib, you should call reloadData.
     * by Green at 08/28/2013.
     */
    
    //self.nibTagList.labelFont = [UIFont systemFontOfSize:16.f];
    
    [self.nibTagList reloadData];
    
    /*
    GCTagList* taglist = [[[GCTagList alloc] initWithFrame:CGRectMake(0, 180, 320, 200)] autorelease];
    taglist.firstRowLeftMargin = 80.f;
    taglist.delegate = self;
    taglist.dataSource = self;
    [self.view addSubview:taglist];
    [taglist reloadData];
     */
}

- (NSInteger)numberOfTagLabelInTagList:(GCTagList *)tagList {
    return self.tagNames.count;
}

- (GCTagLabel*)tagList:(GCTagList *)tagList tagLabelAtIndex:(NSInteger)index {
    
    static NSString* identifier = @"TagLabelIdentifier";
    
    GCTagLabel* tag = [tagList dequeueReusableTagLabelWithIdentifier:identifier];
    if(!tag) {
        tag = [GCTagLabel tagLabelWithReuseIdentifier:identifier];

        tag.gradientColors = [GCTagLabel defaultGradoentColors];
        
        [tag setCornerRadius:6.f];
    }
    
    NSString* labelText = self.tagNames[index];
    
    /**
     * you can change the AccrssoryType with method setLabelText:accessoryType:
     * or with no accessoryButton with method setLabelText:
     */
    
    /* way 1
    GCTagLabelAccessoryType type = GCTagLabelAccessoryCrossSign;
    [tag setLabelText:labelText
        accessoryType:type];
     */
    
    //way 2
    [tag setLabelText:labelText];
    
    return tag;
}

- (void)tagList:(GCTagList *)tagList accessoryButtonTappedAtIndex:(NSInteger)index {

    /**
     * this is the delete method how to use.
     */
    /**
    [self.tagNames removeObjectsInRange:NSMakeRange(index, 2)];
    [tagList deleteTagLabelWithRange:NSMakeRange(index, 2)];
    [tagList deleteTagLabelWithRange:NSMakeRange(index, 2) withAnimation:YES];
     */
    
    
    /**
     * this is the reload method how to use.
     */
    /**
    self.tagNames[index] = @"Kim Jong Kook";
    [tagList reloadTagLabelWithRange:NSMakeRange(index, 1)];
    [tagList reloadTagLabelWithRange:NSMakeRange(index, 1) withAnimation:YES];
    
    self.tagNames[index] = @"Kim Jong Kook";
    self.tagNames[index+1] = @"Girls' Generation";
    [tagList reloadTagLabelWithRange:NSMakeRange(index, 2) withAnimation:YES];
    */
    
    /**
     * this is the insert method how to use.
     */
    [self.tagNames insertObject:@"Girls' Generation" atIndex:index];
    [self.tagNames insertObject:@"TaeTiSeo" atIndex:index];
    [tagList insertTagLabelWithRange:NSMakeRange(index, 2) withAnimation:YES];
    
}

- (void)tagList:(GCTagList *)taglist didChangedHeight:(CGFloat)newHeight {
    NSLog(@"%s:%.1f", __func__, newHeight);
}

- (NSString*)tagList:(GCTagList *)tagList labelTextForGroupTagLabel:(NSInteger)interruptIndex {
    return [NSString stringWithFormat:@"和其他%d位", self.tagNames.count - interruptIndex];
}

- (void)tagList:(GCTagList *)taglist didSelectedLabelAtIndex:(NSInteger)index {
    [taglist deselectedLabelAtIndex:index animated:YES];
}

/**
 * 
 */
//- (NSInteger)maxNumberOfRowAtTagList:(GCTagList *)tagList {
//    return 1;
//}

- (GCTagLabelAccessoryType)accessoryTypeForGroupTagLabel {
    return GCTagLabelAccessoryArrowSign;
}

@end
