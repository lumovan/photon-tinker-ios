//
//  SPKTinkerViewController.m
//  Spark IOS
//
//  Copyright (c) 2013 Spark Devices. All rights reserved.
//

#import "SPKTinkerViewController.h"
#import "Spark-SDK.h"
#import "SPKCorePin.h"
#import "SparkDevice+pins.h"
//#import "Photon_Tinker-Swift.h"
#import "PinView.h"
#import "TSMessage.h"
#import "PinValueView.h"

@interface SPKTinkerViewController () <UITextFieldDelegate, PinViewDelegate, SPKPinFunctionDelegate>

@property (nonatomic, strong) NSMutableDictionary *pinViews;
//@property (nonatomic, strong) NSMutableDictionary *pinValueViews;

@property (nonatomic, weak) IBOutlet SPKPinFunctionView *pinFunctionView;
@property (nonatomic, weak) IBOutlet UIView *firstTimeView;
@property (nonatomic, weak) IBOutlet UIImageView *tinkerLogoImageView;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceIDLabel;
@property (weak, nonatomic) IBOutlet UIView *chipView;
@property (weak, nonatomic) IBOutlet UIImageView *chipShadowImageView;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (weak, nonatomic) IBOutlet UIView *deviceView;
@property (nonatomic) BOOL editingDeviceName;
@property (nonatomic) BOOL instanciatedPins;
@end


@implementation SPKTinkerViewController

- (void)viewDidLoad
{
    self.chipView.alpha = 0;
    self.pinViews = [NSMutableDictionary dictionaryWithCapacity:16];
//    self.pinValueViews = [NSMutableDictionary dictionaryWithCapacity:16];
    self.pinFunctionView.delegate = self;

    // background image
    UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imgTrianglifyBackgroundBlue"]]; // make brown version?
    backgroundImage.frame = [UIScreen mainScreen].bounds;
    backgroundImage.contentMode = UIViewContentModeScaleToFill;
    backgroundImage.alpha = 0.8;
    [self.view addSubview:backgroundImage];
    [self.view sendSubviewToBack:backgroundImage];
    
    // first time view
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFirstTime)];
    [self.firstTimeView addGestureRecognizer:tap];

    // fill in device name
    if ((self.device.name) && (![self.device.name isEqualToString:@""]))
    {
        self.deviceNameLabel.text = self.device.name;
    }
    else
    {
        self.deviceNameLabel.text = @"<no name>";
    }

    // inititalize pins
    [self.device configurePins:self.device.type];
    
    self.deviceIDLabel.text = [NSString stringWithFormat:@"ID: %@",[self.device.id uppercaseString]];
    
    self.instanciatedPins = NO;
    // initialize pin views
    /*
    for (SPKCorePin *pin in self.device.pins) {
        SPKCorePinView *v = [[SPKCorePinView alloc] init];
        [self.chipView insertSubview:v aboveSubview:self.chipShadowImageView];
        v.pin = pin;
        v.delegate = self;
        self.pinViews[pin.label] = v;
        
    }
     */
    
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideFunctionView:)];
    _tap.numberOfTapsRequired = 1;
    _tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:_tap];

    
    
}


