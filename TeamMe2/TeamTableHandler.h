//
//  TeamTableHandler.h
//  TeamMe
//
//  Created by Ofer Livny on 09/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerCell.h"
#import "PlayerCellExpanded.h"

#import "MockTeam.h"

@interface TeamTableHandler : NSObject <UITableViewDelegate, UITableViewDataSource> {
        IBOutlet PlayerCell *playercell;
    IBOutlet PlayerCellExpanded *playercellExpanded;

    NSMutableArray *playersArray;
    NSArray *teamsArray;
    MockTeam *currentTeamSetup;
    bool dontshowslider;
    bool dontshowcollapse;
    int height;
//    bool expanded;

}

@property (nonatomic,retain)     NSMutableArray *playersArray;
@property (nonatomic,retain)     NSArray *teamsArray;
@property (nonatomic,retain) MockTeam *currentTeamSetup;
@property (nonatomic,assign) bool dontshowcollapse;
@property (nonatomic,assign) bool dontshowslider;
@property (nonatomic,assign) int height;
@property (nonatomic,retain) UIProgressView *progressView;
- (void) preloadTeamSetup: (MockTeam *) aTeamSetup ;
- (UIProgressView *) startProgressView;
- (void) hideProgressView;
@end
