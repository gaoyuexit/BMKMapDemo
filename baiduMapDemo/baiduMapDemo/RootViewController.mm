//
//  RootViewController.m
//  baiduMapDemo
//
//  Created by 郜宇 on 15/11/18.
//  Copyright © 2015年 郜宇. All rights reserved.
//

#import "RootViewController.h"
#import <BaiduMapAPI/BMapKit.h>
@interface RootViewController ()<BMKGeneralDelegate,BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,BMKRouteSearchDelegate>
@property (nonatomic, strong) UITextField *startCityTF;
@property (nonatomic, strong) UITextField *startAddressTF;
@property (nonatomic, strong) UITextField *endCityTF;
@property (nonatomic, strong) UITextField *endAddressTF;
@property (nonatomic, strong) BMKMapView *mapView; // 百度地图
@property (nonatomic, strong) BMKLocationService *locationService;//定位
@property (nonatomic, strong) BMKGeoCodeSearch *geoCodeSearch; // 负责地理编码
// 声明路线搜索服务对象
@property (nonatomic, strong) BMKRouteSearch *routeSearch;
// 开始的路线检索节点
@property (nonatomic, strong) BMKPlanNode *startNode;
// 目标路线检索节点
@property (nonatomic, strong) BMKPlanNode *endNode;

@end

@implementation RootViewController

- (void)dealloc
{
    self.mapView.delegate = nil;
    self.locationService.delegate = nil;
    self.geoCodeSearch.delegate = nil;
    self.routeSearch.delegate = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    // 因为百度地图引擎是用C++写的,所以我们要保证工程中至少有一个文件是.mm后缀
    
    // 创建百度地图主引擎类对象(使用百度地图功能之前必须启动引擎)
    BMKMapManager *manager = [[BMKMapManager alloc] init];
    // 启动引擎
    [manager start:@"VIuaKDwHpS8GS2OYfy5VAT2G" generalDelegate:self];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    // 搭建UI
    [self addSubViews];
    
    // 创建定位服务对象
    self.locationService = [[BMKLocationService alloc] init];
    // 设置定位服务对象的代理
    self.locationService.delegate = self;
    // 设置再次定位的最小距离
    [BMKLocationService setLocationDistanceFilter:10];
    
    // 创建地理位置搜索对象
    self.geoCodeSearch = [[BMKGeoCodeSearch alloc] init];
    self.geoCodeSearch.delegate = self;
    
    // 创建routeSearch搜索服务对象
    self.routeSearch = [[BMKRouteSearch alloc] init];
    self.routeSearch.delegate = self;
    
    
}

// 搭建UI
- (void)addSubViews
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"开始定位" style:UIBarButtonItemStyleDone target:self action:@selector(leftAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"结束定位" style:UIBarButtonItemStyleDone target:self action:@selector(rightAction)];
    self.startCityTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 30, 100, 30)];
    self.startCityTF.placeholder = @"开始城市";
    [self.view addSubview:_startCityTF];
    
    self.startAddressTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_startCityTF.frame) + 30, CGRectGetMinY(_startCityTF.frame), CGRectGetWidth(_startCityTF.frame), CGRectGetHeight(_startCityTF.frame))];
    self.startAddressTF.placeholder = @"开始地址";
    [self.view addSubview:_startAddressTF];
    
    self.endCityTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(_startCityTF.frame), CGRectGetMaxY(_startCityTF.frame) + 10, CGRectGetWidth(_startCityTF.frame), CGRectGetHeight(_startCityTF.frame))];
    self.endCityTF.placeholder = @"结束城市";
    [self.view addSubview:_endCityTF];
    
    self.endAddressTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_endCityTF.frame) + 30, CGRectGetMaxY(_startCityTF.frame) + 10, CGRectGetWidth(_startCityTF.frame), CGRectGetHeight(_startCityTF.frame))];
    self.endAddressTF.placeholder = @"结束地址";
    [self.view addSubview:_endAddressTF];
    
    // 添加路线规划按钮
    UIButton *routeSearch = [UIButton buttonWithType:UIButtonTypeSystem];
    [routeSearch setTitle:@"线路规划" forState:UIControlStateNormal];
    routeSearch.frame = CGRectMake(CGRectGetMaxX(_startAddressTF.frame) + 10, CGRectGetMaxY(_startAddressTF.frame), 100, 30);
    [routeSearch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [routeSearch addTarget:self action:@selector(routeSearchAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:routeSearch];
    
    // 添加地图
    self.mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_endAddressTF.frame) + 5, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - CGRectGetMaxY(_endAddressTF.frame) - 5)];
    // 设置代理
    self.mapView.delegate = self;
    [self.view addSubview:_mapView];
    
}

