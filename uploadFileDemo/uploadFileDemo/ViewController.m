//
//  ViewController.m
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/5.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import "ViewController.h"
#import "CWFileManager.h"
#import "CWFileStreamSeparation.h"
#import "CWFileUploadManager.h"
#import "CWUploadTask.h"

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *videoPathLab;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"uploadWaitTasks:%@",[CWFileUploadManager shardUploadManager].uploadWaitTasks);
    NSLog(@"uploadEndTasks:%@",[CWFileUploadManager shardUploadManager].uploadEndTasks);
    NSLog(@"uploadingTasks:%@",[CWFileUploadManager shardUploadManager].uploadingTasks);
}

- (IBAction)selectVideo:(UIButton *)sender {
    NSLog(@"从相册选择");
    UIImagePickerController *picker=[[UIImagePickerController alloc] init];
    
    picker.delegate=self;
    picker.allowsEditing=NO;
    picker.videoMaximumDuration = 1.0;//视频最长长度
    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;//视频质量
    
    //媒体类型：@"public.movie" 为视频  @"public.image" 为图片
    //这里只选择展示视频
    picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    
    picker.sourceType= UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    [self presentViewController:picker animated:YES completion:^{
        
    }];
    
}

- (IBAction)startExeUpload:(UIButton *)sender {
    CWUploadTask *task = [[CWFileUploadManager shardUploadManager] createUploadTask:self.videoPathLab.text];
    [task taskResume];
}

- (NSMutableURLRequest *)setUpRequest{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/upload/file",CURRENT_API]];
    NSMutableURLRequest* request=[NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod=@"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",@"1a2b3c"] forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"v1" forHTTPHeaderField:@"api_version"];
    return request;
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"]){
        //如果是视频
        NSURL *url = info[UIImagePickerControllerMediaURL];//获得视频的URL
        //保存至沙盒路径
        NSString *fileFolder = [[CWFileManager cachesDir] stringByAppendingString:@"/video"];
        if (![CWFileManager isExistsAtPath:fileFolder]) {
            [CWFileManager createDirectoryAtPath:fileFolder];
        }
        NSString *originalPath = [url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [CWFileStreamSeparation fileKeyMD5WithPath:originalPath]];
        NSString *sandboxPath = [fileFolder stringByAppendingPathComponent:videoName];
        [CWFileManager moveItemAtPath:originalPath toPath:sandboxPath overwrite:YES error:nil];
        NSLog(@"url %@",url);
        self.videoPathLab.text = sandboxPath;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
