GCTagList
=========

GCTagList like iOS Mail app's sender or recivers tags.

![](Screenshot.png)
![](Screenshot2.png)

##Installation
Simple copy over the `classes` folder and `assets` folder into your project and make sure you have linked the framework `QuartzCore.framework`.

##What's new

* support MaxRow
* TagLabel could set not show selectedState. (selectedEnabled)

##Supports

* ARC
* iOS 5.0 - 6.0

##How to use
implementation the GCTagListDataSource and call the public method `reloadData`  

```Objective-C   
-(void)viewDidLoad {
	[super viewDidLoad];
	GCTagList* taglist = [[GCTagList alloc] initWithFrame:CGRectMake(0, 180, 320, 200)];
    taglist.firstRowLeftMargin = 80.f;
    taglist.dataSource = self;
    [self.view addSubview:taglist];
    [taglist reloadData];
}
```

```Objective-C   
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
        accessoryType:GCTagLabelAccessoryCrossFont];
    
    return tag;
}
```


##GCTagListDelegate Protocol

```Objective-C   
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
 * if implement protocol <GCTagLabelListDataSource> method 'maxNumberOfRowAtTagList' 
 * and the taglist's rows is more than the maxRow, this method will be call.
 * 
 * @retVal NSString the text for the TagLabel of theMaxRow's last one.
 */
- (NSString*)tagList:(GCTagList *)tagList labelTextForGroupTagLabel:(NSInteger)interruptIndex;
```

##GCTagListDataSource Protocol
```Objective-C   
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
```

##Reference

* [DWTagList](https://github.com/domness/DWTagList)

##License

Use this control in your apps? Let me know!

Copyright (c) 2013 Green Chiu, http://greenchiu.github.com/ Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
