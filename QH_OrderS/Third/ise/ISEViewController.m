//
//  ISEViewController.m
//  MSCDemo_UI
//
//  Created by 张剑 on 15/1/15.
//
//

#import "ISEViewController.h"
#import "ISESettingViewController.h"
#import "PopupView.h"
#import "ISEParams.h"
#import "IFlyMSC/IFlyMSC.h"

#import "ISEResult.h"
#import "ISEResultXmlParser.h"
#import "Definition.h"
#import "IOSToVue.h"
#import "lame.h"

#define _DEMO_UI_MARGIN                  5
#define _DEMO_UI_BUTTON_HEIGHT           49
#define _DEMO_UI_TOOLBAR_HEIGHT          44
#define _DEMO_UI_STATUSBAR_HEIGHT        20

#pragma mark - const values

NSString* const KCTextCNSyllable=@"text_cn_syllable";
NSString* const KCTextCNWord=@"text_cn_word";
NSString* const KCTextCNSentence=@"text_cn_sentence";
NSString* const KCTextENWord=@"text_en_word";
NSString* const KCTextENSentence=@"text_en_sentence";
NSString* const KCAudioPcmName=@"iOS";
NSString* const KCAudioMp3Name=@"iOS.mp3";

#pragma mark -

@interface ISEViewController () <IFlySpeechEvaluatorDelegate ,ISESettingDelegate ,ISEResultXmlParserDelegate,IFlyPcmRecorderDelegate>

@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, assign) CGFloat textViewHeight;
@property (nonatomic, strong) IBOutlet UITextView *resultView;
@property (nonatomic, strong) NSString* resultText;
@property (nonatomic, assign) CGFloat resultViewHeight;

@property (nonatomic, strong) IBOutlet UIButton *startBtn;
@property (nonatomic, strong) IBOutlet UIButton *stopBtn;
@property (nonatomic, strong) IBOutlet UIButton *parseBtn;
@property (nonatomic, strong) IBOutlet UIButton *cancelBtn;

@property (nonatomic, strong) PopupView *popupView;
@property (nonatomic, strong) ISESettingViewController *settingViewCtrl;
@property (nonatomic, strong) IFlySpeechEvaluator *iFlySpeechEvaluator;

@property (nonatomic, assign) BOOL isSessionResultAppear;
@property (nonatomic, assign) BOOL isSessionEnd;

@property (nonatomic, assign) BOOL isValidInput;
@property (nonatomic, assign) BOOL isDidset;

@property (nonatomic,strong) IFlyPcmRecorder *pcmRecorder;//PCM Recorder to be used to demonstrate Audio Stream Evaluation.
@property (nonatomic,assign) BOOL isBeginOfSpeech;//Whether or not SDK has invoke the delegate methods of beginOfSpeech.

@end

@implementation ISEViewController

static NSString *LocalizedEvaString(NSString *key, NSString *comment) {
    return NSLocalizedStringFromTable(key, @"eva/eva", comment);
}

