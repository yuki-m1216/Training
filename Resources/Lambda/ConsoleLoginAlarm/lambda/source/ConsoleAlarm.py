import json
import urllib.request
import os
import time

def lambda_handler(event, context):
    print(json.dumps(event))
    detail = event['detail']
    post_slack(detail)
    return

def post_slack(detail):
    username = get_user_name(detail['userIdentity'])
    eventname = detail['eventName']
    eventresult = next(iter(detail['responseElements'].items()))[1]
    if username == "Root":
        send_data = {
            "attachments":[
                {
                    "fallback": "attachment",
                    "color": "danger",
                    "text": 
                        "ユーザー名：" + username + "\n" 
                        + "イベント名：" + eventname + "\n" 
                        + "結果：" + eventresult,
                    "ts": int(time.time())
                }
            ]
        }
    else:
        send_data = {
            "attachments":[
                {
                    "fallback": "attachment",
                    "text": 
                        "ユーザー名：" + username + "\n" 
                        + "イベント名：" + eventname + "\n" 
                        + "結果：" + eventresult,
                    "ts": int(time.time())
                }
            ]
        }
        
    send_text = "payload=" + json.dumps(send_data)
    request = urllib.request.Request(
        os.environ['webhookURL'], 
        data=send_text.encode("utf-8"), 
        method="POST"
    )
    with urllib.request.urlopen(request) as response:
        response_body = response.read().decode("utf-8")
        
def get_user_name(userIdentity):
    if userIdentity['type'] == "Root":
        return "Root"
    elif userIdentity['type'] == "IAMUser":
        return userIdentity['userName']
    else:
        return json.dumps(userIdentity)
    