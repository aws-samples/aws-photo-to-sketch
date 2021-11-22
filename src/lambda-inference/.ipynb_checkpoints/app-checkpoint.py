import boto3
import base64
import tensorflow as tf
import tensorflow_hub as hub
from PIL import Image
import numpy as np
from io import BytesIO
import json


def load_img(image_object):
    """
        Load image from Amazon S3 bucket and processed it.
    """
    max_dim = 512
    img = tf.keras.preprocessing.image.img_to_array(image_object)
    img = tf.convert_to_tensor(img, dtype=tf.float32)
    shape = tf.cast(tf.shape(img)[:-1], tf.float32)
    long_dim = max(shape)
    scale = max_dim / long_dim
    new_shape = tf.cast(shape * scale, tf.int32)
    img = tf.image.resize(img, new_shape)
    img = img[tf.newaxis, :] / 255
    return img


def read_image_from_s3(bucket_name, key):
    """S3 to PIL Image"""
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(bucket_name)
    object = bucket.Object(key)
    response = object.get()
    return Image.open(response['Body'])


def tensor_to_image(tensor):
    """
        Transform tensor to image.
    """
    tensor = tensor * 255
    tensor = np.array(tensor, dtype=np.uint8)
    if np.ndim(tensor) > 3:
        assert tensor.shape[0] == 1
        tensor = tensor[0]
    return Image.fromarray(tensor)


def upload_s3(stylized_image, bucket_name):
    """
        Save Image to Amazon S3 for verification purposes. 
    """
    file_name = '/tmp/stylized-image.png'
    stylized_image.save(file_name)
    s3_resource = boto3.resource('s3')
    s3_resource.Bucket(bucket_name).upload_file(file_name, "export/stylized-image.png")


def lambda_handler(event, context):
    """
        Lambda Handler for Image Processing logic.
    """

    #Load the event 
    print("My event: {}\n".format(event))
    try:
        event = json.loads(event['body'])
    except:
        event = event['body']
    
    # Content image pre-processing
    input_image = event["image"]  
    content_image_object = Image.open(BytesIO(base64.b64decode(input_image)))
    content_image = load_img(content_image_object)
    content_image = tensor_to_image(content_image)

    #Encode content image scaled to base64 
    buffered = BytesIO()
    content_image.save(buffered, format="JPEG")
    img_str = base64.b64encode(buffered.getvalue())
    event["image"] = img_str.decode("utf-8")
        
    #Read endpoint name from Parameter store
    ssm = boto3.client('ssm')
    endpoint_name = ssm.get_parameter(Name='endpoint_name')
    endpoint_name = endpoint_name['Parameter']['Value']
    print("Using endpoint: {}".format(endpoint_name))
        
    #Invoke endpoint
    sm_runtime = boto3.client('sagemaker-runtime')

    response = sm_runtime.invoke_endpoint(
        EndpointName=endpoint_name,
        Body=json.dumps(event),
        ContentType='application/json',
        Accept='application/json'
    )
    result = json.loads(response['Body'].read())
    
    #Lambda response back to API Gateway
    response = {'headers': {"Content-Type": "image/jpg"},
                'statusCode': 200,
                'body': json.dumps(result),
                'isBase64Encoded': True}
    print(response)
    return response