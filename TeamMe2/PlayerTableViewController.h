//
//  PlayerTableViewController.h
//  TeamMe2
//
//  Created by Ofer Livny on 4/30/15.
//  Copyright (c) 2015 Ofer Livny. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate >

@property (copy, nonatomic) NSArray *test;

@end