- (IBAction)editDeviceNameButtonTapped:(id)sender
{
    if (!self.editingDeviceName)
    {
        self.deviceNameLabel.hidden = YES;
        self.deviceNameTextField.hidden = NO;
        self.deviceNameTextField.text = self.deviceNameLabel.text;
        self.deviceNameTextField.delegate = self;
        self.editingDeviceName = YES;
        [self.deviceNameTextField becomeFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    if (textField==self.deviceNameTextField)
    {
        [self.deviceNameTextField resignFirstResponder];
        self.editingDeviceName = NO;
        self.device.name = self.deviceNameTextField.text; // TODO: verify correctness
        self.deviceNameLabel.text = self.deviceNameTextField.text;
        self.deviceNameLabel.hidden = NO;
        self.deviceNameTextField.hidden = YES;

    }
    return YES;
}


- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)helpButtonTapped:(id)sender {
}

-(void)viewDidLayoutSubviews
{
    // TODO: find a way to do it after layoutSubviews has been called for everything
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

//    self.firstTimeView.hidden = ![SPKSpark sharedInstance].user.firstTime;
    self.tinkerLogoImageView.hidden = NO;
//    self.deviceNameLabel.hidden = NO;
    
    CGFloat aspect = [UIScreen mainScreen].bounds.size.width / [UIScreen mainScreen].bounds.size.height; // calculate the screen aspect ratio
    CGFloat x_offset = (aspect - (9.0/16.0))*250.0; // this will result in 25 for 3:2 screens and 0 for 16:9 screens (push pins in for old screens)
    CGFloat chip_bottom_margin = 40.0;
    
//    NSLog(@"aspect ratio: %f",aspect);
    
    for (SPKCorePin *pin in self.device.pins) {
        PinView *v = [[PinView alloc] initWithPin:pin];
        //CGFloat y_spacing = MAX(v.frame.size.height, ((self.chipShadowImageView.bounds.size.height-40) / (self.device.pins.count/2-1))); // assume even amount of pins per row
        CGFloat y_spacing = ((self.chipShadowImageView.frame.size.height-chip_bottom_margin) / (self.device.pins.count/2)); // assume even amount of pins per row
        y_spacing = MAX(y_spacing,v.frame.size.height);
        CGFloat y_offset = self.chipShadowImageView.frame.origin.y;//+5;//
        if (x_offset<1) // NOT old 3:2 screens
            y_offset += v.frame.size.height/4;
        NSLog(@"y spacing %f / y_ofs %f",y_spacing, y_offset);
        
        [self.chipView insertSubview:v aboveSubview:self.chipShadowImageView];
        v.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutAttribute xPosAttribute = (pin.side == SPKCorePinSideLeft) ? NSLayoutAttributeLeading : NSLayoutAttributeTrailing;
        CGFloat xConstant = (pin.side == SPKCorePinSideLeft) ? x_offset : -x_offset;
        
        [self.chipView addConstraint:[NSLayoutConstraint constraintWithItem:v
                                                                  attribute:xPosAttribute
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.chipView
                                                                  attribute:xPosAttribute
                                                                 multiplier:1.0
                                                                   constant:xConstant]];
        
        [self.chipView addConstraint:[NSLayoutConstraint constraintWithItem:v
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.chipView
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:pin.row*y_spacing + y_offset]];
        
        [v addConstraint:[NSLayoutConstraint constraintWithItem:v
                                                      attribute:NSLayoutAttributeWidth
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:1.0
                                                       constant:50]];
        
        [v addConstraint:[NSLayoutConstraint constraintWithItem:v
                                                      attribute:NSLayoutAttributeHeight
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:1.0
                                                       constant:50]];
        
        v.delegate = self;
        self.pinViews[pin.label] = v;
        
        // Pin Value View
        PinValueView *pvv = [[PinValueView alloc] initWithPin:pin];
        [self.chipView insertSubview:pvv aboveSubview:self.chipShadowImageView];
        pvv.translatesAutoresizingMaskIntoConstraints = NO;
        // stick view to right of the pin when positioned in left or exact opposite
        NSLayoutAttribute pvvXPosAttribute = (pin.side == SPKCorePinSideLeft) ? NSLayoutAttributeLeft : NSLayoutAttributeRight;
        NSLayoutAttribute inv_pvvXPosAttribute = (pin.side == SPKCorePinSideLeft) ? NSLayoutAttributeRight : NSLayoutAttributeLeft;

        [self.chipView addConstraint:[NSLayoutConstraint constraintWithItem:pvv
                                                                  attribute:pvvXPosAttribute
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:v
                                                                  attribute:inv_pvvXPosAttribute
                                                                 multiplier:1.0
                                                                   constant:0]];
        
        [self.chipView addConstraint:[NSLayoutConstraint constraintWithItem:pvv
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:v
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0
                                                                   constant:0]];
        
        [pvv addConstraint:[NSLayoutConstraint constraintWithItem:pvv
                                                      attribute:NSLayoutAttributeWidth
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:1.0
                                                       constant:100]];
        
        [pvv addConstraint:[NSLayoutConstraint constraintWithItem:pvv
                                                      attribute:NSLayoutAttributeHeight
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:1.0
                                                       constant:50]];
        
        v.valueView = pvv;
//        self.pinValueViews[pin.label] = pvv;

        
    }
    
    self.chipView.alpha=0;
    [UIView animateWithDuration:0.5
                          delay:0.5
                        options: UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         self.chipView.alpha=1;
                         [self.chipView setNeedsLayout];
                     }
                     completion:^(BOOL finished){
                         NSLog(@"Done!");
                     }];

}



