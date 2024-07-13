# github actions
## azure terraform
```mermaid
graph TD;
  push --> 1["Checkov Compliance Scan"]
  1 --> 2["Terraform Setup and Plan"]
  2 --> MS["Member Server"]
```
