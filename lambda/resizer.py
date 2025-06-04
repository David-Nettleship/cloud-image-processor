import boto3
from PIL import Image
import io

s3 = boto3.client("s3")


def lambda_handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        # Only process images in the "uploads/" folder
        if not key.startswith("uploads/"):
            continue

        # Download the file
        response = s3.get_object(Bucket=bucket, Key=key)
        image_data = response["Body"].read()

        # Resize the image
        with Image.open(io.BytesIO(image_data)) as img:
            img.thumbnail((128, 128))
            buffer = io.BytesIO()
            img.save(buffer, format="JPEG")
            buffer.seek(0)

            # Save thumbnail to "thumbnails/" folder
            thumb_key = key.replace("uploads/", "thumbnails/", 1)
            s3.put_object(
                Bucket=bucket, Key=thumb_key, Body=buffer, ContentType="image/jpeg"
            )

    return {"statusCode": 200, "body": "Thumbnail(s) created."}