// 开始定位
- (void)leftAction
{
    // 1.开启定位服务
    [self.locationService startUserLocationService];
    // 2.在地图上显示用户的位置
    self.mapView.showsUserLocation = YES;
    
}
// 关闭定位服务
- (void)rightAction
{
    // 1.关闭定位服务
    [self.locationService stopUserLocationService];
    // 2.设置地图不显示用户的位置
    self.mapView.showsUserLocation = NO;
    // 3.删除我们添加的标注对象 (大头针都放到了这个annotations数组中)
    [self.mapView removeAnnotation:[self.mapView.annotations lastObject]];
}

// 路线规划的点击事件
- (void)routeSearchAction:(UIButton *)sender
{
    // 完成正向地理编码
    // 1.创建正向地理编码选项对象
    BMKGeoCodeSearchOption *geoSearchOption = [[BMKGeoCodeSearchOption alloc] init];
    // 2.给想进行正向地理位置编码的位置赋值
    geoSearchOption.city = self.startCityTF.text;
    geoSearchOption.address = self.startAddressTF.text;
    // 执行地理位置编码
    NSLog(@"%@---%@",self.startCityTF.text,self.startAddressTF.text);
    [self.geoCodeSearch geoCode:geoSearchOption];
}

#pragma mark - - BMKLocationService代理方法
// 开始定位
- (void)willStartLocatingUser
{
    NSLog(@"开始定位");
    
}
// 定位失败
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"定位失败 error : %@",error);
    
}
//定位成功,再次定位的方法
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    // 地理反编码
    // 1.创建反向地理编码选项对象
    BMKReverseGeoCodeOption *reverseOption = [[BMKReverseGeoCodeOption alloc] init];
    // 2.给反向地理编码选项对象的坐标点赋值
    reverseOption.reverseGeoPoint = userLocation.location.coordinate;
    // 3.执行反向地理编码操作, 异步函数，返回结果在BMKGeoCodeSearchDelegate的onGetAddrResult通知
    [self.geoCodeSearch reverseGeoCode:reverseOption];
}

#pragma mark -- BMKGeoCodeSearchDelegate反地理编码的代理回调
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    // 这时候添加大头针
    //插入大头针
    //定义大头针标注
    BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
    //设置标注的位置坐标
    annotation.coordinate = result.location;
    annotation.title = result.address;
    [self.mapView addAnnotation:annotation];
    //使地图显示在该位置
    [self.mapView setCenterCoordinate:result.location animated:YES];
}
#pragma mark -- BMKGeoCodeSearchDelegate正向地理编码的代理回调
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    NSLog(@"----%@",result.address);
    if ([result.address isEqualToString:self.startAddressTF.text]) {//当前编码的对象为开始节点
        self.startNode = [[BMKPlanNode alloc] init];
        //给节点的坐标位置赋值(使用坐标比使用位置准确)
        //正向地理编码后返回的坐标赋值给开始节点的坐标
        _startNode.pt = result.location;
        //发起对目标节点的地理编码
        //1.创建正向地理编码选项对象
        BMKGeoCodeSearchOption *geoOption = [[BMKGeoCodeSearchOption alloc] init];
        geoOption.city = self.endCityTF.text;
        geoOption.address = self.endAddressTF.text;
        //目标节点的正向地理编码
        [self.geoCodeSearch geoCode:geoOption];
        //让下一次目标节点可以进入下面else的方法中
        self.endNode = nil;
    }else{ //当前编码的对象为目标节点
        self.endNode = [[BMKPlanNode alloc] init];
        _endNode.pt = result.location;
    }
    
    
    if (_startNode != nil && _endNode != nil) {
        // 开始执行路线规划(公交,乘车,步行)
        // 1.创建驾车路线规划
        BMKDrivingRoutePlanOption *drivingRoutOption = [[BMKDrivingRoutePlanOption alloc] init];
        // 2.指定开始节点和目标节点
        drivingRoutOption.from = _startNode;
        drivingRoutOption.to = _endNode;
        // 3.让路线搜索服务对象搜索路线(执行搜索,会执行代理方法中的代理回调)
        [self.routeSearch drivingSearch:drivingRoutOption];
        
    }
}

