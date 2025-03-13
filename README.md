# Terraform-Cloudfront

##  Diagram

```mermaid
flowchart TD
    A[User] -->|HTTPS Request| B[CloudFront Distribution]
    B -->|Uses Origin Access Identity OAI| C[OAI]
    C -->|Grants Read Access| D[S3 Bucket Static Website]
    D -->|Hosts| E[index.html<br/>error.html]
