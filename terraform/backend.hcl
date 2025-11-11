bucket         = "mb-otr-applications-terraform-state-bucket"
key            = "contract-service/terraform.tfstate"  # For contract service
region         = "ap-south-1"
dynamodb_table = "terraform-locks"  # Optional, for state locking
encrypt        = true