#pragma mark -- BMKRouteSearchDelegate
// 开车路线的回调
- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    // 删除原来的覆盖物(大头针标注) ,获取地图上大头针的数组
    NSArray *array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    // 删除原来的overlays(路线轨迹点)
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) { // 没有错误的话
        // 选取获取到所有路线中的一条 (路线中的数组)
        BMKDrivingRouteLine *plan = [result.routes objectAtIndex:0];
        // 计算路线方案中路段的数目(路线是由一个个的路段构成的)
        // steps 路线中的所有路段
        NSUInteger size = [plan.steps count];
        // 路段是由一个个的轨迹点构成
        // 声明一个整形变量用来计算所有轨迹点的总数
        int planPointCounts = 0;
        for (int i = 0; i < size; i ++) {
            // 获取路线中的路段
            BMKDrivingStep *step = plan.steps[i];
            if (i == 0) { //当时第一个路段的时候,让地图显示为该位置
                // 位置中心点为路段的入口坐标, 0.001,0.001为经纬度范围
                [self.mapView setRegion:BMKCoordinateRegionMake(step.entrace.location,BMKCoordinateSpanMake(0.001, 0.001))];
            }
            // 累计轨迹点的总数   pointsCount 路段所经过的地理坐标集合内点的个数
            planPointCounts += step.pointsCount;
            
            
        }
        // 声明一个结构体数组用来保存所有的轨迹点(每一个轨迹点都是一个结构体)
        // 轨迹点结构体的名字为BMKMapPoint
        // 下面这句为C++语法,创建一个大小为planPointCounts的数组,数组名字为tempPoints
        BMKMapPoint *tempPoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        // 给结构体数组中的每个结构体都附上轨迹点的坐标
        for (int j = 0; j < size; j ++) {
            // 取出路段
            BMKDrivingStep *transitStep = [plan.steps objectAtIndex:j];
            int k = 0;
            for (k = 0; k < transitStep.pointsCount; k ++) {
                // 获取该路段下的每个轨迹点的X,Y放入数组中
                tempPoints[i].x = transitStep.points[k].x;
                tempPoints[i].y = transitStep.points[k].y;
                i ++;
            }
        }
        
        // 通过轨迹点构造BMKPolyine(折线) *@param points 指定的直角坐标点数组
        //*@param count 坐标点的个数
        // 绘制折线还有其他的方法,点进入看
        BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:tempPoints count:planPointCounts];
        // 添加到MapView上
        // 我们想要在地图上显示轨迹, 只能先添加overlay对象(类似于大头针的标注),添加好之后,地图就会根据你设置的overlay显示出轨迹,然后调用mapView的代理方法,绘制轨迹的方法
        [self.mapView addOverlay:polyLine];
    }
}
#pragma mark -- mapView的代理方法
// 绘制轨迹的方法
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        // 创建要显示的折线
        BMKPolylineView *polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        // 设置该线条的填充颜色
        polylineView.fillColor = [UIColor redColor];
        // 设置线条的颜色
        polylineView.strokeColor = [UIColor redColor];
        // 设置折线的宽度
        polylineView.lineWidth = 3.0;
        return polylineView;
    }
    return nil;
}








@end
