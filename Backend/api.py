import boto3
import json

table_name = 'resume_visitors'
dynamodb = boto3.client('dynamodb')

def lambda_handler(event, context):
   response = dynamodb.update_item(
      TableName=table_name,
      Key={
         'visitorcount': {'S': 'visitor-count'}
      },
      UpdateExpression='ADD visitorvalue :val',
      ExpressionAttributeValues={
         ":val" : {"N": "1"}
      },
      ReturnValues='UPDATED_NEW'
   )
   value = response['Attributes']['visitorvalue']['N']
   return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps(value)
    }