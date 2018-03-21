//
//  TableViewController.m
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/5.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import "TableViewController.h"
#import "TableViewCell.h"
#import "CWFileUploadManager.h"
#import "CWFileStreamSeparation.h"
#import "CWUploadTask.h"

@interface TableViewController ()

@property (nonatomic, strong)CWFileUploadManager *uploadManager;

@property (nonatomic, strong)NSMutableArray<CWUploadTask *> *taskArr;

@end

@implementation TableViewController

-(NSMutableArray *)taskArr
{
    if (!_taskArr) {
        _taskArr = [NSMutableArray arrayWithArray:[CWFileUploadManager shardUploadManager].allTasks.allValues];
    }
    return _taskArr;
}

- (CWFileUploadManager *)uploadManager
{
    if (!_uploadManager) {
        _uploadManager = [CWFileUploadManager shardUploadManager];
    }
    return _uploadManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 65.f;
    self.title = [NSString stringWithFormat:@"Task Max:%zd",self.uploadManager.uploadMaxNum];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"TableViewController--dealloc");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.taskArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [TableViewCell cellWithTableView:tableView];
    CWUploadTask *task = self.taskArr[indexPath.row];
    cell.uploadTask = task;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CWUploadTask *task = self.taskArr[indexPath.row];
    CWFileStreamSeparation *fs = task.fileStream;
    switch (fs.fileStatus) {
        case CWUploadStatusWaiting:
            NSLog(@"启动上传");
            [task taskResume];
            break;
        case CWUploadStatusUpdownloading:
            NSLog(@"暂停");
            [task taskCancel];
            break;
        case CWUploadStatusFinished:
            NSLog(@"上传已经完成");
            break;
        case CWUploadStatusFailed:
            NSLog(@"启动上传");
            [task taskResume];
            break;
        case CWUploadStatusPaused:
            NSLog(@"继续上传");
            [task taskResume];
            break;
        default:
            break;
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath

{
    return @"删除";
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.uploadManager removeUploadTask:self.taskArr[indexPath.row].fileStream];
        [self.taskArr removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

    }   
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
