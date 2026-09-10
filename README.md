# 商品管理系统（前端）

便利店 / 快消进销存管理端，覆盖商品、库存、进货、销售、物流对账、货架墨水屏和经营报表。基于 [RuoYi-Vue 3.9.2](https://gitee.com/y_project/RuoYi-Vue) 二次开发。

配套后端：`product-manage-system`（RuoYi 3.9.2 / `ruoyi-pms`）。

## 技术栈

| 类别 | 选型 |
| --- | --- |
| 框架 | Vue 3.5 |
| 构建 | Vite 6 |
| UI | Element Plus 2.13 |
| 状态 | Pinia 3 |
| 路由 | Vue Router 4 |
| 图表 | ECharts 5 |
| HTTP | Axios |

业务接口前缀为 `/pms/*`，权限标识为 `pms:`。侧边栏菜单由后端 `GET /getRouters` 下发，前端不写死 PMS 路由。

## 功能模块

| 模块 | 页面 | 说明 |
| --- | --- | --- |
| 数据总览 | `/index`、`pms/dashboard` | 首页复用经营看板：KPI、趋势、热销、通知、最近进货 |
| 商品信息 | `pms/product` | 列表、新增/编辑/删除、导出、预警筛选、批量同步墨水屏 |
| 商品分类 | `pms/category` | 分类 CRUD、启停，供商品和报表下拉使用 |
| 供应商 | `pms/supplier` | CRUD、启停；详情可看供货商品和进货记录 |
| 进货入库 | `pms/purchase` | 进货台账；与库存流水共用 `pms/inventory` |
| 库存流水 | `pms/stock` | 入库 / 盘点 / 损耗 / 调拨 / 销售 / 建档，支持库存调整 |
| 销售出库 | `pms/sale` | 列表、出库、详情、导出（当前不能改单、退货、作废） |
| 物流对账 | `pms/logistics` | 账单、对账/结清、批量对账、费用统计 |
| 墨水屏 | `pms/device` | 设备绑定/解绑、刷新/重启、批量同步、同步日志 |
| 报表统计 | `pms/report` | 经营概览、进货、库存、成本、供应商、营业额，可导出 |
| 业务设置 | `pms/setting` | 库存/营收预警、墨水屏展示字段与同步频率 |

系统管理、监控、代码生成等仍沿用若依能力（用户、角色、菜单、字典、日志、定时任务等）。

当前已知缺口：后端已有「物流商」菜单和 `/pms/carrier` 接口，前端尚未提供 `pms/carrier` 页面，点开会 404。更完整的实现情况和后续计划见 [docs/项目实现情况与计划.md](docs/项目实现情况与计划.md)。

## 环境要求

- Node.js 18+
- 后端 `product-manage-system` 已启动，默认 `http://localhost:8080`
- 已执行后端权威脚本 `product-manage-system/sql/pms.sql`（不要执行本仓库 `sql/goods_phase*.sql`）

## 本地运行

```bash
# 安装依赖
npm install

# 启动开发服务（默认端口 80，代理 /dev-api → http://localhost:8080）
npm run dev
```

开发环境页面标题为「商品管理系统」，访问地址一般为 `http://localhost/`。若 80 端口被占用，Vite 会改用其它端口。

本地账号沿用若依默认值（以后端实际配置为准）：`admin` / `admin123`。

其它脚本：

```bash
npm run build:stage   # 预发构建（.env.staging，接口前缀 /stage-api）
npm run build:prod    # 生产构建（.env.production，接口前缀 /prod-api）
npm run preview       # 预览构建产物
```

开发代理在 `vite.config.js`：

```js
const baseUrl = 'http://localhost:8080' // 后端接口
```

环境变量见 `.env.development` / `.env.staging` / `.env.production`。提交时不要带密钥。

## 目录说明

```
├── src/
│   ├── api/pms/              # 业务接口（/pms/*）
│   ├── views/pms/            # 业务页面
│   │   ├── dashboard/        # 经营看板（首页复用）
│   │   ├── product/          # 商品
│   │   ├── category/         # 分类
│   │   ├── supplier/         # 供应商
│   │   ├── inventory/        # 进货 + 库存（真正页面）
│   │   ├── purchase/         # 打开进货 Tab
│   │   ├── stock/            # 打开库存 Tab
│   │   ├── sale/             # 销售出库
│   │   ├── logistics/        # 物流对账
│   │   ├── device/           # 墨水屏
│   │   ├── report/           # 报表
│   │   └── setting/          # 业务设置
│   ├── views/system/         # 若依：用户 / 角色 / 菜单 / 字典等
│   ├── views/monitor/        # 若依：日志 / 在线用户 / 缓存等
│   ├── views/tool/           # 若依：代码生成 / 表单构建
│   ├── views/goods/          # 一期遗留页面，不要再用
│   ├── components/
│   ├── layout/
│   ├── router/
│   ├── store/
│   └── utils/
├── sql/                      # 过期菜单脚本，不要执行
├── docs/                     # 实现情况与计划
├── vite.config.js
└── package.json
```

开发约定：

- 业务组件路径为 `pms/.../index`，对应后端菜单 component 字段
- 正式业务走 `src/api/pms/`，不要再接 `src/api/goods/` 或 mock
- 菜单与权限以数据库 `sys_menu` 及后端 `pms.sql` 为准

## 相关文档

- [项目实现情况与计划](docs/项目实现情况与计划.md)
- 若依官方文档：<http://doc.ruoyi.vip>

## License

基于若依 MIT License 二次开发，见 [LICENSE](LICENSE)。