-(void)setExclusiveTouchForButtons:(UIView *)myView
{
    for (UIView * button in [myView subviews]) {
        if([button isKindOfClass:[UIButton class]])
        {
            [((UIButton *)button) setExclusiveTouch:YES];
        }
        else if ([button isKindOfClass:[UIView class]])
        {
            [self setExclusiveTouchForButtons:button];
        }
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [super viewWillAppear:animated];
    self.iFlySpeechEvaluator.delegate = self;
    
    self.isSessionResultAppear=YES;
    self.isSessionEnd=YES;
    self.startBtn.enabled=YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    
    //     unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [self.iFlySpeechEvaluator cancel];
    self.iFlySpeechEvaluator.delegate = nil;
    self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
    self.resultText=@"";
    
    [_pcmRecorder stop];
    _pcmRecorder.delegate = nil;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (IOS7_OR_LATER) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    
    //keyboard
    UIBarButtonItem *spaceBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil
                                                                                  action:nil];
    UIBarButtonItem *hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(onKeyBoardDown:)];
    [hideBtnItem setTintColor:[UIColor whiteColor]];
    UIToolbar *keyboardToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, _DEMO_UI_TOOLBAR_HEIGHT)];
    keyboardToolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray *array = [NSArray arrayWithObjects:spaceBtnItem, hideBtnItem, nil];
    [keyboardToolbar setItems:array];
    self.textView.inputAccessoryView = keyboardToolbar;
    
    self.textView.layer.cornerRadius = 8;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor =[[UIColor whiteColor] CGColor];
    
    self.resultView.layer.cornerRadius = 8;
    self.resultView.layer.borderWidth = 1;
    self.resultView.layer.borderColor =[[UIColor whiteColor] CGColor];
    [self.resultView setEditable:NO];
    
    self.popupView = [[PopupView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    self.popupView.ParentView = self.view;
    
    
    if (!self.iFlySpeechEvaluator) {
        self.iFlySpeechEvaluator = [IFlySpeechEvaluator sharedInstance];
    }
    self.iFlySpeechEvaluator.delegate = self;
    //empty params
    [self.iFlySpeechEvaluator setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    _isSessionResultAppear=YES;
    _isSessionEnd=YES;
    _isValidInput=YES;
    self.iseParams=[ISEParams fromUserDefaults];
    [self reloadCategoryText];
    
    //Initialize recorder
    if (_pcmRecorder == nil)
    {
        _pcmRecorder = [IFlyPcmRecorder sharedInstance];
    }
    
    _pcmRecorder.delegate = self;
    
    [_pcmRecorder setSample:@"16000"];
    
    [self setExclusiveTouchForButtons:self.view];
    
    self.textView.text = _read_content;
}

-(void)reloadCategoryText{
    
    [self.iFlySpeechEvaluator setParameter:@"10000" forKey:[IFlySpeechConstant VAD_BOS]];
    [self.iFlySpeechEvaluator setParameter:@"10000" forKey:[IFlySpeechConstant VAD_EOS]];
    [self.iFlySpeechEvaluator setParameter:@"read_chapter" forKey:[IFlySpeechConstant ISE_CATEGORY]];
    [self.iFlySpeechEvaluator setParameter:@"zh_cn" forKey:[IFlySpeechConstant LANGUAGE]];
    [self.iFlySpeechEvaluator setParameter:@"complete" forKey:[IFlySpeechConstant ISE_RESULT_LEVEL]];
    [self.iFlySpeechEvaluator setParameter:@"-1" forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    [self.iFlySpeechEvaluator setParameter:@"1" forKey:[IFlySpeechConstant AUDIO_SOURCE]];
    
    if ([self.iseParams.language isEqualToString:KCLanguageZHCN]) {
        if ([self.iseParams.category isEqualToString:KCCategorySyllable]) {
            self.textView.text = LocalizedEvaString(KCTextCNSyllable, nil);
        }
        else if ([self.iseParams.category isEqualToString:KCCategoryWord]) {
            self.textView.text = LocalizedEvaString(KCTextCNWord, nil);
        }
        else {
            self.textView.text = LocalizedEvaString(KCTextCNSentence, nil);
        }
    }
    else {
        if ([self.iseParams.category isEqualToString:KCCategoryWord]) {
            self.textView.text = LocalizedEvaString(KCTextENWord, nil);
        }
        else {
            self.textView.text = LocalizedEvaString(KCTextENSentence, nil);
        }
        self.isValidInput=YES;
        
    }
}

-(void)resetBtnSatus:(IFlySpeechError *)errorCode{
    
    if(errorCode && errorCode.errorCode!=0){
        self.isSessionResultAppear=NO;
        self.isSessionEnd=YES;
        self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
        self.resultText=@"";
    }else{
        if(self.isSessionResultAppear == NO){
            self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
            self.resultText=@"";
        }
        self.isSessionResultAppear=YES;
        self.isSessionEnd=YES;
    }
    self.startBtn.enabled=YES;
}

#pragma mark - keyboard

-(void)onKeyBoardDown:(id) sender{
    [self.textView resignFirstResponder];
}


-(void)setViewSize:(BOOL)show Notification:(NSNotification*) notification{
    
    if (!self.isDidset){
        self.textViewHeight = self.textView.frame.size.height;
        self.resultViewHeight = self.resultView.frame.size.height;
        self.isDidset = YES;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    int keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    CGRect textRect = self.textView.frame;
    CGRect resultRect = self.resultView.frame;
    if (show) {
        textRect.size.height = self.view.frame.size.height - keyboardHeight - _DEMO_UI_MARGIN*4;
        resultRect.size.height = 0;
    }
    else{
        textRect.size.height = self.textViewHeight;
        resultRect.size.height = self.resultViewHeight;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3]; // if you want to slide up the view
        
        self.textView.frame = textRect;
        self.resultView.frame=resultRect;
        
        [UIView commitAnimations];
    });
    
}

-(void)keyboardWillShow:(NSNotification *)notification {
    [self setViewSize:YES Notification:notification];
}

-(void)keyboardWillHide :(NSNotification *)notification{
    [self setViewSize:NO Notification:notification];
}


#pragma mark - Button handler

/*!
 *  Setting
 */
- (IBAction)onSetting:(id)sender {
    if (!self.settingViewCtrl) {
        self.settingViewCtrl = [[ISESettingViewController alloc] initWithStyle:UITableViewStylePlain];
        self.settingViewCtrl.delegate = self;
    }
    
    if (![[self.navigationController topViewController] isKindOfClass:[ISESettingViewController class]]){
        [self.navigationController pushViewController:self.settingViewCtrl animated:YES];
    }
    
}

/*!
 *  start recorder
 */
- (IBAction)onBtnStart:(id)sender {
    
    NSLog(@"%s[IN]",__func__);
    [self.iFlySpeechEvaluator setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
    [self.iFlySpeechEvaluator setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    [self.iFlySpeechEvaluator setParameter:@"xml" forKey:[IFlySpeechConstant ISE_RESULT_TYPE]];
    [self.iFlySpeechEvaluator setParameter:KCAudioPcmName forKey:[IFlySpeechConstant ISE_AUDIO_PATH]];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSLog(@"text encoding:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]]);
    NSLog(@"language:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]]);
    
    BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]] isEqualToString:@"utf-8"];
    BOOL isZhCN=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]] isEqualToString:KCLanguageZHCN];
    
    BOOL needAddTextBom=isUTF8&&isZhCN;
    NSMutableData *buffer = nil;
    if(needAddTextBom){
        self.textView.text = _read_content;
        if(self.textView.text && [self.textView.text length]>0){
            Byte bomHeader[] = { 0xEF, 0xBB, 0xBF };
            buffer = [NSMutableData dataWithBytes:bomHeader length:sizeof(bomHeader)];
            [buffer appendData:[self.textView.text dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@" \ncn buffer length: %lu",(unsigned long)[buffer length]);
        }
    }else{
        buffer= [NSMutableData dataWithData:[self.textView.text dataUsingEncoding:encoding]];
        NSLog(@" \nen buffer length: %lu",(unsigned long)[buffer length]);
    }
    self.resultView.text = NSLocalizedString(@"M_ISE_Noti2", nil);
    self.resultText=@"";
    
    BOOL ret = [self.iFlySpeechEvaluator startListening:buffer params:nil];
    if(ret){
        self.isSessionResultAppear=NO;
        self.isSessionEnd=NO;
        self.startBtn.enabled=NO;
        
        //Set audio stream as audio source,which requires the developer import audio data into the recognition control by self through "writeAudio:".
        if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
            
            _isBeginOfSpeech = NO;
            //set the category of AVAudioSession
            [IFlyAudioSession initRecordingAudioSession];
            
            _pcmRecorder.delegate = self;
            
            //start recording
            BOOL ret = [_pcmRecorder start];
            
            NSLog(@"%s[OUT],Success,Recorder ret=%d",__func__,ret);
        }
    }
}