/*
 
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    
    if (!isiPhone5) {
        CGRect f = self.nameLabel.frame;
        f.origin.y = 340.0;
        self.nameLabel.frame = f;

        f = self.firstTimeView.frame;
        f.origin.y += 1.0;
        self.firstTimeView.frame = f;

        f = self.tinkerLogoImageView.frame;
        f.origin.y -= 30.0;
        self.tinkerLogoImageView.frame = f;
    }
}
*/

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Pin Function Delegate

- (void)pinFunctionSelected:(SPKCorePinFunction)function
{
    SPKCorePin *pin = self.pinFunctionView.pin;
    pin.selectedFunction = function;
    self.pinFunctionView.pin = pin;

    PinView *pinView = self.pinViews[pin.label];
    [pinView.pin resetValue];
    if (function == SPKCorePinFunctionNone)
        pinView.active = NO;
    else
        pinView.active = YES;
    [pinView refresh];
}

#pragma mark - Core Pin View Delegate

//- (void)pinViewAdjusted:(SPKCorePinView *)pinView newValue:(NSUInteger)newValue
//{
//    [pinView.pin adjustValue:newValue];
//
//    [pinView noslider];
//    [pinView refresh];
//    [pinView activate];
//    [self pinCallHome:pinView];
//    for (SPKCorePinView *pv in self.pinViews.allValues) {
//        [pv showDetails];
//    }
//}


- (void)pinViewHeld:(PinView *)pinView
{
//    if (![self slidingAnalogWritePinView] && !pinView.active) {
//        [self showFunctionView:pinView];
//    }
    
    NSLog(@"Pin %@ held",pinView.pin.label);
    pinView.active = NO;
    
    
}


-(void)pinViewTapped:(PinView *)pinView
{
    NSLog(@"Pin %@ tapped",pinView.pin.label);
    // if function view is showing, remove it
    if (!self.pinFunctionView.hidden)
    {
        self.pinFunctionView.hidden = YES;
        for (SPKCorePinView *pv in self.pinViews.allValues)
        {
            pv.alpha = 1.0;
        }
        self.tinkerLogoImageView.hidden = NO;
//        self.deviceNameLabel.hidden = NO;
    } // else if pin is not active then show function view
    else
    {
        if (!pinView.active) // pin is inactive - show pin function view
        {
            [self showFunctionView:pinView];
        }
        else // or else just tinker the pin as 
        {
            switch (pinView.pin.selectedFunction) {
                case SPKCorePinFunctionDigitalRead:
                case SPKCorePinFunctionAnalogRead:
                {
                    [self pinCallHome:pinView completion:nil];
                    
                    break;
                }

                case SPKCorePinFunctionDigitalWrite:
                {
                    if (pinView.pin.value)
                        [pinView.pin adjustValue:0];
                    else
                        [pinView.pin adjustValue:1];
                    
                    [self pinCallHome:pinView completion:nil];
                    
                    break;
                }


                case SPKCorePinFunctionAnalogWrite:
                {

                    break;
                }

                default:
                {
                    break;
                }
            }
        }
    }
    
    /*
    else if (!pinView.active) {
        SPKCorePinView *slidingAnalogWritePinView = [self slidingAnalogWritePinView];

        if (!slidingAnalogWritePinView && pinView.pin.selectedFunction == SPKCorePinFunctionAnalogWrite) {
            for (SPKCorePinView *pinView in self.pinViews.allValues) {
                [pinView hideDetails];
            }

            self.tinkerLogoImageView.hidden = YES;
//            if (!isiPhone5) {
//                self.nameLabel.hidden = YES;
//            }
            [self.view bringSubviewToFront:pinView];
            [pinView slider];
        } else if (!slidingAnalogWritePinView && inPin && pinView.pin.selectedFunction == SPKCorePinFunctionNone) {
            [self showFunctionView:pinView];
        } else if (!slidingAnalogWritePinView && pinView.pin.selectedFunction == SPKCorePinFunctionDigitalWrite) {
            if (!pinView.pin.valueSet) {
                [pinView.pin adjustValue:1];
            } else {
                [pinView.pin adjustValue:!pinView.pin.value];
            }

            [pinView refresh];
            [pinView activate];
            [self pinCallHome:pinView];
        } else if (!slidingAnalogWritePinView && inPin) {
            if (pinView.pin.selectedFunction == SPKCorePinFunctionAnalogRead || pinView.pin.selectedFunction == SPKCorePinFunctionDigitalRead) {
                [pinView showDetails];
                [self.view bringSubviewToFront:pinView];
                [pinView activate];
                [self pinCallHome:pinView];
            }
        } else if (slidingAnalogWritePinView && pinView != slidingAnalogWritePinView) {
            [slidingAnalogWritePinView noslider];
            [slidingAnalogWritePinView refresh];
            [slidingAnalogWritePinView activate];
            [self pinCallHome:slidingAnalogWritePinView];
            for (SPKCorePinView *pinView in self.pinViews.allValues) {
                [pinView showDetails];
            }
        }
    }*/
    
}

