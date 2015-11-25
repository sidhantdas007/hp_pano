//
//  ViewController.m
//  HPMosaic
//
//  Created by HP Inc. on 11/18/15.
//  Copyright © 2015 Pilots & Incubation. All rights reserved.
//

#import "PPLaunchViewController.h"

@interface PPLaunchViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *launchImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *launchImageView;

@end

@implementation PPLaunchViewController

CGFloat const kPPLaunchAnimationDelay = 0.5; // seconds
CGFloat const kPPLaunchAnimationDuration = 0.61803399; // seconds
CGFloat const kPPLaunchConstraintWidthMultiplier = 0.01;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPPLaunchAnimationDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.view layoutIfNeeded];
        
        [UIView animateWithDuration:kPPLaunchAnimationDuration * 0.25 animations:^{
            self.titleLabel.alpha = 0.0;
        }];
        
        [self adjustConstraintsAfterLaunch];
        [UIView animateWithDuration:kPPLaunchAnimationDuration animations:^{
            self.launchImageView.alpha = 0.0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self performSegueWithIdentifier:@"Show Pano" sender:self];
        }];
        
    });
}

- (void)adjustConstraintsAfterLaunch
{
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.launchImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.launchImageView.superview
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:kPPLaunchConstraintWidthMultiplier
                                                                        constant:0 ];
    
    self.launchImageViewWidthConstraint.active = NO;
    widthConstraint.active = YES;
}

@end