/*!
 *  stop recording
 */
- (IBAction)onBtnStop:(id)sender {
    
    if(!self.isSessionResultAppear &&  !self.isSessionEnd){
        self.resultView.text = NSLocalizedString(@"M_ISE_Noti3", nil);
        self.resultText=@"";
    }
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM] && !_isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
    [self.iFlySpeechEvaluator stopListening];
    [self.resultView resignFirstResponder];
    [self.textView resignFirstResponder];
    self.startBtn.enabled=YES;
}

- (NSString *)getCachesPcmPath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:KCAudioPcmName];
    return filePath;
}

- (NSString *)getCachesMp3Path {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:KCAudioMp3Name];
    return filePath;
}

- (NSString *)getCaches {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return path;
}

- (NSString *)getDocument {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return path;
}

/*!
 *  cancel speech evaluation
 */
- (IBAction)onBtnCancel:(id)sender {
    
    NSString *string = [self getCaches];
    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:string error:nil];
    NSLog(@"%@", fileList);
    
    NSString *filePath = [self getCachesPcmPath];
    NSFileManager  *fileMananger = [NSFileManager defaultManager];
    if ([fileMananger fileExistsAtPath:filePath]) {
        NSDictionary *dic = [fileMananger attributesOfItemAtPath:filePath error:nil];
        NSLog(@"%lld", [dic[@"NSFileSize"] longLongValue]);
    }
    
    //    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM] && !_isBeginOfSpeech){
    //        NSLog(@"%s,stop recording",__func__);
    //        [_pcmRecorder stop];
    //    }
    //
    //	[self.iFlySpeechEvaluator cancel];
    //	[self.resultView resignFirstResponder];
    //    [self.textView resignFirstResponder];
    //	[self.popupView removeFromSuperview];
    //    self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
    //    self.resultText=@"";
    //    self.startBtn.enabled=YES;
}


