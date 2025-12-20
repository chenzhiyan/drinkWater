# 喝水提醒系统 (Server酱3版)

这是一个基于 Django 和 Celery 的喝水提醒系统，会定时通过 Server酱3 发送微信推送消息提醒用户喝水。

## 功能特性

- 每隔指定时间自动发送喝水提醒
- 支持手动发送测试通知  
- 系统状态监控页面
- 使用 Server酱3 进行消息推送 (API: https://sc3.ft07.com/send/)
- 多种随机提醒消息（从预设列表中随机选择）
- 智能时间调度（上午9:00-11:50和下午14:00-17:30，随机间隔45-60分钟）

## 部署说明

### 1. 环境准备

```bash
# 克隆项目
git clone <your-repo-url>
cd drink_reminder

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置 Server酱3

1. 获取 Server酱3 SendKey：
   - 访问 [Server酱3官网](https://sc3.ft07.com/)
   - 扫码关注并获取 SendKey

2. 编辑 `config.py` 文件：
   ```python
   SERVER_CHAN_TOKEN = "YOUR_SENDKEY_HERE"  # 替换为你的 SendKey
   DRINK_REMINDER_TITLE = "喝水提醒"      # 提醒标题
   DRINK_REMINDER_MESSAGES = [
     "记得喝水哦！保持身体水分充足对健康很重要。",
     "水是生命之源，记得及时补充水分！",
     # ... 更多消息
   ]
   ```

### 3. 数据库迁移

```bash
python manage.py migrate
```

### 4. 启动应用

需要启动多个进程：

1. 启动 Django 服务器：
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

2. 启动 Celery worker（处理任务）：
   ```bash
   celery -A drink_reminder worker -l info
   ```

3. 启动 Celery beat（调度任务）：
   ```bash
   celery -A drink_reminder beat -l info
   ```

### 5. 生产环境部署（使用 Gunicorn + Nginx）

```bash
# 安装 gunicorn
pip install gunicorn

# 启动 gunicorn
gunicorn drink_reminder.wsgi:application --bind 0.0.0.0:8000
```

在生产环境中，建议配置 Supervisor 或 systemd 来管理 Celery worker 和 beat 进程。

### 6. 手动发送提醒

可以通过管理命令手动发送提醒：

```bash
python manage.py send_drink_reminder
```

## 项目结构

```
drink_reminder/                    # 主项目目录
├── config.py                     # 配置文件
├── deploy_and_run.sh             # 一键部署和启动脚本 (Server酱)
├── deploy_and_run_serverchan3.sh # 一键部署和启动脚本 (Server酱3)
├── setup_serverchan3.sh          # Server酱3快速设置脚本
├── start_system.sh               # 日常启动脚本
├── stop_system.sh                # 停止服务脚本
├── manage.py                     # Django 管理脚本
├── requirements.txt              # 依赖列表
├── drink_reminder/               # Django 配置目录
│   ├── __init__.py
│   ├── settings.py
│   ├── settings_prod.py           # 生产环境设置
│   ├── urls.py
│   └── wsgi.py
└── reminder/                     # 提醒功能应用
    ├── __init__.py
    ├── admin.py
    ├── apps.py
    ├── models.py
    ├── services.py               # Server酱3 服务
    ├── tasks.py                  # Celery 任务
    ├── views.py
    ├── urls.py
    ├── templates/                # 模板文件
    └── static/                   # 静态文件
```

## 快速部署和启动

### 一键部署和启动（Server酱3版 - 推荐）

```bash
# 下载Server酱3快速设置脚本
wget https://raw.githubusercontent.com/chenzhiyan/drinkWater/main/setup_serverchan3.sh
chmod +x setup_serverchan3.sh
./setup_serverchan3.sh
```

### 或使用部署脚本

```bash
# 下载Server酱3部署脚本
wget https://raw.githubusercontent.com/chenzhiyan/drinkWater/main/deploy_and_run_serverchan3.sh
chmod +x deploy_and_run_serverchan3.sh
./deploy_and_run_serverchan3.sh
```

### 日常启动（部署后）

```bash
# 启动已部署的系统（检查服务状态并启动未运行的服务）
./start_system.sh
```

### 停止服务

```bash
# 停止所有服务
./stop_system.sh
```

## 配置说明

编辑 `config.py` 文件配置Server酱3推送：

1. `SERVER_CHAN_TOKEN`: Server酱3的SendKey
2. `DRINK_REMINDER_MESSAGES`: 一个包含多条提醒消息的列表，系统会随机选择一条发送
3. 智能时间调度：
   - 上午：9:00 - 11:50，随机间隔45-60分钟发送提醒
   - 下午：14:00 - 17:30，随机间隔45-60分钟发送提醒
   - 其他时间不发送提醒

## Server酱3 API

本项目使用 Server酱3 API: `https://sc3.ft07.com/send/{SENDKEY}`

Server酱3是Server酱的升级版本，提供更稳定的推送服务。

## Redis 配置

系统使用 Redis 作为 Celery 的消息代理和结果后端。请确保 Redis 服务正在运行：

```bash
# Ubuntu/Debian
sudo systemctl start redis

# macOS (with Homebrew)
brew services start redis
```

## 故障排除

1. 如果无法接收推送消息，请检查：
   - Server酱 SCKEY 是否正确配置
   - 网络是否能访问 Server酱 服务器
   - Celery worker 是否正常运行

2. 查看日志：
   - Django 日志：查看控制台输出
   - Celery 日志：启动时的输出信息

## 定时任务说明

系统在以下时间段发送提醒：
- 上午：9:00 - 11:50，随机间隔45-60分钟
- 下午：14:00 - 17:30，随机间隔45-60分钟
- 其他时间不发送提醒

你可以在 `drink_reminder/celery.py` 中修改定时规则。