# 喝水提醒系统

这是一个基于 Django 和 Celery 的喝水提醒系统，会定时通过 Server酱 发送微信推送消息提醒用户喝水。

## 功能特性

- 每隔指定时间自动发送喝水提醒
- 支持手动发送测试通知
- 系统状态监控页面
- 使用 Server酱 进行消息推送

## 部署说明

### 1. 环境准备

```bash
# 克隆项目
git clone <your-repo-url>
cd drink_reminder

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置 Server酱

1. 获取 Server酱 SCKEY：
   - 访问 [Server酱官网](https://sct.ftqq.com/)
   - 扫码关注并获取 SCKEY

2. 编辑 `config.py` 文件：
   ```python
   SERVER_CHAN_TOKEN = "YOUR_SCKEY_HERE"  # 替换为你的 SCKEY
   DRINK_REMINDER_TITLE = "喝水提醒"      # 提醒标题
   DRINK_REMINDER_MESSAGE = "记得喝水哦！保持身体水分充足对健康很重要。"  # 提醒内容
   REMINDER_INTERVAL_HOURS = 2  # 提醒间隔（小时）
   ```

### 3. 数据库迁移

```bash
python manage.py migrate
```

### 4. 启动应用

需要启动两个进程：

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
drink_reminder/          # 主项目目录
├── config.py           # 配置文件
├── manage.py           # Django 管理脚本
├── requirements.txt    # 依赖列表
├── drink_reminder/     # Django 配置目录
│   ├── __init__.py
│   ├── settings.py
│   ├── settings_prod.py # 生产环境设置
│   ├── urls.py
│   └── wsgi.py
└── reminder/           # 提醒功能应用
    ├── __init__.py
    ├── admin.py
    ├── apps.py
    ├── models.py
    ├── services.py     # Server酱 服务
    ├── tasks.py        # Celery 任务
    ├── views.py
    ├── urls.py
    ├── templates/      # 模板文件
    └── static/         # 静态文件
```

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

默认情况下，系统每 2 小时发送一次提醒（在每个小时的第 0 分钟）。你可以在 `drink_reminder/celery.py` 中修改定时规则。