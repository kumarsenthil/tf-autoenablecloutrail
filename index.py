import json
import boto3

print('Loading function')
def lambda_handler(event, context):
    try:
        client = boto3.client('cloudtrail')
        if event['detail']['eventName'] == 'StopLogging':
            response = client.start_logging(Name=event['detail']['requestParameters']['name'])
    
    except:
        print("Exception")
        