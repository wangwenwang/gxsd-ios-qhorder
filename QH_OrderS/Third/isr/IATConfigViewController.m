//
//  ISRConfigViewController.m
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "IATConfigViewController.h"
#import "IATConfig.h"
#import "Definition.h"


@interface IATConfigVIewController ()
@property (nonatomic,strong) SAMultisectorSector *bosSec;
@property (nonatomic,strong) SAMultisectorSector *eosSec;
@property (nonatomic,strong) SAMultisectorSector *recSec;
@end

@implementation IATConfigVIewController


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self setupMultisectorControl];
    [self needUpdateView];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    _backScrollView.contentSize = CGSizeMake(size.width ,size.height+300);
}


#pragma mark -  User interface processing

-(void)initView
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER )
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif

    
    _accentPicker.delegate = self;
    _accentPicker.dataSource = self;
    _accentPicker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _accentPicker.textColor = [UIColor whiteColor];
    _accentPicker.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
    _accentPicker.highlightedFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    _accentPicker.highlightedTextColor = [UIColor colorWithRed:0.0 green:168.0/255.0 blue:255.0/255.0 alpha:1.0];
    _accentPicker.interitemSpacing = 20.0;
    _accentPicker.fisheyeFactor = 0.001;
    _accentPicker.pickerViewStyle = AKPickerViewStyle3D;
    _accentPicker.maskDisabled = false;
    
    self.view.backgroundColor = [UIColor colorWithRed:26.0/255.0 green:26.0/255.0 blue:26.0/255.0 alpha:1.0];
}


- (void)setupMultisectorControl{
    [_roundSlider addTarget:self action:@selector(multisectorValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    UIColor *blueColor = [UIColor colorWithRed:0.0 green:168.0/255.0 blue:255.0/255.0 alpha:1.0];
    UIColor *redColor = [UIColor colorWithRed:245.0/255.0 green:76.0/255.0 blue:76.0/255.0 alpha:1.0];
    UIColor *greenColor = [UIColor colorWithRed:29.0/255.0 green:207.0/255.0 blue:0.0 alpha:1.0];
    
    _bosSec = [SAMultisectorSector sectorWithColor:redColor maxValue:10000];//timeout of Beginning Of Speech
    _eosSec = [SAMultisectorSector sectorWithColor:blueColor maxValue:10000];//timeout of End Of Speech
    _recSec = [SAMultisectorSector sectorWithColor:greenColor maxValue:60000];//timeout of Recording

    _bosSec.endValue = (double)[IATConfig sharedInstance].vadBos.integerValue;
    
    
    _eosSec.endValue = [IATConfig sharedInstance].vadEos.integerValue;
    _recSec.endValue = [IATConfig sharedInstance].speechTimeout.integerValue;
    
    [_roundSlider addSector:_bosSec];
    [_roundSlider addSector:_eosSec];
    [_roundSlider addSector:_recSec];
    
    _backScrollView.canCancelContentTouches = YES;
    _backScrollView.delaysContentTouches = NO;
    
}


- (void)updateDataView{

    IATConfig *config = [IATConfig sharedInstance];
    config.speechTimeout =  [NSString stringWithFormat:@"%ld", (long)_recSec.endValue];
    config.vadBos =  [NSString stringWithFormat:@"%ld", (long)_bosSec.endValue];
    config.vadEos =  [NSString stringWithFormat:@"%ld", (long)_eosSec.endValue];
    

    _bosLabel.text = config.vadBos;
    _eosLabel.text = config.vadEos;
    _recTimeoutLabel.text = config.speechTimeout;
    
    _recSec.endValue = [config.speechTimeout integerValue];
    _bosSec.endValue = [config.vadBos integerValue];
    _eosSec.endValue = [config.vadEos integerValue];
    
}


-(void)needUpdateView {
    
    IATConfig *instance = [IATConfig sharedInstance];
    
    _recTimeoutLabel.text = instance.speechTimeout;
    _eosLabel.text = instance.vadEos;
    _bosLabel.text = instance.vadBos;
    
    _recSec.endValue = instance.speechTimeout.integerValue;
    _bosSec.endValue = instance.vadBos.integerValue;
    _eosSec.endValue = instance.vadEos.integerValue;
    
    
    //update language and accent
    if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_CHINESE]]) {
        if ([instance.accent isEqualToString:[IFlySpeechConstant ACCENT_CANTONESE]]) {
            [_accentPicker selectItem:0 animated:NO];
            
        }else if ([instance.accent isEqualToString:[IFlySpeechConstant ACCENT_MANDARIN]]) {
            [_accentPicker selectItem:1 animated:NO];
            
        }else if ([instance.accent isEqualToString:[IFlySpeechConstant ACCENT_SICHUANESE]]) {
            [_accentPicker selectItem:3 animated:NO];
            
        }
    }else if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_ENGLISH]]) {
        [_accentPicker selectItem:2 animated:NO];
    }else if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_JAPANESE]]) {
        [_accentPicker selectItem:4 animated:NO];
    }else if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_RUSSIAN]]) {
        [_accentPicker selectItem:5 animated:NO];
    }else if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_FRENCH]]) {
        [_accentPicker selectItem:6 animated:NO];
    }else if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_SPANISH]]) {
        [_accentPicker selectItem:7 animated:NO];
    }else if ([instance.language isEqualToString:[IFlySpeechConstant LANGUAGE_KOREAN]]) {
        [_accentPicker selectItem:8 animated:NO];
    }
    
    //update punctuation setting
    if ([instance.dot isEqualToString:[IFlySpeechConstant ASR_PTT_HAVEDOT]]) {
        _dotSeg.selectedSegmentIndex = 0;
        
    }else if ([instance.dot isEqualToString:[IFlySpeechConstant ASR_PTT_NODOT]]) {
        _dotSeg.selectedSegmentIndex = 1;
        
    }
    
    if([IATConfig sharedInstance].isTranslate){
        _transSeg.selectedSegmentIndex = 0;
    }
    else{
        _transSeg.selectedSegmentIndex = 1;
    }
    
    if (instance.haveView == NO) {
        _viewSeg.selectedSegmentIndex = 0;
        
    }else if (instance.haveView == 1) {
        _viewSeg.selectedSegmentIndex = 1;
        
    }
    
}


