#!/bin/bash

# 测试模式监控脚本
# 监控从现在到 15:30 的推送情况

END_TIME="15:30:00"
LOG_FILE="/root/data/drinkWater/celery_worker.log"

echo "=========================================="
echo "喝水提醒系统 - 测试模式监控"
echo "=========================================="
echo "开始时间: $(date '+%H:%M:%S')"
echo "结束时间: $END_TIME"
echo "检查间隔: 每1分钟"
echo "发送间隔: 1-3分钟随机"
echo "=========================================="
echo ""

# 记录已发送的推送
SENT_COUNT=0
LAST_SEND_TIME="14:40"

while true; do
    CURRENT_TIME=$(date '+%H:%M:%S')
    CURRENT_HOUR_MIN=$(date '+%H:%M')
    
    # 检查是否超过 15:30
    if [[ "$CURRENT_TIME" > "$END_TIME" ]]; then
        echo "已达到测试结束时间 15:30"
        break
    fi
    
    # 检查最新的推送记录
    NEW_SENDS=$(tail -50 "$LOG_FILE" | grep "Smart drink reminder sent successfully" | tail -5)
    
    if [ ! -z "$NEW_SENDS" ]; then
        # 提取最后一次发送时间
        LATEST_SEND=$(echo "$NEW_SENDS" | tail -1 | grep -oP '\d{2}:\d{2}' | head -1)
        
        if [ "$LATEST_SEND" != "$LAST_SEND_TIME" ]; then
            SENT_COUNT=$((SENT_COUNT + 1))
            echo "[$CURRENT_HOUR_MIN] ✅ 推送 #$SENT_COUNT - 发送时间: $LATEST_SEND"
            LAST_SEND_TIME="$LATEST_SEND"
        fi
    fi
    
    sleep 30  # 每30秒检查一次
done

echo ""
echo "=========================================="
echo "测试完成！"
echo "总推送次数: $SENT_COUNT"
echo "=========================================="
