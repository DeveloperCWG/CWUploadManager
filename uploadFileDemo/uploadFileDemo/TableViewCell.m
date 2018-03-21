//
//  TableViewCell.m
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/5.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import "TableViewCell.h"
#import "CWUploadTask.h"
#import "CWFileStreamSeparation.h"

@interface TableViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *headImgView;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIButton *startOrStopBtn;

@property (weak, nonatomic) IBOutlet UILabel *uploadStatusLab;

@property (weak, nonatomic) IBOutlet UILabel *uploadSizeLab;

@property (weak, nonatomic) IBOutlet UILabel *rateLab;

@property (nonatomic, copy) NSString *statusText;

@end

@implementation TableViewCell

static NSString *cellId = @"taskCell";

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
    }
    [cell registeNotification];
    return cell;
}

- (void)setUploadTask:(CWUploadTask *)uploadTask
{
    _uploadTask = uploadTask;
    [self refreshUI:_uploadTask.fileStream];
}

#pragma mark - refresh UI
- (void)refreshUI:(CWFileStreamSeparation *)fileStream{
    if (![fileStream.md5String isEqualToString:_uploadTask.ID]) {
        return;
    }
    switch (fileStream.fileStatus) {
        case CWUploadStatusUpdownloading:
            _statusText = @"上传中...";
            break;
        case CWUploadStatusWaiting:
            _statusText = @"等待";
            break;
        case CWUploadStatusFinished:
            _statusText = @"完成";
            break;
        case CWUploadStatusFailed:
            _statusText = @"失败";
            break;
        case CWUploadStatusPaused:
            _statusText = @"暂停";
            break;
        default:
            break;
    }
    _progressView.progress = fileStream.progressRate;
    _uploadSizeLab.text = [NSString stringWithFormat:@"%zd/%zd",fileStream.uploadDateSize,fileStream.fileSize];
    _rateLab.text = [NSString stringWithFormat:@"%.1f%%",fileStream.progressRate*100];
    _uploadStatusLab.text = _statusText;
    if (fileStream.fileStatus == CWUploadStatusUpdownloading) {
        _startOrStopBtn.selected = YES;
    }else{
        _startOrStopBtn.selected = NO;
    }
}

- (void)registeNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskExeIng:) name:CWUploadTaskExeing object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskExeEnd:) name:CWUploadTaskExeEnd object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskExeError:) name:CWUploadTaskExeError object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskExeSupend:) name:CWUploadTaskExeSuspend object:nil];
}

- (void)taskExeIng:(NSNotification *)notification
{
    [self refreshUI:notification.userInfo[@"fileStream"]];
}

- (void)taskExeSupend:(NSNotification *)notification
{
    [self refreshUI:notification.userInfo[@"fileStream"]];
}

- (void)taskExeEnd:(NSNotification *)notification
{
    CWFileStreamSeparation *fs = notification.userInfo.allValues.firstObject;
    [self refreshUI:fs];
}

- (void)taskExeError:(NSNotification *)notification
{
    CWFileStreamSeparation *fs = notification.userInfo[@"fileStream"];
    NSError *error = (NSError *)notification.userInfo[@"error"];
    NSLog(@"%@,%@",fs,error);
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