#pragma mark - Event Handling

- (void)multisectorValueChanged:(id)sender{
    [self updateDataView];
}


/*
 set recognition view
 */
- (IBAction)viewSegHandler:(id)sender {
    UISegmentedControl *control = sender;
    if (control.selectedSegmentIndex == 0) {
        [IATConfig sharedInstance].haveView = NO;
        
    }else if (control.selectedSegmentIndex == 1) {
        [IATConfig sharedInstance].haveView = YES;
        
    }
}

/*
 set punctuation
 */
- (IBAction)dotSegHandler:(id)sender {
    UISegmentedControl *control = sender;
    
    if (control.selectedSegmentIndex == 0) {
        [IATConfig sharedInstance].dot = [IFlySpeechConstant ASR_PTT_HAVEDOT];
        
    }else if (control.selectedSegmentIndex == 1) {
        [IATConfig sharedInstance].dot = [IFlySpeechConstant ASR_PTT_NODOT];
    }
}

/*
 set whether or not to open translation
 */
- (IBAction)translateSegHandler:(id)sender {
    UISegmentedControl *control = sender;
    
    if (control.selectedSegmentIndex == 0) {
        [IATConfig sharedInstance].isTranslate = YES;
    }else if (control.selectedSegmentIndex == 1) {
        [IATConfig sharedInstance].isTranslate = NO;
    }
}



#pragma mark - AKPickerViewDataSource Delegate

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    IATConfig* instance = [IATConfig sharedInstance];
    return instance.accentNickName.count;
}
- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item;
{
    IATConfig* instance = [IATConfig sharedInstance];
    return  [instance.accentNickName objectAtIndex:item];
}


- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
    IATConfig *instance = [IATConfig sharedInstance];

    if (item == 0) { //Cantonese
        instance.language = [IFlySpeechConstant LANGUAGE_CHINESE];
        instance.accent = [IFlySpeechConstant ACCENT_CANTONESE];
    }else if (item == 1) {//Mandarin
        instance.language = [IFlySpeechConstant LANGUAGE_CHINESE];
        instance.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    }else if (item == 2) {//English
        instance.language = [IFlySpeechConstant LANGUAGE_ENGLISH];
        instance.accent = @"";
    }else if (item == 3) {//Szechuan
        instance.language = [IFlySpeechConstant LANGUAGE_CHINESE];
        instance.accent = [IFlySpeechConstant ACCENT_SICHUANESE];
    }else if (item == 4) {//japanese
        instance.language = [IFlySpeechConstant LANGUAGE_JAPANESE];
        instance.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    }else if (item == 5) {//russian
        instance.language = [IFlySpeechConstant LANGUAGE_RUSSIAN];
        instance.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    }else if (item == 6) {//french
        instance.language = [IFlySpeechConstant LANGUAGE_FRENCH];
        instance.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    }else if (item == 7) {//spanish
        instance.language = [IFlySpeechConstant LANGUAGE_SPANISH];
        instance.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    }else if (item == 8) {//korean
        instance.language = [IFlySpeechConstant LANGUAGE_KOREAN];
        instance.accent = [IFlySpeechConstant ACCENT_MANDARIN];
    }
    
    
}


@end
