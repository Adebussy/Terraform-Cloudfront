# -Cloudfront

##  Diagram

```mermaid
flowchart TD
    A[User] -->|HTTPS Request| B[CloudFront Distribution]
    B -->|Uses Origin Access Identity OAI| C[OAI]
    C -->|Grants Read Access| D[S3 Bucket Static Website]
    D -->|Hosts| E[index.html<br/>error.html]
```

 ## terraform diagram
 ```
 terraform-cloudfront-app/
├── main.tf
├── provider.tf
├── s3.tf
├── cloudfront.tf
├── upload.tf
├── variables.tf
├── outputs.tf
└── modules/
    └── (optional reusable module directories)
```


