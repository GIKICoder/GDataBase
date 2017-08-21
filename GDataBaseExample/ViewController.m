//
//  ViewController.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "ViewController.h"
#import "GDataBase.h"
#import "NSJSONSerialization+Utils.h"
#import "GAppsDataViewModel.h"
#import "SQLiteReserveModel.h"
#import "GMutilKeyModel.h"
#import "GBlackListModel.h"
#import "GAutoPrimaryKeyModel.h"
#import "GTableA.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) GDataBase * database;
@property (nonatomic, strong) NSArray * models;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadDataBase];
    [self loadData];
    [self.view addSubview:({
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView;
    })];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)loadDataBase
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingString:@"GDATA.db"];
    self.database = [GDataBase databaseWithPath:path];
}

- (void)loadData
{
    NSArray *modelJsons = [NSJSONSerialization JSONObjectWithContentsOfFile:@"model.json"];
    
    self.models = [NSArray yy_modelArrayWithClass:[GAppsDataViewModel class] json:modelJsons];

}


#pragma mark -- TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tableViewCell"];
        }
    cell.textLabel.text = @"  ";
    if (indexPath.row == 0) {
        cell.textLabel.text = @"单条数据插入";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"批量数据插入(不开始事务)";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"批量数据插入(开始事务)";
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"全部数据读取";
    } else if (indexPath.row == 4) {
        cell.textLabel.text = @"数据条件查询";
    }else if (indexPath.row == 5) {
        cell.textLabel.text = @"排序和limit";
    }else if (indexPath.row == 6) {
        cell.textLabel.text = @"update";
    }else if (indexPath.row == 7) {
        cell.textLabel.text = @"多条件查询";
    }else if (indexPath.row == 8) {
        cell.textLabel.text = @"sqlite 保留关键字测试 存储";
    }else if (indexPath.row == 9) {
        cell.textLabel.text = @"sqlite 保留关键字测试 读取";
    }else if (indexPath.row == 10) {
        cell.textLabel.text = @"sqlite 存储模型黑名单处理";
    }else if (indexPath.row == 11) {
        cell.textLabel.text = @"sqlite 读取模型黑名单处理";
    }else if (indexPath.row == 12) {
        cell.textLabel.text = @"sqlite 多主键表创建存储";
    }else if (indexPath.row == 13) {
        cell.textLabel.text = @"sqlite 多主键表读取";
    }else if (indexPath.row == 14) {
        cell.textLabel.text = @"sqlite 自增主键列表";
    }else if (indexPath.row == 15) {
        cell.textLabel.text = @"数据表 count 字段查询";
    }else if (indexPath.row == 16) {
        cell.textLabel.text = @"从数据库中删除模型";
        
    }else if (indexPath.row == 17) {
        cell.textLabel.text = @"从数据库中查询字典集合";
    } else if (indexPath.row == 18) {
        cell.textLabel.text = @"数据嵌套存储";
    }
    return cell;
}


#pragma mark -- TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        [self insertOneRowData];
    } else if (indexPath.row == 1) {
        [self insertLargeDataNOInTransaction];
    } else if (indexPath.row == 2) {
        [self insertLargeData];
    } else if (indexPath.row == 3) {
        [self readSqlData];
    } else if (indexPath.row == 4) {
        [self querySqlData];
    }else if (indexPath.row == 5) {
        [self queryOrderbylimit];
    }else if (indexPath.row == 6) {
        [self updateSqlData];
    }else if (indexPath.row == 7) {
        [self querySelectSqlData];
    } else if (indexPath.row == 8) {
        [self saveSqliteReserveWord];
    } else if (indexPath.row == 9) {
         [self querySqliteReserveWord];
    }else if (indexPath.row == 10) {
        [self saveBlackListModel];
    }else if (indexPath.row == 11) {
        [self queryBlackListModel];
    }else if (indexPath.row == 12) {
        [self saveMutiKeyModel];
    } else if (indexPath.row == 13) {
        [self queryMutiKeyModel];
    }else if (indexPath.row == 14) {
         [self createAutoPrimarykey];
    }else if (indexPath.row == 15) {
        [self querySqlTableCount];
    }else if (indexPath.row == 16) {
        [self deleteObject];
    }else if (indexPath.row == 17) {
        [self querySqlDictionany];
    }else if (indexPath.row == 18) {
        [self saveMutiData];
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)insertOneRowData
{
    GAppsDataViewModel * model = [[GAppsDataViewModel alloc] init];
    model.dataID = @"WOSHI_dataID";
    model.fields = @"1234567";
    model.dataGroup = 12;
    model.dataIndex = 12;
    GAppsDataViewModel * model1 = [[GAppsDataViewModel alloc] init];
    model1.dataID = @"WOSHI_dataID2";
    model1.fields = @"1234567";
    model1.dataGroup = 12;
    model1.dataIndex = 12;
    BOOL isSucess = [self.database addObject:model];
    [self.database addObject:model1];
    NSLog(@"isSucess -- %d",isSucess);
}

