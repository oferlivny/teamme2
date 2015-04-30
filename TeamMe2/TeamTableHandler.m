//
//  TeamTableHandler.m
//  TeamMe
//
//  Created by Ofer Livny on 09/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TeamTableHandler.h"
#import "macros.h"
#import "TeamedPlayer.h"
#import "Player.h"
#import "PlayerCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation TeamTableHandler

@synthesize playersArray,teamsArray,currentTeamSetup,dontshowslider,height, dontshowcollapse;

- (id) init {
    self = [super init];
    if (self) {
        [self setDontshowslider:NO];
        [self setDontshowcollapse:NO];
        height = -1;
    };
    return self;
}
- (void) preloadTeamSetup: (MockTeam *) aTeamSetup {
    self.currentTeamSetup = aTeamSetup;
    NSSet *players = [currentTeamSetup players];
    NSMutableArray *tempArray = [[[NSMutableArray alloc] init ] autorelease];
    NSMutableArray *tempTeamsArray = [[[NSMutableArray alloc] init ] autorelease];
    for (int i=0;i<[currentTeamSetup number_of_teams] ;i++) {
        [tempTeamsArray addObject:[NSMutableArray array]];
    }
    for (MockTeamedPlayer *p in players) {
        [tempArray addObject:[p player]];
        int team_index = p.teamIndex;
        NSAssert(team_index>=0,@"sanity");
        NSAssert(team_index<=10,@"sanity");
        [[tempTeamsArray objectAtIndex:team_index] addObject:[p player]];
        NSLog(@"found player %@ with team %d",[[p player] name],[p teamIndex]);
    }
    self.playersArray = [NSMutableArray arrayWithArray:tempArray];
    self.teamsArray = [NSArray arrayWithArray:tempTeamsArray];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@" got %d sections",[teamsArray count]);
    int cnt = 0;
    for (NSArray *ar in teamsArray) if ([ar count]>0) cnt++;
    return cnt;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([teamsArray count]==1) {
        return [NSString stringWithFormat:@"All Players"];
    }
    NSInteger maxteams = [TEAM_NAMES count];
    return [TEAM_NAMES objectAtIndex:(section%maxteams)];
}
/*

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect sectionRect = CGRectMake(0,0,tableView.frame.size.width,200);;
	// create the button object
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:sectionRect];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor blackColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = GALI_FONT_OF_SIZE(25);//)[UIFont boldSystemFontOfSize:20];
    [headerLabel setTextAlignment:UITextAlignmentCenter];
    NSInteger maxteams = [TEAM_NAMES count];
    if ([teamsArray count]==1) {
        headerLabel.text = @"All Players";
    } else {
        headerLabel.text = [TEAM_NAMES objectAtIndex:(section%maxteams)]; // i.e. array element
    }
	return headerLabel;
}

*/



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *a = [teamsArray objectAtIndex:section];
    NSLog(@"got %d rows at index %d",[a count],section);
    return [a count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    if (false && dontshowslider)  {
        static NSString *CellIdentifier = @"PlayerCell";
        PlayerCell *playerCell = (PlayerCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (playerCell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"PlayerCell" owner:self options:NULL];
            playerCell = playercell;//[[[PlayerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        NSArray *a = [teamsArray objectAtIndex:indexPath.section];
        Player *p = [a objectAtIndex:[indexPath row]];
        playerCell.player = p;
        [playerCell setName: [p name] rank: [[p rank] floatValue]];
        if ([teamsArray count]>1)
            [playerCell setTeam: indexPath.section];
        else
            [playerCell setTeam: NO_TEAM];
        if (dontshowslider) [playerCell hideSlider];
        cell = playerCell;
    } else {
        static NSString *CellIdentifier = @"PlayerCellExpanded";
        PlayerCellExpanded *playerCell = (PlayerCellExpanded*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (playerCell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"PlayerCellExpanded" owner:self options:NULL];
            playerCell = playercellExpanded;//[[[PlayerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        NSArray *a = [teamsArray objectAtIndex:indexPath.section];
        Player *p = [a objectAtIndex:[indexPath row]];
        playerCell.player = p;
        [playerCell setName: [p name] rank: [[p rank] floatValue]];
        if ([teamsArray count]>1)
            [playerCell setTeam: indexPath.section];
        else
            [playerCell setTeam: NO_TEAM];
        if (dontshowslider) [playerCell hideSlider];
        if (dontshowcollapse) [playerCell hideCollaps];
        cell = playerCell;
    }
//    [cell setBackgroundColor:[UIColor clearColor]];
    assert(cell!=Nil);
    return cell;
    
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath { 
    cell.layer.cornerRadius = 10;
    UIView *view = [[[UIView alloc] initWithFrame:cell.bounds] autorelease];
    view.layer.cornerRadius = 10;
    [view setBackgroundColor: [UIColor colorWithRed:1 green:1 blue:1 alpha:0.77]];
    cell.backgroundView = view;
//    cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.77];

}
#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (height != -1) return height;
    if (dontshowslider) return 40;
    else return 100;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"player_selected" object:nil];
//    return indexPath;
//
////    [[NSNotificationCenter defaultCenter] postNotificationName:@"player_selected" object:nil];
////    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//
////    NSIndexPath *ip = [tableView indexPathForSelectedRow];
////    if ([ip row] == [indexPath row])
////        NSLog(@"blah");

}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"player_selected" object:nil];
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
    if (IOS_5_AND_UP)  [[NSNotificationCenter defaultCenter] postNotificationName:@"player_selected" object:nil];
//    return indexPath;
    
}

@end
