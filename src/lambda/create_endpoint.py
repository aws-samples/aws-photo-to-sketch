
"""
    This Lambda function creates an Endpoint Configuration and deploys a model to an Endpoint. 
    The name of the model to deploy is provided via the event argument.
    The Lambda also saves the endpoint_name in Parameter Store.
"""

import json
import boto3 
import time
    
def lambda_handler(event, context):    
    
    #Amazon SageMaker session
    sm = boto3.client("sagemaker")
    region = boto3.Session().region_name
    endpoint_name = event["endpoint_name"]
    
    time.sleep(10)
    
    #Create Endpoint Configuration & endpoint in a Lambda
    endpoint_config = sm.create_endpoint_config(
        EndpointConfigName=endpoint_name,
        ProductionVariants=[
            {
                'VariantName': endpoint_name,
                'ModelName': endpoint_name,
                'InitialInstanceCount': 1,
                'InstanceType': 'ml.m4.xlarge',
            }
        ]
    )
        
    #Create Endpoint
    endpoint = sm.create_endpoint(
        EndpointName=endpoint_name,
        EndpointConfigName=endpoint_name
    )
    
    #Register endpoint name to Parameter Store
    ssm = boto3.client('ssm')
    ssm.put_parameter(Name='endpoint_name',Value=endpoint_name,Type='String',Overwrite=True)
    
    return {
        "statusCode": 200,
        "body": json.dumps("Created Endpoint!")
    }
