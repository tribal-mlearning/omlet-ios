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

#import "LoginController.h"
#import <QuartzCore/QuartzCore.h>

@interface LoginController ()

@end

@implementation LoginController
@synthesize noConnectionText;
@synthesize infoTxt;
@synthesize loginBtn;
@synthesize versionLabel;
@synthesize PINaltText, pin, delegate, canLogin;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateUI {
    if (self.isViewLoaded) {
        if (canLogin) {
            pin.enabled = YES;
            pin.text = @"";
            pin.hidden = NO;
            PINaltText.hidden = NO;
            noConnectionText.hidden = YES;
            
            if (pin.text.length > 0)
                loginBtn.hidden = NO;
            else
                loginBtn.hidden = YES;
            
        } else { 
            pin.enabled = NO;
            pin.hidden = YES;
            PINaltText.hidden = YES;
            noConnectionText.hidden = NO;
            loginBtn.hidden = YES;
        }
    }
}

- (void)setCanLogin:(BOOL)_canLogin {
    canLogin = _canLogin;
    [self updateUI];
}

- (void)resetPIN {
    infoTxt.hidden = NO;
    pin.text = @"";
    pin.hidden = NO;
    PINaltText.hidden = NO;
    loginBtn.hidden = YES;
}

- (void)enterPIN:(NSString *)string {
    [pin resignFirstResponder];
    pin.hidden = YES;
    loginBtn.hidden = YES;
    [delegate authenticatePIN:string onAuthenticationCompleted:^(bool sucess, id data) {
        if (sucess) {}
        else [self resetPIN];
    }];
}

- (IBAction)loginPress:(id)sender {
    [self enterPIN:pin.text];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    if ([textField.text length] == 1 && [string isEqualToString:@""]) PINaltText.hidden = NO;
    else PINaltText.hidden = YES;
        
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 8) ? NO : YES;
    
//   BOOL num = YES;
    
/*    if ([string isEqualToString:@""]) num = NO;
    if (textField.text.length == 4 && num) {
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        [self performSelector:@selector(enterPIN:) withObject:textField.text afterDelay:0.3];
    } else if (textField.text.length > 4) return NO;
    return YES;*/
}

-(void) textFieldDidChange:(id)sender
{
    if (pin.text.length > 0)
        loginBtn.hidden = NO;
    else
        loginBtn.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    noConnectionText.text = NSLocalizedString(@"No internet connection", @"");
    infoTxt.text = NSLocalizedString(@"Access denied", @"");
    [self updateUI];
                   
    versionLabel.text = [@"v" stringByAppendingString:
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    //self.loginBtn.buttonType = UIButtonTypeCustom;
    [self.loginBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.loginBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
    self.loginBtn.layer.borderColor = [UIColor blackColor].CGColor;
    self.loginBtn.layer.borderWidth = 0.5f;
    self.loginBtn.layer.cornerRadius = 2.0f;
    
    [pin addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0.0 blue:0.498 alpha:1.0] CGColor], 
                       (id)[[UIColor colorWithRed:0.0 green:0.0 blue:0.737 alpha:1.0] CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setPINaltText:nil];
    [self setPin:nil];
    [self setVersionLabel:nil];
    [self setNoConnectionText:nil];
    [self setInfoTxt:nil];
    [self setLoginBtn:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [PINaltText release];
    [pin release];
    [versionLabel release];
    [noConnectionText release];
    [infoTxt release];
    [loginBtn release];
    [super dealloc];
}
@end
