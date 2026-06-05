#!/bin/bash
# cronで毎日指定時刻に実行し、問題あるものはSlackの個人DMに通知するスクリプト

source .env  # .envファイルを読み込む

# ssh接続テンプレ
SSH_CMD="ssh MachineLearningServer_Production"

# SSH接続先のエラーログ
ERROR_LOGS=(
    "/home/ec2-user/EntityExtractor/company_register/logs/company_register.log"
    "/home/ec2-user/EntityExtractor/rakuten_securities/logs/rakuten_data.log"
    "/home/ec2-user/DailyKanaListUploaderApp/app/logs/dailykanalist_uploader.log"
    "/home/ec2-user/ScrapingLocalNews/logfile/ScrapingLocalNews.log"
)

# エラーログ行数の閾値
ERROR_LOG_THRESHOLD=10

# エラーログを確認する関数
check_error_logs() {
    for log in "${ERROR_LOGS[@]}"; do
        # 指定エラーログの行数を確認
        log_lines=$($SSH_CMD "wc -l $log" | awk '{print $1}')
        if [ "$log_lines" -lt "$ERROR_LOG_THRESHOLD" ]; then
            # 最終エラーログの内容を確認し、 "INFO:"が無い場合はエラーとみなす
            if ! $SSH_CMD "tail -n 1 $log" | grep -qE "INFO:? "; then
                send_slack_notification "$log: スクリプトが正常に動いていない可能性があります。確認してください。"
            fi
        fi
    done
}

# Slack通知の関数（例）
send_slack_notification() {
    local message="$1"
    curl https://slack.com/api/chat.postMessage \
        -X POST \
        -H 'Content-type: application/json; charset=utf-8' \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        --data "{\"channel\":\"${SLACK_CHANNEL_ID}\",\"text\":\"$message\"}"
}

# メイン処理
check_error_logs