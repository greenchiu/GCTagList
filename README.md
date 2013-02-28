GCTagList
=========

GCTagList like iOS Mail app's sender or recivers tags.

![](Screenshot.png)

##Installation
Simple copy over the `classes` folder and `assets` folder into your project and make sure you have linked the framework `QuartzCore.framework`.

##Supports

* ARC
* iOS 5 -

##How to use
implementation the GCTagLabelListDataSource and call the public method `reloadData`  

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
```

##GCTagLabelListDataSource Protocol
```Objective-C   
/**
 * how many count for taglist to display.
 */
- (NSInteger)numberOfTagLabelInTagList:(GCTagList*)tagList;

/**
 * the taglabel At index in the taglist.
 */
- (GCTagLabel*)tagList:(GCTagList*)tagList tagLabelAtIndex:(NSInteger)index;
```

##License
Copyright (c) 2013 Green Chiu, http://greenchiu.github.com/ Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
