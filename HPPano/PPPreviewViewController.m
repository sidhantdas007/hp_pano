//
//  PPPreviewViewController.m
//  PaPreview View ControllernoPix
//
//  Created by P&I Lab on 11/7/15.
//  Copyright © 2015 HP Inc. All rights reserved.
//

#import "PPPreviewViewController.h"
#import "PPScrollView.h"
#import "PPPaperView.h"
#import <MPLayoutFactory.h>

@interface PPPreviewViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) IBOutletCollection(UIScrollView) NSArray *panoScrollViews;
@property (weak, nonatomic) IBOutlet PPPaperView *paperView;

@end

@implementation PPPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addGestures];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    self.paperView.frame = CGRectMake(0, 0, 7.0, 5.0);
    [self computePositions];
    self.paperView.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    
//    self.paperView.hidden = YES;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.

        [self computePositions];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {

        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        
        [self computePositions];
    }];
}

- (IBAction)doneButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Layout

- (void)computePositions
{
    MPLayout *layout = [MPLayoutFactory layoutWithType:[MPLayoutFit layoutType] orientation:MPLayoutOrientationFixed assetPosition:[MPLayout completeFillRectangle]];
    [layout layoutContentView:self.paperView inContainerView:self.containerView];
    [self layoutScrollViews];
    [self createImageViews];
    self.paperView.sourceImages = self.images;
    [self.paperView drawPerforations:kPPNumberOfStrips stripPercent:kPPStripHeight / kPPPaperHeight];
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
        UIScrollView *scrollView = (UIScrollView *)self.panoScrollViews[idx];
        [scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        if (self.images.count > idx) {
            UIImage *image = self.images[idx];
            CGFloat xScale = scrollView.bounds.size.width / image.size.width;
            CGFloat yScale = scrollView.bounds.size.height / image.size.height;
            CGFloat scale = fmaxf(xScale, yScale);
            UIImageView *contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
            contentView.backgroundColor = [UIColor blackColor];
            contentView.contentMode = UIViewContentModeScaleAspectFit;
            contentView.image = self.images[idx];
            [scrollView addSubview:contentView];
            scrollView.contentOffset = CGPointZero;
            scrollView.contentInset = UIEdgeInsetsZero;
            scrollView.contentSize = contentView.bounds.size;
        }
    }
}

#pragma mark - Gestures

- (void)addGestures
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePreviewTap:)];
    tapRecognizer.cancelsTouchesInView = YES;
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)handlePreviewTap:(UIGestureRecognizer *)gestureRecognizer
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
