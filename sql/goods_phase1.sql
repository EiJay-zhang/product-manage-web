-- 商品管理第一期：菜单、权限、字典
-- 接入后端后执行，前端开发可通过 VITE_APP_GOODS_MOCK=true 使用本地演示数据

-- 目录
insert into sys_menu values('2100', '商品管理', '0', '5', 'goods', null, '', '', 1, 0, 'M', '0', '0', '', 'shopping', 'admin', sysdate(), '', null, '商品管理目录');

-- 商品列表
insert into sys_menu values('2101', '商品列表', '2100', '1', 'product', 'goods/product/index', '', '', 1, 0, 'C', '0', '0', 'goods:product:list', 'list', 'admin', sysdate(), '', null, '商品列表菜单');
insert into sys_menu values('2102', '商品查询', '2101', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:product:query', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2103', '商品新增', '2101', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:product:add', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2104', '商品修改', '2101', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:product:edit', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2105', '商品删除', '2101', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:product:remove', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2106', '商品导出', '2101', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:product:export', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2107', '同步墨水屏', '2101', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:product:sync', '#', 'admin', sysdate(), '', null, '');

-- 供应商管理
insert into sys_menu values('2110', '供应商管理', '2100', '2', 'supplier', 'goods/supplier/index', '', '', 1, 0, 'C', '0', '0', 'goods:supplier:list', 'peoples', 'admin', sysdate(), '', null, '供应商管理菜单');
insert into sys_menu values('2111', '供应商查询', '2110', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:supplier:query', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2112', '供应商新增', '2110', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:supplier:add', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2113', '供应商修改', '2110', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:supplier:edit', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2114', '供应商删除', '2110', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:supplier:remove', '#', 'admin', sysdate(), '', null, '');
insert into sys_menu values('2115', '供应商导出', '2110', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'goods:supplier:export', '#', 'admin', sysdate(), '', null, '');

-- 字典：商品分类
insert into sys_dict_type values(110, '商品分类', 'goods_category', '0', 'admin', sysdate(), '', null, '商品分类');
insert into sys_dict_data values(1101, 1, '饮料', 'drink', 'goods_category', '', 'primary', 'N', '0', 'admin', sysdate(), '', null, '饮料');
insert into sys_dict_data values(1102, 2, '零食', 'snack', 'goods_category', '', 'success', 'N', '0', 'admin', sysdate(), '', null, '零食');
insert into sys_dict_data values(1103, 3, '方便食品', 'instant', 'goods_category', '', 'warning', 'N', '0', 'admin', sysdate(), '', null, '方便食品');

-- 字典：供应商合作状态
insert into sys_dict_type values(111, '供应商合作状态', 'goods_coop_status', '0', 'admin', sysdate(), '', null, '供应商合作状态');
insert into sys_dict_data values(1111, 1, '合作中', '0', 'goods_coop_status', '', 'success', 'Y', '0', 'admin', sysdate(), '', null, '合作中');
insert into sys_dict_data values(1112, 2, '暂停', '1', 'goods_coop_status', '', 'info', 'N', '0', 'admin', sysdate(), '', null, '暂停');
