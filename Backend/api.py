
import boto3
import json
from botocore.exceptions import ClientError

table_name = 'Visitors'
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    # Print event data to logs .. 
    print("Received event: " + json.dumps(event))
    try:
        # Parse the incoming JSON payload
        payload = json.loads(event['body'])
        ip_address = payload.get('ip_address')

        if not ip_address:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing ip_address in payload'})
            }

        # Check if IP address already exists in the DynamoDB table
        response = table.get_item(Key={'ip_address': ip_address})
        if 'Item' in response:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'IP address already exists'})
            }

        # Add the IP address to the DynamoDB table
        table.put_item(Item={'ip_address': ip_address})

        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'IP address added successfully'})
        }

    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }