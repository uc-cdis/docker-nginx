FROM docker.io/python:3.9.6

RUN pip install --upgrade pip
RUN pip install boto3 config cloudpickle kfp
RUN pip install pandas petl requests utils
