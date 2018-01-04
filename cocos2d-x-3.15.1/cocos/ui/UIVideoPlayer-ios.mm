/****************************************************************************
 Copyright (c) 2014-2017 Chukong Technologies Inc.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "ui/UIVideoPlayer.h"

// No Available on tvOS
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS && !defined(CC_TARGET_OS_TVOS)

using namespace cocos2d::experimental::ui;
//-------------------------------------------------------------------------------------

#include "platform/ios/CCEAGLView-ios.h"
#import <MediaPlayer/MediaPlayer.h>
#include "base/CCDirector.h"
#include "platform/CCFileUtils.h"

@interface UIVideoViewWrapperIos : NSObject

@property (strong,nonatomic) MPMoviePlayerController * moviePlayer;

- (void) setFrame:(int) left :(int) top :(int) width :(int) height;
- (void) setURL:(int) videoSource :(std::string&) videoUrl;
- (void) play;
- (void) pause;
- (void) resume;
- (void) stop;
- (void) seekTo:(float) sec;
- (void) setVisible:(BOOL) visible;
- (void) setKeepRatioEnabled:(BOOL) enabled;
- (void) setFullScreenEnabled:(BOOL) enabled;
- (BOOL) isFullScreenEnabled;

-(id) init:(void*) videoPlayer;

-(void) videoFinished:(NSNotification*) notification;
-(void) playStateChange;


@end

@implementation UIVideoViewWrapperIos
{
    int _left;
    int _top;
    int _width;
    int _height;
    bool _keepRatioEnabled;

    VideoPlayer* _videoPlayer;
    UIVisualEffectView *_effectView;
    NSTimer *_timerCheck;
    UIActivityIndicatorView *_activitiIndicatorView;
}

-(id)init:(void*)videoPlayer
{
    if (self = [super init]) {
        self.moviePlayer = nullptr;
        _videoPlayer = (VideoPlayer*)videoPlayer;
        _keepRatioEnabled = false;
    }

    return self;
}

-(void) dealloc
{
    if (self.moviePlayer != nullptr) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];

        [self.moviePlayer stop];
        [self.moviePlayer.view removeFromSuperview];
        self.moviePlayer = nullptr;
        _videoPlayer = nullptr;
    }
    [super dealloc];
}

-(void) setFrame:(int)left :(int)top :(int)width :(int)height
{
    _left = left;
    _width = width;
    _top = top;
    _height = height;
    if (self.moviePlayer != nullptr) {
        [self.moviePlayer.view setFrame:CGRectMake(left, top, width, height)];
    }
}

-(void) setFullScreenEnabled:(BOOL) enabled
{
    if (self.moviePlayer != nullptr) {
        [self.moviePlayer setFullscreen:enabled animated:(true)];
    }
}

-(BOOL) isFullScreenEnabled
{
    if (self.moviePlayer != nullptr) {
        return [self.moviePlayer isFullscreen];
    }

    return false;
}

-(void) setURL:(int)videoSource :(std::string &)videoUrl
{
    if (self.moviePlayer != nullptr) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];

        [self.moviePlayer stop];
        [self.moviePlayer.view removeFromSuperview];
        self.moviePlayer = nullptr;
    }

    if (videoSource == 1) {
        self.moviePlayer = [[[MPMoviePlayerController alloc] init] autorelease];
        self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
        [self.moviePlayer setContentURL:[NSURL URLWithString:@(videoUrl.c_str())]];
    } else {
        self.moviePlayer = [[[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:@(videoUrl.c_str())]] autorelease];
        self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    }
    self.moviePlayer.allowsAirPlay = false;
    self.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    self.moviePlayer.view.userInteractionEnabled = true;

    auto clearColor = [UIColor clearColor];
    self.moviePlayer.backgroundView.backgroundColor = clearColor;
    self.moviePlayer.view.backgroundColor = clearColor;
    for (UIView * subView in self.moviePlayer.view.subviews) {
        subView.backgroundColor = clearColor;
    }

    if (_keepRatioEnabled) {
        self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    } else {
        self.moviePlayer.scalingMode = MPMovieScalingModeFill;
    }

    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    auto eaglview = (CCEAGLView *) view->getEAGLView();
    [eaglview addSubview:self.moviePlayer.view];
    
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _effectView = [[UIVisualEffectView alloc]initWithEffect:effect];
    _effectView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 45);
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    UIVisualEffectView *contentEffectView = [[UIVisualEffectView alloc]initWithEffect:vibrancyEffect];
    contentEffectView.frame = _effectView.bounds;
    [_effectView addSubview:contentEffectView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self bp_imageNamed:@"game_videoPlayer_back_selected"] forState:UIControlStateSelected];
    [button setImage:[self bp_imageNamed:@"game_videoPlayer_back"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    CGFloat buttonWH = 45;
    [button setFrame:CGRectMake(15, 0, buttonWH, buttonWH)];
    [contentEffectView.contentView addSubview:button];
    
    UILabel *titleLab = [[UILabel alloc]initWithFrame:CGRectMake(80, 0, 120, buttonWH)];
    titleLab.text = @"竹兜说育儿";
    [contentEffectView.contentView addSubview:titleLab];
    
    _activitiIndicatorView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-buttonWH-20, 0, buttonWH, buttonWH)];
    _activitiIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _activitiIndicatorView.hidesWhenStopped = YES;
    [_activitiIndicatorView startAnimating];
    
    [contentEffectView.contentView addSubview:_activitiIndicatorView];
    
    
    [self.moviePlayer.view addSubview:_effectView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStateChange) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
    
    _timerCheck = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkShowControls) userInfo:nil repeats:YES];
    [_timerCheck fire];
}

-(void)checkShowControls
{
    BOOL showControls = false;
    do{
        NSArray* viewSub = _moviePlayer.view.subviews;
        if (!viewSub || viewSub.count<=0 || !viewSub[0])
            break;
        
        UIView* swapview =viewSub[0];
        viewSub = swapview.subviews;
        if (!viewSub || viewSub.count<=0 || !viewSub[0])
            break;
        
        UIView* videoConView = viewSub[0];
        viewSub =videoConView.subviews;
        if (!viewSub || viewSub.count<4 || !viewSub[3])
            break;
        
        
        UIView* tmpview = viewSub[3];
        
        CGRect rect = [tmpview convertRect:tmpview.frame fromView:nil];
        if (CGRectIsEmpty(rect) || CGRectIsNull(rect))
            break;
        // ios6此处就可能检测出是否隐藏
        if (tmpview.hidden)
            break;
        
        if (CGSizeEqualToSize(rect.size, CGSizeZero))
            break;
        // ios6以上需要此处来检测
        if (viewSub.count>=5) {
            tmpview = viewSub[4];
            if (CGRectIsEmpty(rect) || CGRectIsNull(rect))
                break;
            
            if (tmpview.hidden)
                break;
            
            if (CGSizeEqualToSize(rect.size, CGSizeZero))
                break;
        }
        
        showControls = true;
    }while (0);
    [self setControlsShow:showControls];
}
-(void)setControlsShow:(BOOL)show
{
    _effectView.hidden = !show;
}

-(void)backAction
{
    if (_timerCheck) {
        [_timerCheck invalidate];
        _timerCheck = nil;
    }
    if (_effectView) {
        [_effectView removeFromSuperview];
    }
    if (_videoPlayer) {
        _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::BACK);
    }
}

 -(UIImage *)bp_imageNamed:(NSString*)imgName
{
    NSString* mainPath = [[NSBundle mainBundle] resourcePath];
    NSString* imgPath = [mainPath stringByAppendingPathComponent:imgName];
    UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
    if (img) {
        return img;
    }
    img = [UIImage imageWithContentsOfFile:[imgPath stringByAppendingString:@"@2x.png"]];
    if (img) {
        return img;
    }
    img = [UIImage imageWithContentsOfFile:[imgPath stringByAppendingString:@"@3x.png"]];
    if (img) {
        return img;
    }
    return [[UIImage alloc]init];
}



-(void) videoFinished:(NSNotification *)notification
{
    if(_videoPlayer != nullptr)
    {
        if([self.moviePlayer playbackState] != MPMoviePlaybackStateStopped)
        {
            _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::COMPLETED);
            [self backAction];
        }
    }
}

-(void) playStateChange
{
    MPMoviePlaybackState state = [self.moviePlayer playbackState];
    switch (state) {
        case MPMoviePlaybackStatePaused:
            _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::PAUSED);
            [_activitiIndicatorView startAnimating];
            break;
        case MPMoviePlaybackStateStopped:
            _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::STOPPED);
            [_activitiIndicatorView startAnimating];
            break;
        case MPMoviePlaybackStatePlaying:
            _videoPlayer->onPlayEvent((int)VideoPlayer::EventType::PLAYING);
            [_activitiIndicatorView stopAnimating];
            break;
        case MPMoviePlaybackStateInterrupted:
            [_activitiIndicatorView startAnimating];
            break;
        case MPMoviePlaybackStateSeekingBackward:
            [_activitiIndicatorView startAnimating];
            break;
        case MPMoviePlaybackStateSeekingForward:
            [_activitiIndicatorView startAnimating];
            break;
        default:
            break;
    }
}

-(void) seekTo:(float)sec
{
    if (self.moviePlayer != NULL) {
        [self.moviePlayer setCurrentPlaybackTime:(sec)];
    }
}

-(void) setVisible:(BOOL)visible
{
    if (self.moviePlayer != NULL) {
        [self.moviePlayer.view setHidden:!visible];
    }
}

-(void) setKeepRatioEnabled:(BOOL)enabled
{
    _keepRatioEnabled = enabled;
    if (self.moviePlayer != NULL) {
        if (enabled) {
            self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
        } else {
            self.moviePlayer.scalingMode = MPMovieScalingModeFill;
        }
    }
}

-(void) play
{
    if (self.moviePlayer != NULL) {
        [self.moviePlayer.view setFrame:CGRectMake(_left, _top, _width, _height)];
        [self.moviePlayer play];
    }
}

-(void) pause
{
    if (self.moviePlayer != NULL) {
        [self.moviePlayer pause];
    }
}

-(void) resume
{
    if (self.moviePlayer != NULL) {
        if([self.moviePlayer playbackState] == MPMoviePlaybackStatePaused)
        {
            [self.moviePlayer play];
        }
    }
}

-(void) stop
{
    if (self.moviePlayer != NULL) {
        [self.moviePlayer stop];
    }
}

@end
//------------------------------------------------------------------------------------------------------------

VideoPlayer::VideoPlayer()
: _isPlaying(false)
, _fullScreenDirty(false)
, _fullScreenEnabled(false)
, _keepAspectRatioEnabled(false)
, _videoPlayerIndex(-1)
, _eventCallback(nullptr)
{
    _videoView = [[UIVideoViewWrapperIos alloc] init:this];

#if CC_VIDEOPLAYER_DEBUG_DRAW
    _debugDrawNode = DrawNode::create();
    addChild(_debugDrawNode);
#endif
}

VideoPlayer::~VideoPlayer()
{
    if(_videoView)
    {
        [((UIVideoViewWrapperIos*)_videoView) dealloc];
    }
}

void VideoPlayer::setFileName(const std::string& fileName)
{
    _videoURL = FileUtils::getInstance()->fullPathForFilename(fileName);
    _videoSource = VideoPlayer::Source::FILENAME;
    [((UIVideoViewWrapperIos*)_videoView) setURL:(int)_videoSource :_videoURL];
}

void VideoPlayer::setURL(const std::string& videoUrl)
{
    _videoURL = videoUrl;
    _videoSource = VideoPlayer::Source::URL;
    [((UIVideoViewWrapperIos*)_videoView) setURL:(int)_videoSource :_videoURL];
}

void VideoPlayer::draw(Renderer* renderer, const Mat4 &transform, uint32_t flags)
{
    cocos2d::ui::Widget::draw(renderer,transform,flags);

    if (flags & FLAGS_TRANSFORM_DIRTY)
    {
        auto directorInstance = Director::getInstance();
        auto glView = directorInstance->getOpenGLView();
        auto frameSize = glView->getFrameSize();
        auto scaleFactor = [static_cast<CCEAGLView *>(glView->getEAGLView()) contentScaleFactor];

        auto winSize = directorInstance->getWinSize();

        auto leftBottom = convertToWorldSpace(Vec2::ZERO);
        auto rightTop = convertToWorldSpace(Vec2(_contentSize.width,_contentSize.height));

        auto uiLeft = (frameSize.width / 2 + (leftBottom.x - winSize.width / 2 ) * glView->getScaleX()) / scaleFactor;
        auto uiTop = (frameSize.height /2 - (rightTop.y - winSize.height / 2) * glView->getScaleY()) / scaleFactor;

        [((UIVideoViewWrapperIos*)_videoView) setFrame :uiLeft :uiTop
                                                          :(rightTop.x - leftBottom.x) * glView->getScaleX() / scaleFactor
                                                          :( (rightTop.y - leftBottom.y) * glView->getScaleY()/scaleFactor)];
    }

#if CC_VIDEOPLAYER_DEBUG_DRAW
    _debugDrawNode->clear();
    auto size = getContentSize();
    Point vertices[4]=
    {
        Point::ZERO,
        Point(size.width, 0),
        Point(size.width, size.height),
        Point(0, size.height)
    };
    _debugDrawNode->drawPoly(vertices, 4, true, Color4F(1.0, 1.0, 1.0, 1.0));
#endif
}

bool VideoPlayer::isFullScreenEnabled()const
{
    return [((UIVideoViewWrapperIos*)_videoView) isFullScreenEnabled];
}

void VideoPlayer::setFullScreenEnabled(bool enabled)
{
    [((UIVideoViewWrapperIos*)_videoView) setFullScreenEnabled:enabled];
}

void VideoPlayer::setKeepAspectRatioEnabled(bool enable)
{
    if (_keepAspectRatioEnabled != enable)
    {
        _keepAspectRatioEnabled = enable;
        [((UIVideoViewWrapperIos*)_videoView) setKeepRatioEnabled:enable];
    }
}

void VideoPlayer::play()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) play];
    }
}

void VideoPlayer::pause()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) pause];
    }
}

void VideoPlayer::resume()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) resume];
    }
}

void VideoPlayer::stop()
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) stop];
    }
}

void VideoPlayer::seekTo(float sec)
{
    if (! _videoURL.empty())
    {
        [((UIVideoViewWrapperIos*)_videoView) seekTo:sec];
    }
}

bool VideoPlayer::isPlaying() const
{
    return _isPlaying;
}

void VideoPlayer::setVisible(bool visible)
{
    cocos2d::ui::Widget::setVisible(visible);

    if (!visible)
    {
        [((UIVideoViewWrapperIos*)_videoView) setVisible:NO];
    }
    else if(isRunning())
    {
        [((UIVideoViewWrapperIos*)_videoView) setVisible:YES];
    }
}

void VideoPlayer::onEnter()
{
    Widget::onEnter();
    if (isVisible())
    {
        [((UIVideoViewWrapperIos*)_videoView) setVisible: YES];
    }
}

void VideoPlayer::onExit()
{
    Widget::onExit();
    [((UIVideoViewWrapperIos*)_videoView) setVisible: NO];
}

void VideoPlayer::addEventListener(const VideoPlayer::ccVideoPlayerCallback& callback)
{
    _eventCallback = callback;
}

void VideoPlayer::onPlayEvent(int event)
{
    if (event == (int)VideoPlayer::EventType::PLAYING) {
        _isPlaying = true;
    } else {
        _isPlaying = false;
    }

    if (_eventCallback)
    {
        _eventCallback(this, (VideoPlayer::EventType)event);
    }
}

cocos2d::ui::Widget* VideoPlayer::createCloneInstance()
{
    return VideoPlayer::create();
}

void VideoPlayer::copySpecialProperties(Widget *widget)
{
    VideoPlayer* videoPlayer = dynamic_cast<VideoPlayer*>(widget);
    if (videoPlayer)
    {
        _isPlaying = videoPlayer->_isPlaying;
        _fullScreenEnabled = videoPlayer->_fullScreenEnabled;
        _fullScreenDirty = videoPlayer->_fullScreenDirty;
        _videoURL = videoPlayer->_videoURL;
        _keepAspectRatioEnabled = videoPlayer->_keepAspectRatioEnabled;
        _videoSource = videoPlayer->_videoSource;
        _videoPlayerIndex = videoPlayer->_videoPlayerIndex;
        _eventCallback = videoPlayer->_eventCallback;
        _videoView = videoPlayer->_videoView;
    }
}

#endif
