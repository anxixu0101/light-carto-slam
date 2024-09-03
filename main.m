
clear;
clc;

%% 重要参数调节
voxel_size = 0.05; % 体素滤波器
max_iterations = 1000; % 前端最大迭代次数
tolerance = 0.001; % 迭代停止误差
multi_resolution = 0.8;


%% 姿态坐标
robot_position = zeros(2,1);
robot_rotate = eye(2);
position_index = 1;

h = scatter(NaN, NaN, NaN, 'filled');
%% 栅格地图初始化
mapWidth = 50;  % 地图宽度 (单位: 米)
mapHeight = 50; % 地图高度 (单位: 米)
resolution = 10; % 每米的栅格数 (resolution)
originX = mapWidth / 2;  % 假设地图中心是 (0, 0) 对应的世界坐标原点
originY = mapHeight / 2;

% 计算栅格地图的大小 (单位: 栅格)
gridSizeX = mapWidth * resolution;
gridSizeY = mapHeight * resolution;

% 初始化栅格地图 (全1表示空闲，0表示占据)
gridMap = ones(gridSizeY, gridSizeX);
gridMap1 = ones(gridSizeY, gridSizeX);
%% 搜索框参数
angle_step=2; % 单位度
x_step = 0.1; % 单位m
y_step = 0.1; % 单位m

R_init = eye(2); % 初始化为3x3单位矩阵
T_init = zeros(2, 1); % 初始化为3x1零向量

%% 雷达参数
lidar = SetLidarParameters();

%% 前端匹配
% 输出所有的点云帧
and_non = 0;
lidar_data = load('horizental_lidar.mat');
N = size(lidar_data.timestamps, 1);


for scanIdx = 1:500
    
    time = lidar_data.timestamps(scanIdx) * 1e-9;
    scan = get_lidar_point(lidar_data, scanIdx, lidar, 24);
   
        % disp(point_index); %点云帧的序号
%         laser_point =get_lidar_point(laser_data,point_index);
        
        if and_non==0
            ref_point = voxel_filter(scan, voxel_size);
            point_map=ref_point;
%             map =descart2grid(ref_point,originX,originY,resolution,gridSizeX,gridSizeY);
            %     gridMap=drawGridMap(gridMap,map);
            and_non=1;
        end
        


% 删除离群点
% filtered_points = voxel_filter(laser_point, voxel_size);

%% 观看实时点云
% map1 =descart2grid(filtered_points,originX,originY,resolution,gridSizeX,gridSizeY);
% gridMap1=drawGridMap(gridMap1,map1);
% play_map(gridMap1,point_index);
% map1=[];
% gridMap1 = ones(gridSizeY, gridSizeX);

% 隔十帧作一次关键帧提取
if(mod(scanIdx,1)==0&&scanIdx>1)
    
   % 获得点云相对机器人的位姿
    scan=transform(scan,robot_rotate,robot_position);
%    
%    [R,T]= match_score(gridMap,filtered_points,angle_step,...
%                             x_step,y_step,R_init,T_init,...
%                             originX,originY,resolution,gridSizeX,gridSizeY);
  
 [R_icp,T_icp,aligned_points]=icp(ref_point, scan,R_init,T_init, max_iterations, tolerance);
%    

 aligned_points=transform(aligned_points,robot_rotate,robot_position);
%   position1(:,scanIdx+1)=position1(:,scanIdx)+T_icp;
  point_map =[point_map;aligned_points];
%  transform_point = transform(filtered_points,R_icp,T_icp);

%     gridPosition=grid_stitch(gridMap,aligned_points,originX,originY,resolution,gridSizeX,gridSizeY);
%     gridMap = drawGridMap(gridMap,gridPosition);
%     
%     % 更新机器人位姿
     robot_rotate=R_icp*robot_rotate;
     robot_position=robot_position+T_icp;
%     
%     pose(position_index,1)=robot_position(1,1);
%     pose(position_index,2)=robot_position(2,1);
%     position_index = position_index+1;
%     
      ref_point = scan;
     
  
%     play_map(gridMap,point_index);
end

end

 plot(point_map(:,1),point_map(:,2),'r.');


%% 播放地图
function play_map(gridMap,point_index)
    h = imagesc(gridMap(:, :, 1));
    colormap(gray);
    set(h, 'CData', gridMap(:, :)); % 更新栅格地图数据
    title(sprintf('Frame %d', point_index)); % 显示当前帧数
    pause(0.1); % 控制动画速度，单位为秒
end


%% 播放功能
function play_video(h,filtered_points)
set(h, 'XData', filtered_points(:,1), 'YData', filtered_points(:,2));
% 刷新图形
drawnow;    
% 可选：控制播放速度
pause(0.05);  % 暂停0.05秒
end



