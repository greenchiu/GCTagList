GCTagList
=========

GCTagList like iOS Mail app's sender or recivers tags.

![](Screenshot.png)

##Installation
Simple copy over the `classes` folder and `assets` folder into your project and make sure you have linked the framework `QuartzCore.framework`.

##GCTagListDelegate Protocol

```
/**
 * after reloadData, if the height of TagLabelList has changed, will call this method.  
 */
- (void)tagList:(GCTagList *)taglist didChangedHeight:(CGFloat)newHeight;
```
---
```
/**
 * Tapped the TagLabel, will call this mehtod.
 */
- (void)tagList:(GCTagList *)taglist didSelectedLabelAtIndex:(NSInteger)index;
```
---
```
/**
 * Tapped the TagLabel's accessoryButton, will call this mehtod.
 */
- (void)tagList:(GCTagList *)tagList accessoryButtonTappedAtIndex:(NSInteger)index;
```

##GCTagLabelListDataSource Protocol
```
/**
 * how many count for taglist to display.
 */
- (NSInteger)numberOfTagLabelInTagList:(GCTagList*)tagList;
```
---
```
/**
 * the taglabel At index in the taglist.
 */
- (GCTagLabel*)tagList:(GCTagList*)tagList tagLabelAtIndex:(NSInteger)index;
```

##License
Copyright (c) 2013 Green Chiu, http://greenchiou.github.com/ Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
