import json


def lambda_handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        message = json.loads(body["Message"])
        detail = message["detail"]

        print(
            f"[inventory-updater] Updating inventory for order "
            f"{detail['order_id']} (total: {detail['total_amount']})"
        )

    return {"statusCode": 200}
