import boto3
import json

table_name = 'resume_visitors'
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
   response = table.update_item(
      Key = {
         'visitorcount': {'S': 'visitorvalue'}
      },
      UpdateExpression='ADD visitorcount :val',
      ExpressionAttributeValues={
         ':val': 1
      },
      ReturnValues='UPDATED_NEW'
   )
    #Return the value
   value = response['Attributes']['visitorcount']['N']
   return {      
            'statusCode': 200,
            'body': value}