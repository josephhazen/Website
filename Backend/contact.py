import json
import boto3

recipient_email = 'jhazen@horizontech.cloud'
sender_email = 'info@horizontech.cloud'
ses_client = boto3.client('ses', region_name='us-east-1')
def lambda_handler(event, context):

    body = json.loads(event['body'])
    name = body.get('name', '')
    email = body.get('email', '')
    message = body.get('message', '')

    # Send email to recipient
    subject = 'New Contact Form Submission'
    body_text = f'Name: {name}\nEmail: {email}\nMessage: {message}'
    try:
        response = ses_client.send_email(
            Source=sender_email,
            Destination={'ToAddresses': [recipient_email]},
            Message={'Subject': {'Data': subject}, 'Body': {'Text': {'Data': body_text}}}
        )
        print("Email sent successfully to recipient:", response)
    except Exception as e:
        print("Email sending failed to recipient:", e)

    # Send email to customer
    subject = 'Contact Information Received'
    body_text = 'Your contact information has been received. We will get back to you shortly.'
    try:
        response = ses_client.send_email(
            Source=sender_email,
            Destination={'ToAddresses': [email]},
            Message={'Subject': {'Data': subject}, 'Body': {'Text': {'Data': body_text}}}
        )
        print("Email sent successfully to customer:", response)
    except Exception as e:
        print("Email sending failed to customer:", e)

    # Return HTTP response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Emails sent successfully'})
    }