import json
import os
import uuid
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])
events_client = boto3.client("events")
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]


def lambda_handler(event, context):
    try:
        body = json.loads(event["body"]) if "body" in event else event
    except (json.JSONDecodeError, TypeError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON in request body"}),
        }

    if "customer_id" not in body or "total_amount" not in body:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing required fields: customer_id, total_amount"}),
        }

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

    events_client.put_events(
        Entries=[
            {
                "Source": "order-handler",
                "DetailType": "OrderPlaced",
                "EventBusName": EVENT_BUS_NAME,
                "Detail": json.dumps(
                    {
                        "order_id": order_id,
                        "customer_id": body["customer_id"],
                        "total_amount": str(body["total_amount"]),
                        "created_at": created_at,
                    }
                ),
            }
        ]
    )

    return {
        "statusCode": 201,
        "body": json.dumps({"order_id": order_id, "status": "PLACED"}),
    }
