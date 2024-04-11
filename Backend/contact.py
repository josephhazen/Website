import json
import boto3

def lambda_handler(event, context):
    body = json.loads(event['body'])
    name = body['name']
    email = body['email']
    message = body['message']

    ses = boto3.client('ses')

    sender = 'info@horizontech.cloud'
    recipient = 'jhazen@horizontech.cloud'
    subject = 'New Contact Form Submission'
    body_text = f"Name: {name}\nEmail: {email}\nMessage: {message}"

    # Send the email
    try:
        response = ses.send_email(
            Source=sender,
            Destination={
                'ToAddresses': [recipient]
            },
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body_text}}
            }
        )
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Email sent successfully'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }