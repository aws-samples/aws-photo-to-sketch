# This file implements a flask server for inference. You can modify the file to align with your own inference logic.
from __future__ import print_function

import io
import json
import os
import pickle
import signal
import sys
import traceback

import flask
from flask import request

import tensorflow_hub as hub

import boto3
import base64
import tensorflow as tf
import tensorflow_hub as hub
from PIL import Image
import numpy as np
from io import BytesIO
import json

import pandas as pd

prefix = "/opt/ml"
model_path = os.path.join(prefix, "model")

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

class TensorflowService(object):
    model = None  # Where we keep the model when it's loaded

    @classmethod
    def get_model(cls):
        """Get the model object for this instance, loading it if it's not already loaded."""
        if cls.model == None:
            # Load ML Model from TensorflowHub 
            cls.model = hub.load(model_path)
            print("Tensorflow hub model loaded!")
        return cls.model

    @classmethod
    def predict(cls, content_image, style_image):
        """For the input, do the predictions and return them.
        Args:
            input (a pandas dataframe): The data on which to do the predictions. There will be
                one prediction per row in the dataframe"""
        clf = cls.get_model()
        return clf(tf.constant(content_image), tf.constant(style_image))[0]
    
# The flask app for serving predictions
app = flask.Flask(__name__)


@app.route("/ping", methods=["GET"])
def ping():
    """Determine if the container is working and healthy.
    In this sample container, we declare
    it healthy if we can load the model successfully."""

    health = TensorflowService.get_model() is not None  # You can insert a health check here

    status = 200 if health else 404
    return flask.Response(response="\n", status=status, mimetype="application/json")


@app.route("/invocations", methods=["POST"])
def inference():
    """Performed an inference on incoming data.
    In this sample server, we take data as application/json,
    print it out to confirm that the server received it.
    """
    content_type = flask.request.content_type
    if flask.request.content_type != "application/json":
        msg = "I just take json, and I am fed with {}".format(content_type)
    else:
        msg = "I am fed with json. Therefore, I am happy"

    
    data = flask.request.data.decode("utf-8")
    data = io.StringIO(data)
    data = json.loads(data.read())
    
    account_id = boto3.client("sts").get_caller_identity()["Account"]
    region = boto3.Session().region_name
    
    bucket_name = f"photo-to-sketch-{account_id}"
    dict_style = {"1":"style/1.jpeg","2":"style/2.jpeg","3":"style/3.jpeg","4":"style/4.jpeg"}
    effect_type = dict_style[data["effectType"]]
    
    #Style image
    style_image_object = read_image_from_s3(bucket_name, effect_type)
    style_image = load_img(style_image_object)
    print("Style image loaded!")
    
    # Content image
    input_image = data['image']
    content_image_object = Image.open(BytesIO(base64.b64decode(input_image)))
    content_image = load_img(content_image_object)
    print("Content image loaded!")
    
    stylized_image = TensorflowService.predict(content_image,style_image)
    stylized_image = tensor_to_image(stylized_image)  
    
    #Encode the response to base64 
    buffered = BytesIO()
    stylized_image.save(buffered, format="JPEG")
    img_str = base64.b64encode(buffered.getvalue())
    print("Stylized image generated!")
    
    return flask.Response(
        response=json.dumps({"image": img_str.decode("utf-8")}),
        status=200,
        mimetype="text/plain",
    )