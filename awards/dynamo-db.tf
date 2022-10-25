resource "aws_dynamodb_table" "belts" {
  name           = "Belts"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "uid"

  attribute {
    name = "uid"
    type = "S"
  }
}
