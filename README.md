# Serverless Event-Driven Order Platform

A production-style order processing pipeline built on AWS Lambda, API Gateway, DynamoDB, EventBridge, SNS, and SQS — fully defined in Terraform, with distributed tracing via X-Ray.

![Architecture](docs/screenshots/05-architecture-diagram.png)

## 1. Problem statement

Most portfolio projects demonstrate always-on compute (EC2, ECS, EKS). This project demonstrates the opposite: an event-driven, serverless order pipeline where nothing runs until a request arrives, downstream processing happens asynchronously and in parallel, and failures in one consumer never affect the others. It simulates a realistic e-commerce order flow: an order is placed, persisted, and then independently triggers email confirmation, warehouse notification, and inventory update workflows.

## 2. Requirements

- Accept order requests over a public HTTP endpoint
- Persist orders durably with the ability to query by both order ID and customer ID
- Notify three independent downstream systems (email, warehouse, inventory) per order, with failure isolation between them
- Guarantee no order event is silently lost, even under repeated consumer failure
- Provide distributed tracing across the full request path
- Stay within AWS free-tier costs for portfolio-scale testing (create, test, destroy per session)

## 3. Architecture

**Synchronous path:** `API Gateway (HTTP API)` leads to `order-handler` Lambda leads to `DynamoDB` (orders table, on-demand billing, GSI on customer_id/created_at)

**Asynchronous fan-out path:** `order-handler` also publishes an `OrderPlaced` event to a custom `EventBridge` bus, a rule routes it to an SNS topic, the topic fans out independently to three SQS queues (email, warehouse, inventory), each with its own dead-letter queue, each queue triggers its own consumer Lambda via an event source mapping.

**Tracing:** AWS `X-Ray` active tracing is enabled on all four Lambdas, automatically capturing sub-segments for every downstream AWS SDK call (DynamoDB writes, EventBridge publishes) with zero code instrumentation required.

All infrastructure is defined in modular Terraform (dynamodb, iam, lambda, api-gateway, eventbridge, sns-sqs modules), using S3 remote state with native locking, and reuses conventions established in Projects 1-4 of this portfolio.

## 4. Trade-offs

- **HTTP API over REST API** (API Gateway): about 3x cheaper per request and simpler to configure, at the cost of more limited native X-Ray integration and no built-in request validation; validation was implemented entirely in the Lambda instead.
- **SNS fan-out over direct EventBridge-to-SQS targeting**: adds one extra hop, but is what enables true fan-out isolation; each consumer queue is independent, so a failure in one never blocks or slows the others.
- **`str()` over `Decimal`** for monetary values: simpler for a portfolio scope, but not production-correct; see Possible Improvements.
- **Kept the Terraform-deprecated `hash_key`/`range_key` syntax** over the newer `key_schema` syntax for aws_dynamodb_table, after discovering the replacement has active, documented bugs (including destructive GSI recreation) in the AWS provider. Verified via the provider's GitHub issue tracker rather than assumed.

## 5. Cost considerations

Every AWS service used here is either free at idle (Lambda, API Gateway, SNS, SQS, EventBridge, all pay-per-use with generous free tiers) or free-tier covered at portfolio test volume (DynamoDB on-demand). Real infrastructure was created, tested, and destroyed within each session, never left running between sessions. Verified actual cost across all 8 build days: effectively $0.

## 6. Security decisions

- **Every IAM role is scoped** to the specific resource ARN it needs (e.g. order-handler can PutItem/GetItem only on the orders table, not dynamodb:* on "*"); containing blast radius from bugs or compromise to a single resource, not the whole account.
- **Every cross-service trust relationship** (API Gateway to Lambda, EventBridge to SNS, SNS to SQS) uses an explicit resource-based policy with a SourceArn/ArnEquals condition, preventing the confused deputy problem where any caller of that AWS service, not just this specific resource, could invoke or publish.
- **`AWSXRayDaemonWriteAccess`** is the one broad managed policy used; justified because its capability (writing trace telemetry) has no meaningful blast radius even applied broadly, unlike data-access permissions.
- **Terraform state** is stored in a versioned, encrypted S3 bucket with native locking, preventing concurrent-write corruption and enabling rollback if state is ever corrupted.

