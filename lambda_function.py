import json
import os
import boto3
import whisper

# model_path = os.path.join('/tmp', 'tiny.pt')
# print('Loading model from path', os.path.isfile(model_path))

def lambda_handler(event, context):
    # Download file from s3
    s3 = boto3.client('s3')
    bucket, key = 'orakly-lambda', 'test.mp4'
    print('Bucket:', bucket, 'key:', key)

    # Create a directory to store the downloaded file
    os.makedirs('/tmp/data', exist_ok=True)
    file_to_transcribe = '/tmp/data/{}'.format(key)
    print('File to transcribe', file_to_transcribe)

    if not key:
        return json.dumps({'error': 'Missing "key" parameter'}), 400

    try:
        # Downloading file to transcribe
        s3.download_file(bucket, key, file_to_transcribe)
        print('File downloaded successfully', os.listdir())

        # Load the model
        model = whisper.load_model('tiny', download_root='/tmp')
        print('Model loaded successfully')
        result = model.transcribe(file_to_transcribe, fp16=False)
        print(result['text'])

        # Delete the downloaded file
        os.remove(file_to_transcribe)

        # Delete the file from s3
        # s3.delete_object(Bucket=bucket, Key=key)

        return json.dumps({'transcript': result['text']}), 200
    except Exception as e:
        print(e)
        return json.dumps({'error': str(e)}), 500