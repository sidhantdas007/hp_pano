//
//  PPPreviewViewController.m
//  PaPreview View ControllernoPix
//
//  Created by James Trask on 11/7/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import "PPPreviewViewController.h"
#import "PPScrollView.h"

@interface PPPreviewViewController ()

@property (strong, nonatomic) IBOutletCollection(UIScrollView) NSArray *panoScrollViews;
@property (weak, nonatomic) IBOutlet UIView *paperView;

@end

@implementation PPPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self layoutScrollViews];
    [self createImageViews];
    self.paperView.hidden = NO;
    
//    for (int idx = 0; idx < self.panoImageViews.count; idx++) {
//        UIImage *image = nil;
//        if (idx < self.images.count) {
//            image = self.images[idx];
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImageView *imageView = self.panoImageViews[idx];
//            UIScrollView *scrollView = (UIScrollView *)imageView.superview;
//            imageView.autoresizingMask = UIViewAutoresizingNone;
//            imageView.frame = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
//            
//            imageView.image = image;
//            scrollView.contentSize = imageView.frame.size;
//            scrollView.contentOffset = CGPointZero;
//            [scrollView setNeedsDisplay];
//        });
//    }
//    
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Scroll views

- (void)layoutScrollViews
{
    NSInteger stripCount = self.panoScrollViews.count;
    CGFloat stripHeightPercent = 1.375 / 5.0;
    CGFloat gutterPercent = (1.0 - stripHeightPercent * stripCount) / (stripCount + 1);
    for (int idx = 0; idx < self.panoScrollViews.count; idx++) {
        UIScrollView *scrollView = (UIScrollView *)self.panoScrollViews[idx];
        CGFloat topPercent = stripHeightPercent * idx + (gutterPercent * (idx + 1));
        CGSize containerSize = self.paperView.bounds.size;
        scrollView.frame = CGRectMake(0, topPercent * containerSize.height, containerSize.width, stripHeightPercent * containerSize.height);
    }
}

- (void)createImageViews
{
    for (int idx = 0; idx < self.panoScrollViews.count; idx++) {
        if (self.images.count > idx) {
            UIScrollView *scrollView = (UIScrollView *)self.panoScrollViews[idx];
            UIImage *image = self.images[idx];
            UIImageView *contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
            contentView.backgroundColor = [UIColor blackColor];
            contentView.contentMode = UIViewContentModeScaleAspectFit;
            contentView.image = self.images[idx];
            [scrollView addSubview:contentView];
            scrollView.contentOffset = CGPointZero;
            scrollView.contentSize = contentView.bounds.size;
            NSLog(@"%d: %.1f, %.1f", idx, scrollView.contentOffset.x, scrollView.contentOffset.y);
        }
    }
}

@end
