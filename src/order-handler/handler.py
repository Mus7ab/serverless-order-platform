import json
import os
import uuid
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    body = json.loads(event["body"]) if "body" in event else event

    order_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()

    item = {
        "order_id": order_id,
        "customer_id": body["customer_id"],
        "status": "PLACED",
        "total_amount": str(body["total_amount"]),
        "created_at": created_at,
    }

    table.put_item(Item=item)

    return {
        "statusCode": 201,
        "body": json.dumps({"order_id": order_id, "status": "PLACED"}),
    }
