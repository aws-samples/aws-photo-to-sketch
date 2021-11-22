# Pull the base image with python 3.7 as a runtime for your Lambda
FROM public.ecr.aws/lambda/python:3.7

# Copy the earlier created requirements.txt file to the container
COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt 

# Copy the earlier created app.py file to the container
COPY app.py ./

# Set the CMD to your handler
CMD ["app.lambda_handler"]