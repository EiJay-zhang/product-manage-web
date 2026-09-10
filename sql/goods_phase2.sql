-- 商品管理第二期：库存进货、墨水屏、物流对账
-- 需先执行 sql/goods_phase1.sql

-- 调整供应商菜单顺序，为库存进货腾出第 2 位
update sys_menu set order_num = 3 where menu_id = 2110;

-- 库存进货
insert into sys_menu values('2120', '库存进货', '2100', '2', 'inventory', 'goods/inventory/index', '', '', 1, 0, 'C', '0', '0', 'goods:inventory:list', 'inventory', 'admin', sysdate(), '', null, '库存进货菜单');
insert into sys_menu values('2121', '进货查询', '2120', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:inventory:query', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2122', '新增进货', '2120', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:inventory:add', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2123', '库存调整', '2120', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:inventory:adjust', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2124', '进货导出', '2120', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:inventory:export', '#', 'admin', sysdate(), '', null, '');

-- 墨水屏管理
insert into sys_menu values('2130', '墨水屏管理', '2100', '4', 'eink', 'goods/eink/index', '', '', 1, 0, 'C', '0', '0', 'goods:eink:list', 'eink', 'admin', sysdate(), '', null, '墨水屏管理菜单');
insert into sys_menu values('2131', '设备查询', '2130', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:eink:query', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2132', '绑定设备', '2130', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:eink:bind', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2133', '解绑设备', '2130', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:eink:unbind', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2134', '同步设备', '2130', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:eink:sync', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2135', '重启设备', '2130', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:eink:restart', '#', 'admin', sysdate(), '', null, '');

-- 物流对账
insert into sys_menu values('2140', '物流对账', '2100', '5', 'logistics', 'goods/logistics/index', '', '', 1, 0, 'C', '0', '0', 'goods:logistics:list', 'truck', 'admin', sysdate(), '', null, '物流对账菜单');
insert into sys_menu values('2141', '物流查询', '2140', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:logistics:query', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2142', '新增物流单', '2140', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:logistics:add', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2143', '物流对账', '2140', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:logistics:edit', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2144', '物流导出', '2140', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:logistics:export', '#', 'admin', sysdate(), '', null, '');

-- 字典：库存变动类型
insert into sys_dict_type values(112, '库存变动类型', 'goods_stock_type', '0', 'admin', sysdate(), '', null, '库存进货变动类型');
insert into sys_dict_data values(1121, 1, '进货入库', 'in', 'goods_stock_type', '', 'success', 'Y', '0', 'admin', sysdate(), '', null, '进货入库');
insert into sys_dict_data values(1122, 2, '人工盘点', 'check', 'goods_stock_type', '', 'info', 'N', '0', 'admin', sysdate(), '', null, '人工盘点');
insert into sys_dict_data values(1123, 3, '损耗调减', 'loss', 'goods_stock_type', '', 'warning', 'N', '0', 'admin', sysdate(), '', null, '损耗调减');

-- 字典：墨水屏在线状态
insert into sys_dict_type values(113, '墨水屏在线状态', 'goods_eink_online', '0', 'admin', sysdate(), '', null, '墨水屏在线状态');
insert into sys_dict_data values(1131, 1, '在线', 'online', 'goods_eink_online', '', 'success', 'Y', '0', 'admin', sysdate(), '', null, '在线');
insert into sys_dict_data values(1132, 2, '离线', 'offline', 'goods_eink_online', '', 'danger', 'N', '0', 'admin', sysdate(), '', null, '离线');

-- 字典：墨水屏同步状态
insert into sys_dict_type values(114, '墨水屏同步状态', 'goods_eink_sync', '0', 'admin', sysdate(), '', null, '墨水屏同步状态');
insert into sys_dict_data values(1141, 1, '成功', 'success', 'goods_eink_sync', '', 'success', 'Y', '0', 'admin', sysdate(), '', null, '成功');
insert into sys_dict_data values(1142, 2, '等待', 'pending', 'goods_eink_sync', '', 'warning', 'N', '0', 'admin', sysdate(), '', null, '等待');
insert into sys_dict_data values(1143, 3, '失败', 'failed', 'goods_eink_sync', '', 'danger', 'N', '0', 'admin', sysdate(), '', null, '失败');

-- 字典：物流对账状态
insert into sys_dict_type values(115, '物流对账状态', 'goods_logistics_status', '0', 'admin', sysdate(), '', null, '物流对账状态');
insert into sys_dict_data values(1151, 1, '未对账', 'pending', 'goods_logistics_status', '', 'warning', 'Y', '0', 'admin', sysdate(), '', null, '未对账');
insert into sys_dict_data values(1152, 2, '已对账', 'reconciled', 'goods_logistics_status', '', 'info', 'N', '0', 'admin', sysdate(), '', null, '已对账');
insert into sys_dict_data values(1153, 3, '已结清', 'settled', 'goods_logistics_status', '', 'success', 'N', '0', 'admin', sysdate(), '', null, '已结清');
insert into sys_dict_data values(1154, 4, '异常', 'abnormal', 'goods_logistics_status', '', 'danger', 'N', '0', 'admin', sysdate(), '', null, '异常');

-- 字典：物流商
insert into sys_dict_type values(116, '物流商', 'goods_carrier', '0', 'admin', sysdate(), '', null, '物流商');
insert into sys_dict_data values(1161, 1, '顺丰速运', 'sf', 'goods_carrier', '', 'primary', 'N', '0', 'admin', sysdate(), '', null, '顺丰速运');
insert into sys_dict_data values(1162, 2, '德邦物流', 'deppon', 'goods_carrier', '', 'success', 'N', '0', 'admin', sysdate(), '', null, '德邦物流');
insert into sys_dict_data values(1163, 3, '中通快递', 'zto', 'goods_carrier', '', 'warning', 'N', '0', 'admin', sysdate(), '', null, '中通快递');
insert into sys_dict_data values(1164, 4, '京东物流', 'jd', 'goods_carrier', '', 'danger', 'N', '0', 'admin', sysdate(), '', null, '京东物流');
