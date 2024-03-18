import boto3
import json

table_name = 'resume_visitors'
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
   response = table.update_item(
      Key={
         'count': '0'
         },
      UpdateExpression='ADD count :val',
      ExpressionAttributeValues={
         ':val': 1
         },
      ReturnValues='UPDATED_NEW'
   )
    #Return the value
   value = response['Attributes']['count']['N']
   return {      
            'statusCode': 200,
            'body': value}
