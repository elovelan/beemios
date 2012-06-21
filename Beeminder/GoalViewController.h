//
//  GoalViewController.h
//  Beeminder
//
//  Created by Andy Brett on 6/19/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GoalViewController : UIViewController

@property NSMutableData *responseData;
@property NSUInteger responseStatus;
@property (strong, nonatomic) NSMutableArray *datapoints;
@property (strong, nonatomic) IBOutlet UILabel *tmpLabel;
@property (strong, nonatomic) NSString *slug;
@end
