//
//  PPScrollView.m
//  HPPano
//
//  Created by P&I Lab on 11/7/15.
//  Copyright © 2015 HP Inc. All rights reserved.
//

#import "PPScrollView.h"

@interface PPScrollView()

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation PPScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setImage:(UIImage *)image
{
    if (!self.imageView) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
        self.imageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.imageView];
    }
    
    self.imageView.image = image;
    self.contentSize = self.imageView.frame.size;
    _image = image;
    [self setNeedsDisplay];
}

@end
