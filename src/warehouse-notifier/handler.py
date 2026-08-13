import json


def lambda_handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        message = json.loads(body["Message"])
        detail = message["detail"]

        print(
            f"[warehouse-notifier] Notifying warehouse to prepare shipment "
            f"for order {detail['order_id']} (customer: {detail['customer_id']})"
        )

    return {"statusCode": 200}
