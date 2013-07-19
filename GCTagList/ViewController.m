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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tagNames = [NSMutableArray arrayWithArray:ARY];
    
//    GCTagLabel* tagLabel0 = [GCTagLabel tagLabelWithReuseIdentifier:@"test"];
//    [tagLabel0 setLabelText:@"Green Chiu" accessoryType:GCTagLabelAccessoryArrowSign];
//    [self.view addSubview:tagLabel0];
//    
//    GCTagLabel* tagLabel1 = [GCTagLabel tagLabelWithReuseIdentifier:@"test"];
//    tagLabel1.maxWidth = 60.f;
//    [tagLabel1 setLabelText:@"Green Chiu" accessoryType:GCTagLabelAccessoryNone];
//    
//    CGRect frame = tagLabel1.frame;
//    frame.origin.y = 50;
//    tagLabel1.frame = frame;
//    [self.view addSubview:tagLabel1];
    
//    NSLog(@"heightOfRows:[%d rows]:[%.1f]",2, [GCTagList heightOfRows:1]);
    
    
    GCTagList* taglist = [[[GCTagList alloc] initWithFrame:CGRectMake(0, 180, 320, 200)] autorelease];
//    taglist.firstRowLeftMargin = 80.f;
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
//        tag.startGradientColor = [UIColor colorWithString:@"e8e8e8"];
//        tag.endGradientColor = [UIColor colorWithRed:84/255.f green:164/255.f blue:222/255.f alpha:1.f];
//        NSLog(@"%@", tag.endGradientColor);
        
        tag.gradientColors = [GCTagLabel defaultGradoentColors];
        
        [tag setCornerRadius:6.f];
    }
    
    NSString* labelText = self.tagNames[index];
    GCTagLabelAccessoryType type = GCTagLabelAccessoryCrossSign;
    [tag setLabelText:labelText
        accessoryType:type];
    
    return tag;
}

- (void)tagList:(GCTagList *)tagList accessoryButtonTappedAtIndex:(NSInteger)index {
//    NSLog(@"%s", __func__);
//    [self.tagNames removeObjectAtIndex:index];
    
//    [self.tagNames removeObjectAtIndex:index];
//    [self.tagNames removeObjectAtIndex:index];
//
    
//    NSInteger allCount = [self.tagNames count];
//    [self.tagNames removeObjectsInRange:NSMakeRange(index, 2)];
//    [tagList deleteTagLabelWithRange:NSMakeRange(index, 2)];
    
//    [tagList deleteTagLabelWithRange:NSMakeRange(index, 2) withAnimation:YES];
//    NSLog(@"%@", self.tagNames);
//    self.tagNames[index] = @"Kim Jong Kook";
//    [tagList reloadTagLabelWithRange:NSMakeRange(index, 1)];
//    [tagList reloadTagLabelWithRange:NSMakeRange(index, 1) withAnimation:YES];
    
    
//    self.tagNames[index] = @"Kim Jong Kook";
//    self.tagNames[index+1] = @"Girls' Generation";
//    [tagList reloadTagLabelWithRange:NSMakeRange(index, 2) withAnimation:YES];
    
//    [self.tagNames insertObject:@"Girls' Generation" atIndex:index];
//    [self.tagNames insertObject:@"TaeTiSeo" atIndex:index];
//    [tagList insertTagLabelWithRange:NSMakeRange(index, 2)];
//    [tagList insertTagLabelWithRange:NSMakeRange(index, 2) withAnimation:YES];
    
//    [tagList reloadData];
}

- (void)tagList:(GCTagList *)taglist didChangedHeight:(CGFloat)newHeight {
    NSLog(@"%s:%.1f", __func__, newHeight);
}

- (NSString*)tagList:(GCTagList *)tagList labelTextForGroupTagLabel:(NSInteger)interruptIndex {
    return [NSString stringWithFormat:@"和其他%d位", self.tagNames.count - interruptIndex];
}

- (void)tagList:(GCTagList *)taglist didSelectedLabelAtIndex:(NSInteger)index {
//    NSLog(@"%.0f", [taglist tagLabelAtIndex:index].maxWidth);
//    NSLog(@"selectIndex:%d", index);
    [taglist deselectedLabelAtIndex:index animated:YES];
}

//

//- (NSInteger)maxNumberOfRowAtTagList:(GCTagList *)tagList {
//    return 1;
//}
//
- (GCTagLabelAccessoryType)accessoryTypeForGroupTagLabel {
    return GCTagLabelAccessoryArrowSign;
}

@end
