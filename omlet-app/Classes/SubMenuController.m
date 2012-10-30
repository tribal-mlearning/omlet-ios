/*
 * Copyright (c) 2012, TATRC and Tribal
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * * Neither the name of TATRC or TRIBAL nor the
 *   names of its contributors may be used to endorse or promote products
 *   derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL TATRC OR TRIBAL BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SubMenuController.h"
#import "PEMenu.h"
#import "PEMenuLink.h"
#import "PEResource.h"
#import "Framework.h"

@implementation SubMenuController


- (id)initWithMenu:(PEMenu *)_menu
{
    return [self initWithMenu:_menu andStyle:SubMenuStyleNormalList withDescription:nil];
}

- (id)initWithMenu:(PEMenu *)_menu andStyle:(SubMenuStyle)style withDescription:(NSString *)_description
{
    if (self = [super init]) {
        menu = [_menu retain];
        menuStyle = style;
        if (_description) description = [_description copy];
    }
    return self;
}

- (void) dealloc{
    [menu release];
    [description release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (description)
        self.title = description;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [menu childCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    NSArray *elements = [menu getChildren];
    PEBase *elem = [elements objectAtIndex:indexPath.row];
    BOOL hasLink = YES;
    if ([elem isKindOfClass:[PEMenuLink class]]) {
        PEResource *link = (PEResource *) [((PEMenuLink *) elem) getLinkedElement];
        if ([link.path isEqualToString:@""]) hasLink = NO;
        if ([link.desc isEqualToString:@""] == NO) cell.detailTextLabel.text = link.desc;
    }
    BOOL enabled = [elem isEnabled];
    cell.textLabel.enabled = enabled;
    cell.userInteractionEnabled = (enabled && hasLink);
    cell.textLabel.text = elem.title;
    
     if (menuStyle == SubMenuStyleNormalList) {
         if (enabled && hasLink) cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
         else cell.accessoryType = UITableViewCellAccessoryNone;
         cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];   
     }
     else {
         cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
     }
    
    cell.textLabel.numberOfLines = 2;
    
    /*
    if ([elem isKindOfClass:[PEMenuLink class]]  && ![elem.icon isEqualToString:@"default-icon.png"]) {
        cell.imageView.image = [UIImage imageWithContentsOfFile: [NSString stringWithFormat:@"%@/%@",[((PEMenuLink *) elem) getPath],elem.icon ]];
    }
    else {
       cell.imageView.image = [UIImage imageNamed:elem.icon];
    }*/
    
    if (elem.icon)
    {
        NSString *packagePath = ((Framework *)[Framework client]).packagePath;
        cell.imageView.image = [UIImage imageWithContentsOfFile: [NSString stringWithFormat:@"%@/%@",packagePath, elem.icon]];
    }
    else
    {
        cell.imageView.image = nil;
    }
    
    if (!enabled) cell.imageView.alpha = 0.5;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *elements = [menu getChildren];
    PEBase *selectedElement = [elements objectAtIndex:indexPath.row];
    
    if ([selectedElement isMemberOfClass:[PEMenuLink class]]) {
        PEBase *link = [((PEMenuLink *) selectedElement) getLinkedElement];
        if (link) selectedElement = link;
    }
    
    if ([selectedElement isKindOfClass:[PEResource class]])
    {
        //For backwards compatiability, ensure that the resource path isn't prepended by anything from a menu item
        NSArray *strComp = [[selectedElement getFullId] componentsSeparatedByString: @"."];
        [[Framework client] openResource:[strComp objectAtIndex:strComp.count -1]];
    }
    else if ([selectedElement isKindOfClass:[PEMenu class]])
    {
        [[Framework client] openMenu:[selectedElement getFullId]];
    }
    
}

@end