## 7. Failure scenarios

- **SQS retry and DLQ**: each queue has maxReceiveCount = 3; after 3 failed processing attempts a message moves automatically to its dedicated dead-letter queue rather than retrying forever or being silently dropped.
- **Consumer isolation**: verified live; because each consumer has its own SQS queue subscribed independently to the SNS topic, a failure in warehouse-notifier cannot affect email-notifier or inventory-notifier.
- **Real incident (Day 7)**: mid-apply, a network interruption caused an S3 state upload failure and left 3 SQS queues marked tainted by Terraform (created successfully, but their post-create verification call had timed out). Rather than assume corruption, the incident was diagnosed methodically: verified connectivity, cross-checked terraform state list against real AWS resources, inspected the actual plan diff before touching apply again. Terraform's taint mechanism safely destroyed and recreated the 3 affected (empty, message-free) queues with zero data loss. Full recovery confirmed via a clean terraform plan showing no drift.
- **Known limitation — dual-write problem**: the DynamoDB write and EventBridge publish are two separate, non-atomic calls. If the DynamoDB write succeeds but the EventBridge publish fails, the order exists but no downstream consumer is ever notified. The ordering (DB write first) was chosen deliberately so DynamoDB remains the source of truth, but this does not fully solve the problem; see Possible Improvements.

## 8. Lessons learned

- Terraform deprecation warnings do not always mean migrate immediately; verified via the provider's own issue tracker that the suggested replacement (key_schema) had an active bug, and made the informed call to keep the deprecated syntax.
- SQS's failure model is precise: a message is only successful when explicitly deleted, not merely when the Lambda code finishes running without an exception; meaning a crash after real side effects still triggers redelivery and duplicate processing (at-least-once delivery, not exactly-once).
- Proxy integration between API Gateway and Lambda means API Gateway transports, but Lambda alone is responsible for input validation and turning failures into proper 4xx vs 5xx responses.
- Heredoc (cat > file << EOF) proved more reliable than interactive nano for pasting multi-line Terraform blocks in this environment, after two file-save failures traced back to terminal/editor interaction issues rather than content errors.

## 9. Possible improvements

- **Idempotent consumers**: use order_id as an idempotency key (e.g. a DynamoDB conditional write per consumer) to guard against SQS's at-least-once delivery causing duplicate side effects (duplicate emails, duplicate inventory decrements).
- **Partial batch failure reporting**: currently, one bad message in an SQS batch fails the entire batch, redelivering already-successful messages too. AWS Lambda supports reporting which specific message IDs failed; a real fix, not implemented here to keep consumer code simple.
- **Transactional outbox pattern**: to properly solve the DynamoDB/EventBridge dual-write problem, write the event to an outbox table (via DynamoDB Streams) instead of publishing directly from the Lambda; guarantees the event is eventually published if and only if the DB write succeeded.
- **`Decimal` instead of `str()`** for monetary values, enabling numeric queries and aggregations directly in DynamoDB.
- Confirm and, if needed, recreate a remote-state bucket for Project 3 (EKS); none was found during a cross-portfolio S3 bucket audit while building this project's own state backend.

## Evidence

| Screenshot | Shows |
|---|---|
| docs/screenshots/01-eventbridge-rule.png | EventBridge rule matching OrderPlaced events |
| docs/screenshots/02-sns-fanout.png | SNS topic with all 3 SQS subscriptions |
| docs/screenshots/03-consumer-logs.png | A consumer Lambda processing a real order end-to-end |
| docs/screenshots/04-xray-trace.png | A live X-Ray distributed trace |
| docs/screenshots/05-architecture-diagram.png | Full system architecture |

## Repository structure

Terraform root: main.tf, provider.tf, backend.tf, outputs.tf, plus a modules folder containing dynamodb, iam, lambda, api-gateway, eventbridge, and sns-sqs.

Source code: src/order-handler for the API-facing Lambda, and src/email-notifier, src/warehouse-notifier, src/inventory-notifier for the three SQS consumers.

Evidence: docs/screenshots.

## Deploy

Run terraform init followed by terraform apply from the terraform directory.

## Teardown

Run terraform destroy from the terraform directory. Every session in this project followed a strict create, test, verify, destroy discipline; no resources were left running between sessions.