- (void)insertLargeDataNOInTransaction
{
    BOOL isSucess =   [self.database addObjects:self.models WithTableName:nil];
    NSLog(@"isSucess -- %d",isSucess);
}

- (void)insertLargeData
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      BOOL isSucess =   [weakSelf.database addObjectsInTransaction:weakSelf.models WithTableName:nil];
        NSLog(@"isSucess -- %d",isSucess);
    });
}

- (void)readSqlData
{
    NSArray * all = [self.database getAllObjectsWithClass:[GAppsDataViewModel class]];
    NSString *jsons = [all yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

- (void)querySqlData
{

    NSArray *Datas = [self.database getObjectsWithClass:[GAppsDataViewModel class] withTableName:@"GAppsDataViewModel"  whereCond:@"dataID= '%@' AND dataGroup=%d",@"WOSHI_dataID",12];
    
    NSString *jsons = [Datas yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

- (void)queryOrderbylimit
{
    NSString *str = @"str";
    NSArray *datas = [self.database getObjectsWithClass:[GAppsDataViewModel class] withTableName:nil orderBy:@"dataID" limit:10 cond:@"dataID='%@' and dataGroup='%@'",str,str];
    
    NSString *jsons = [datas yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

- (void)updateSqlData
{
    BOOL isSucess = [self.database updateObjectClazz:[GAppsDataViewModel class] keyValues:@{@"fields":@"我被修改了"} cond:@"dataIndex = %ld and dataGroup = %ld",12,12,nil];
    NSLog(@"isSucess -- %d",isSucess);

}

- (void)querySelectSqlData
{
    
   NSArray *  array = [[[[[[self.database selectClazz:[GAppsDataViewModel class]]
                           whereProperty:@"dataID"] equal:@"WOSHI_dataID"]
                         orderby:@"dataID" asc:YES]
                        limit:10]
                       queryObjectsWithClazz:[GAppsDataViewModel class]];
    
    NSString *jsons = [array yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

- (void)saveSqliteReserveWord
{
    SQLiteReserveModel *model = [SQLiteReserveModel new];
    model.index = 1;
    model.group = @"12";
    model.add = @"add";
    model.as = @"as";
    model.desc = @"desc";
    SQLiteReserveModel *model1 = [SQLiteReserveModel new];
    model1.index = 2;
    model1.group = @"12";
    model1.add = @"add";
    model1.as = @"as";
    model1.desc = @"desc";
   BOOL isSucess =   [self.database addObject:model];
     [self.database addObject:model1];
    NSLog(@"isSucess -- %d",isSucess);
}

- (void)querySqliteReserveWord
{
    NSArray * datas = [self.database getAllObjectsWithClass:[SQLiteReserveModel class]];
    NSString *jsons = [datas yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
    
    NSArray * datas1 = [self.database getObjectsWithClass:[SQLiteReserveModel class] whereCond:@"desc ='%@'",@"desc"];
    NSString *jsons1 = [datas1 yy_modelDescription];
    NSLog(@"alldata1__ %@",jsons1);
}

- (void)saveBlackListModel
{
    GBlackListModel *black = [GBlackListModel new];
    black.dataID = @"asdfjkasdhjklghsad";
    black.name = @"我是黑名单模型";
    ///这三个字段会自动过滤. 数据表中也不会有这三个字段
    black.blackField1 =@[@"1"];
    black.blackField2 = YES;
    black.blackField3 = @"asdlkfljaksd";
    
    BOOL isSucess =   [self.database addObject:black];
    NSLog(@"isSucess -- %d",isSucess);
}

- (void)queryBlackListModel
{
    NSArray * datas = [self.database getAllObjectsWithClass:[GBlackListModel class]];
    NSString *jsons = [datas yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

/// 多主键
- (void)saveMutiKeyModel
{
    GMutilKeyModel *key = [GMutilKeyModel new];
    key.primaryKey1 = @"primaryKey1";
    key.primaryKey2 = 10;
    key.primaryKey3 = @"primaryKey1";
    key.other = @"test";
    GMutilKeyModel *key1 = [GMutilKeyModel new];
    key1.primaryKey1 = @"primaryKey1";
    key1.primaryKey2 = 10;
    key1.primaryKey3 = @"primaryKey1";
    key1.other = @"test1";
    GMutilKeyModel *key2 = [GMutilKeyModel new];
    key2.primaryKey1 = @"primaryKey1";
    key2.primaryKey2 = 11;
    key2.primaryKey3 = @"primaryKey1";
    key2.other = @"test";
    // key 与key1 所有主键均相同. so key1 会覆盖key
   BOOL isSucess =  [self.database addObjects:@[key,key1,key2]];
    NSLog(@"isSucess -- %d",isSucess);
}

- (void)queryMutiKeyModel
{
    NSArray * datas = [self.database getAllObjectsWithClass:[GMutilKeyModel class]];
    NSString *jsons = [datas yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

- (void)createAutoPrimarykey
{
    GAutoPrimaryKeyModel *model = [GAutoPrimaryKeyModel new];
    model.key = @"woshikey";
    GAutoPrimaryKeyModel *model1 = [GAutoPrimaryKeyModel new];
    model1.key = @"woshikey";
    GAutoPrimaryKeyModel *model2 = [GAutoPrimaryKeyModel new];
    model2.key = @"woshikey";
    GAutoPrimaryKeyModel *model3 = [GAutoPrimaryKeyModel new];
    model3.key = @"woshikey";
    GAutoPrimaryKeyModel *model4 = [GAutoPrimaryKeyModel new];
    model4.key = @"woshikey";
    
    BOOL isSucess = [self.database addObjects:@[model,model1,model2,model3,model4]];
    NSLog(@"isSucess -- %d",isSucess);
    
    NSArray * datas = [self.database getAllObjectsWithClass:[GAutoPrimaryKeyModel class]];
    NSString *jsons = [datas yy_modelDescription];
    NSLog(@"alldata__ %@",jsons);
}

- (void)querySqlTableCount
{
    long count = [self.database countInDataBaseWithClass:[GAppsDataViewModel class] withTableName:nil cond:nil];
    NSLog(@"count -- %ld",count);
}

- (void)deleteObject
{
    NSArray * datas = [self.database getAllObjectsWithClass:[GAutoPrimaryKeyModel class]];
    BOOL isSucess = [self.database deleteObject:[datas firstObject]];
    NSLog(@"isSucess -- %d",isSucess);
}

- (void)querySqlDictionany
{
    NSArray *datas = [self.database getResultDictionaryWithTableName:NSStringFromClass(GAutoPrimaryKeyModel.class) CustomCond:nil];
    NSLog(@"alldata__ %@",datas);
}

- (void)updateObject
{
    NSArray *objects = [self.database getAllObjectsWithClass:[GAppsDataViewModel class]];
    GAppsDataViewModel* object = [objects firstObject];
   ///
    long autoPri = [object g_getAutoPrimaryKey];
    GAppsDataViewModel * dataModel = [GAppsDataViewModel new];
    dataModel.dataID = @"WOSHI_dataID";
    dataModel.fields = @"1234567";
    dataModel.dataGroup = 12;
    dataModel.dataIndex = 12;
    [dataModel setValue:@(autoPri) forKey:GAUTOPRIMARYKEY];
    [self.database addObject:object];
}

- (void)saveMutiData
{
    GSubTableA * sub = [GSubTableA new];
    sub.key = @"ceshi";
    GTableA *tableA = [GTableA new];
    tableA.datas = @[sub];
    tableA.subA = sub;
    NSString *str = @"asdf";
    tableA.data = [str dataUsingEncoding:NSUTF8StringEncoding];
    tableA.realData =[str dataUsingEncoding:NSUTF8StringEncoding];
    BOOL isSucess =  [self.database addObject:tableA];
    NSLog(@"isSucess -- %d",isSucess);
    
    NSArray * datas = [self.database getAllObjectsWithClass:[GTableA class]];
    GTableA * ta = [datas lastObject];
    NSString *str1 = [[NSString alloc] initWithData:ta.realData encoding:NSUTF8StringEncoding];
    NSString *jsons = [datas yy_modelDescription];
    
    
    NSLog(@"alldata__ %@",jsons);
}
@end
