# FROM ubuntu:18.04

FROM public.ecr.aws/v0b5s6b3/tensorflow/tensorflow:2.3.0

RUN apt-get -y update && apt-get install -y --no-install-recommends \
         wget \
         python3-pip \
         python3-setuptools \
         nginx \
         ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python
RUN ln -s /usr/bin/pip3 /usr/bin/pip


# Copy the earlier created requirements.txt file to the container
COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt 


ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV PATH="/opt/program:${PATH}"

# Set up the program in the image
COPY src /opt/program
WORKDIR /opt/program