#pragma mark - Private Methods

- (void)dismissFirstTime
{
    self.firstTimeView.hidden = YES;
//    [SPKSpark sharedInstance].user.firstTime = NO;
}

- (void)showFunctionView:(PinView *)pinView
{
    if (self.pinFunctionView.hidden) {
        self.tinkerLogoImageView.hidden = YES;
        self.pinFunctionView.pin = pinView.pin;
        self.pinFunctionView.hidden = NO;
        for (PinView *pv in self.pinViews.allValues) {
            if (pv != pinView) {
                pv.alpha = 0.1;
            }
        }
        [self.view bringSubviewToFront:self.pinFunctionView];
    }
}


-(void)hideFunctionView:(id)sender
{
    if (!self.pinFunctionView.hidden)
    {
        self.tinkerLogoImageView.hidden = NO;
        self.pinFunctionView.hidden = YES;
        for (PinView *pv in self.pinViews.allValues) {
                pv.alpha = 1;
        }
    
    }
}

- (SPKCorePinView *)slidingAnalogWritePinView
{
    for (SPKCorePinView *pv in self.pinViews.allValues) {
        if (pv.pin.selectedFunction == SPKCorePinFunctionAnalogWrite && pv.sliding) {
            return pv;
        }
    }

    return nil;
}

- (void)pinCallHome:(PinView *)pinView completion:(void (^)(NSUInteger value))completion
{
    [self.device updatePin:pinView.pin.label function:pinView.pin.selectedFunction value:pinView.pin.value success:^(NSUInteger result) {
        ///
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tinkerLogoImageView.hidden = NO;
            if (pinView.pin.selectedFunction == SPKCorePinFunctionDigitalWrite || pinView.pin.selectedFunction == SPKCorePinFunctionAnalogWrite) {
                if (result == -1) {

                    [TSMessage showNotificationWithTitle:@"Device pin error" subtitle:@"There was a problem writing to this pin." type:TSMessageNotificationTypeError];
                    [pinView.pin resetValue];
                }
            } else {
                [pinView.pin adjustValue:result];
                [pinView refresh];
                if (completion)
                    completion(result);
            }
            [pinView refresh];
        });
    } failure:^(NSString *errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // TSMessage
            NSString* errorStr = [NSString stringWithFormat:@"Error communicating with device: %@",errorMessage];
            [TSMessage showNotificationWithTitle:@"Device error" subtitle:errorStr type:TSMessageNotificationTypeError];

            [pinView.pin resetValue];
            self.tinkerLogoImageView.hidden = NO;
            [pinView refresh];
        });
    }];
}

@end