/*!
 *  parse results
 */
- (IBAction)onBtnParse:(id)sender {
    
    ISEResultXmlParser* parser=[[ISEResultXmlParser alloc] init];
    parser.delegate=self;
    [parser parserXml:self.resultText];
    
}


#pragma mark - ISESettingDelegate

/*!
 *  callback of ISE setting
 */
- (void)onParamsChanged:(ISEParams *)params {
    self.iseParams=params;
    [self performSelectorOnMainThread:@selector(reloadCategoryText) withObject:nil waitUntilDone:NO];
}

#pragma mark - IFlySpeechEvaluatorDelegate

/*!
 *  volume callback,range from 0 to 30.
 */
- (void)onVolumeChanged:(int)volume buffer:(NSData *)buffer {
    //    NSLog(@"volume:%d",volume);
    [self.popupView setText:[NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),volume]];
    [self.view addSubview:self.popupView];
}

/*!
 *  Beginning Of Speech
 */
- (void)onBeginOfSpeech {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
        _isBeginOfSpeech =YES;
    }
    
}

/*!
 *  End Of Speech
 */
- (void)onEndOfSpeech {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
        [_pcmRecorder stop];
    }
    
}

/*!
 *  callback of canceling evaluation
 */
- (void)onCancel {
    
}

/*!
 *  evaluation session completion, which will be invoked no matter whether it exits error.
 *  error.errorCode =
 *  0     success
 *  other fail
 */
- (void)onCompleted:(IFlySpeechError *)errorCode {
    if(errorCode && errorCode.errorCode!=0){
        [self.popupView setText:[NSString stringWithFormat:@"Error：%d %@",[errorCode errorCode],[errorCode errorDesc]]];
        [self.view addSubview:self.popupView];
        
    }
    
    [self performSelectorOnMainThread:@selector(resetBtnSatus:) withObject:errorCode waitUntilDone:NO];
    
}

