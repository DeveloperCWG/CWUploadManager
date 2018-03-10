//
//  TableViewCell.h
//  uploadFileDemo
//
//  Created by hyjet on 2018/3/5.
//  Copyright © 2018年 uploadFileDemo. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CWUploadTask;

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong)CWUploadTask *uploadTask;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
