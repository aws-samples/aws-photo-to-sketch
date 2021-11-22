
"""
    This Lambda function creates a SageMaker model.
    As input event, it receives the endpoint_name, the image_uri and the execution role. 
"""

import json
import boto3 
     
def lambda_handler(event, context):   
    
    #Amazon SageMaker session
    sm = boto3.client("sagemaker")
    region = boto3.Session().region_name
    
    #Input parameters
    endpoint_name = event['endpoint_name']
    image_uri = event['image_uri']
    role = event['role']
    model_url = event['model_path']
    
    #Create a Model using Amazon SageMaker 
    model = sm.create_model(
        ModelName=endpoint_name,
            Containers=[
                {
                    "Image": image_uri,
                    'Mode': 'SingleModel',
                    'ModelDataUrl': model_url,
                },
            ],
            ExecutionRoleArn=role,
            EnableNetworkIsolation=False,
    )
    
    return {
        "statusCode": 200,
        "body": json.dumps("Created Model!"),
        "model_name": str(endpoint_name),
    }
