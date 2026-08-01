FROM public.ecr.aws/lambda/python:3.12@sha256:25c18513b06eeecf56635e9caaf69f3c0b0235ef50b90cfa3c17d2d6c4ffd4b3

COPY backend/requirements.txt ${LAMBDA_TASK_ROOT}/requirements.txt
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

COPY backend/src ${LAMBDA_TASK_ROOT}/src

CMD ["src.lambda_handler.handler"]
