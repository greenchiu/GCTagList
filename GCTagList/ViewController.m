//
//  ViewController.m
//  GCTagList
//
//  Created by Green on 13/2/27.
//  Copyright (c) 2013年 greenchiu. All rights reserved.
//

#import "ViewController.h"
#import "GCTagList.h"
#import "GCTagLabel.h"

#define ARY @[@"Mark Wu", @"Green Chiu", @"Eikiy Chang", @"Gina Sun", @"Jeremy Chang", @"Sandra Hsu"]

@interface ViewController () <GCTagLabelListDataSource, GCTagLabelListDelegate>
@property (nonatomic, retain) NSMutableArray* tagNames;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tagNames = [NSMutableArray arrayWithArray:ARY];
    
    GCTagLabel* tagLabel0 = [GCTagLabel tagLabelWithReuseIdentifier:@"test"];
    [tagLabel0 setLabelText:@"Green Chiu" accessoryType:GCTagLabelAccessoryNone];
    [self.view addSubview:tagLabel0];
    
    GCTagLabel* tagLabel1 = [GCTagLabel tagLabelWithReuseIdentifier:@"test"];
    tagLabel1.maxWidth = 60.f;
    [tagLabel1 setLabelText:@"Green Chiu" accessoryType:GCTagLabelAccessoryNone];
    
    CGRect frame = tagLabel1.frame;
    frame.origin.y = 50;
    tagLabel1.frame = frame;
    [self.view addSubview:tagLabel1];
    
    
    GCTagList* taglist = [[[GCTagList alloc] initWithFrame:CGRectMake(0, 180, 320, 200)] autorelease];
    taglist.firstRowLeftMargin = 80.f;
    taglist.delegate = self;
    taglist.dataSource = self;
    [self.view addSubview:taglist];
    [taglist reloadData];
    
    
}

- (NSInteger)numberOfTagLabelInTagList:(GCTagList *)tagList {
    return self.tagNames.count;
}

- (GCTagLabel*)tagList:(GCTagList *)tagList tagLabelAtIndex:(NSInteger)index {
    
    static NSString* identifier = @"TagLabelIdentifier";
    
    GCTagLabel* tag = [tagList dequeueReusableTagLabelWithIdentifier:identifier];
    if(!tag) {
        tag = [GCTagLabel tagLabelWithReuseIdentifier:identifier];
        tag.labelBackgroundColor = [UIColor colorWithRed:84/255.f green:164/255.f blue:222/255.f alpha:1.f];
    }
    
    [tag setLabelText:self.tagNames[index]
        accessoryType:tagList.tag == 1000 ? GCTagLabelAccessoryArrowFont : GCTagLabelAccessoryCrossFont];
    
    return tag;
}

- (void)tagList:(GCTagList *)tagList accessoryButtonTappedAtIndex:(NSInteger)index {
    NSLog(@"%s", __func__);
}

- (void)tagList:(GCTagList *)taglist didChangedHeight:(CGFloat)newHeight {
    NSLog(@"%s", __func__);
}

- (void)tagList:(GCTagList *)taglist didSelectedLabelAtIndex:(NSInteger)index {
    NSLog(@"%s", __func__);
}

@end
