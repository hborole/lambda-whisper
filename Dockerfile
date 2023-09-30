FROM public.ecr.aws/lambda/python:3.11 as builder

# install helpers
RUN yum -y install tar xz

# install ffmpeg
RUN curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz > /tmp/ffmpeg-release.tar.xz && tar xvf /tmp/ffmpeg-release.tar.xz -C /opt && mv /opt/ffmpeg-* /opt/ffmpeg && cd /opt/ffmpeg && mv model /usr/local/share && mv ffmpeg ffprobe qt-faststart /usr/local/bin && rm /tmp/ffmpeg-release.tar.xz

FROM  public.ecr.aws/lambda/python:3.9 as app
COPY --from=builder /opt/ffmpeg /opt/ffmpeg
COPY --from=builder /usr/local/share/model /usr/local/share
COPY --from=builder /usr/local/bin/ff* /usr/local/bin
COPY --from=builder /usr/local/bin/qt-* /usr/local/bin

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Copy the model file tiny.pt into /tmp folder of the lambda
COPY tiny.pt /tmp
COPY tiny.en.pt /tmp

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "lambda_function.lambda_handler" ]