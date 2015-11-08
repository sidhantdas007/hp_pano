//
//  PPPreviewViewController.m
//  PaPreview View ControllernoPix
//
//  Created by James Trask on 11/7/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import "PPPreviewViewController.h"

@interface PPPreviewViewController ()
@property (strong, nonatomic) IBOutletCollection(UIScrollView) NSArray *panoScrollViews;

@end

@implementation PPPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