/*!
 *  result callback of speech evaluation
 *  results：evaluation results
 *  isLast：whether or not this is the last result
 */
- (void)onResults:(NSData *)results isLast:(BOOL)isLast{
    
    if (results) {
        
        NSString *showText = @"";
        const char* chResult=[results bytes];
        BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant RESULT_ENCODING]]isEqualToString:@"utf-8"];
        NSString* strResults=nil;
        if(isUTF8){
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:NSUTF8StringEncoding];
        }else{
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:encoding];
        }
        if(strResults){
            
            NSData *data = [strResults dataUsingEncoding:NSUTF8StringEncoding];
            NSString *stringBase64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]; // base64格式的字符串
            
            // pcm转mp3
            [self audio_PCMtoMP3:[self getCachesMp3Path] andPcmPath:[self getCachesPcmPath]];
            NSString *filePath = [self getCachesMp3Path];
            NSData *mp3Data = [[NSData alloc] initWithContentsOfFile: filePath];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                sleep(3);
                dispatch_async(dispatch_get_main_queue(), ^{

                    
                    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/jpeg", nil];
                    __weak __typeof(self)weakSelf = self;
                    [manager POST:@"https://ise.yocou.com/index.php?type=yp_url" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                        [formData appendPartWithFileData:mp3Data name:@"file" fileName:KCAudioMp3Name mimeType:@"audio/wav"];
                    } progress:^(NSProgress * _Nonnull uploadProgress) {
                        NSLog(@"上传进度：%@", uploadProgress);
                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        NSLog(@"上传成功：%@", responseObject);
                        [IOSToVue TellVueReadGswXml:self->_webView andXml:stringBase64 andMp3Path:responseObject[@"data"]];
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        NSLog(@"上传失败");
                    }];
                });
            });
            showText = [showText stringByAppendingString:strResults];
        }
        self.resultText=showText;
        self.resultView.text = showText;
        self.isSessionResultAppear=YES;
        self.isSessionEnd=YES;
        if(isLast){
            [self.popupView setText: NSLocalizedString(@"T_ISE_End", nil)];
            [self.view addSubview:self.popupView];
        }
    }
    else{
        if(isLast){
            [self.popupView setText: NSLocalizedString(@"M_ISE_Msg", nil)];
            [self.view addSubview:self.popupView];
        }
        self.isSessionEnd=YES;
    }
    self.startBtn.enabled=YES;
}

#pragma mark - ISEResultXmlParserDelegate

-(void)onISEResultXmlParser:(NSXMLParser *)parser Error:(NSError*)error{
    
}

-(void)onISEResultXmlParserResult:(ISEResult*)result{
    self.resultView.text=[result toString];
}


#pragma mark - IFlyPcmRecorderDelegate

- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size
{
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    int ret = [self.iFlySpeechEvaluator writeAudio:audioBuffer];
    if (!ret)
    {
        [self.iFlySpeechEvaluator stopListening];
    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error
{
    NSLog(@"fds");
}

//range from 0 to 30
- (void) onIFlyRecorderVolumeChanged:(int) power
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.popupView setText:[NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),power]];
        [self.view addSubview:self.popupView];
    });
}

- (void)audio_PCMtoMP3:(NSString *)mp3_path andPcmPath:(NSString *)pcm_path {
    
    NSString *mp3FilePath = mp3_path;
    NSString *_recordFilePath = pcm_path;
    @try {
        int read, write;
        FILE *pcm = fopen([_recordFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;//8192
        const int MP3_SIZE = 8192;//8192
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 7500.0);//采样播音速度，值越大播报速度越快，反之。
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0) {
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            }else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            fwrite(mp3_buffer, write, 1, mp3);
        } while (read != 0);
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        NSLog(@"pcm转mp3成功");
    }
    @catch (NSException *exception) {
        NSLog(@"pcm转mp3失败%@",[exception description]);
    }
}
@end
