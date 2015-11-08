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
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *panoImageViews;

@end

@implementation PPPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    for (int idx = 0; idx < self.panoImageViews.count; idx++) {
        UIImage *image = nil;
        if (idx < self.images.count) {
            image = self.images[idx];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageView *imageView = self.panoImageViews[idx];
            UIScrollView *scrollView = (UIScrollView *)imageView.superview;
            imageView.autoresizingMask = UIViewAutoresizingNone;
            imageView.frame = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
            
            imageView.image = image;
            scrollView.contentSize = imageView.frame.size;
            scrollView.contentOffset = CGPointZero;
            [scrollView setNeedsDisplay];
        });
    }
    
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

#pragma mark - Scroll view management

- (void)prepareScrollView:(UIScrollView *)scrollView withImage:(UIImage *)image
{
    
}

@end
