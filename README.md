This is Terraform code for creating VPC in AWS with 3 subnets in different AZ Also it creates 3 instances in different subnets and one load balancer.

in code NOT included file with credentials: "aws_access_key" , "aws_secret_key", "aws_region".

To use remote state in s3 bucket You shoud create your bucket and configure policies for it.

Versions: Terraform v0.11.10 Provider.aws v2.41.0