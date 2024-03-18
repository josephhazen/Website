
import boto3
import json

table_name = 'resume_visitors'
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    #Update the count
    response = table.update_item(
         Key={
            'count'
         }
         UpdateExpression= 'ADD count :val',
         ExpressionAttributeValues = {":val" : {"N": "1"}},
         ReturnValues = 'UPDATED_NEW'
    )

    #Return the value
    value = response['Attributes']['Quantity']['N']
    return {      
            'statusCode': 200,
            'body': value}
