resource "aws_api_gateway_rest_api" "awards" {
  name = "Awards"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_stage" "awards" {
  rest_api_id   = aws_api_gateway_rest_api.awards.id
  deployment_id = aws_api_gateway_deployment.awards.id
  stage_name    = "v1"
}

resource "aws_apigatewayv2_api_mapping" "awards" {
  api_id          = aws_api_gateway_rest_api.awards.id
  stage           = aws_api_gateway_stage.awards.stage_name
  domain_name     = "api.coderdojokinsale.com"
  api_mapping_key = "v1/awards"
}

resource "aws_api_gateway_method" "get_awards" {
  rest_api_id   = aws_api_gateway_rest_api.awards.id
  resource_id   = aws_api_gateway_rest_api.awards.root_resource_id
  authorization = "NONE"
  http_method   = "GET"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.awards.id
  resource_id = aws_api_gateway_rest_api.awards.root_resource_id
  http_method = aws_api_gateway_method.get_awards.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "get_awards" {
  rest_api_id             = aws_api_gateway_rest_api.awards.id
  resource_id             = aws_api_gateway_rest_api.awards.root_resource_id
  http_method             = aws_api_gateway_method.get_awards.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:eu-west-1:dynamodb:action/Scan"
  credentials             = "arn:aws:iam::770708881166:role/api-gateway-dynamodb"
  request_templates = {
    "application/json" = <<EOF
      {
          "TableName": "awards",
          "PartitionKey": "uid"
      }
    EOF
  }
}

resource "aws_api_gateway_integration_response" "get_awards" {
  rest_api_id = aws_api_gateway_rest_api.awards.id
  resource_id = aws_api_gateway_rest_api.awards.root_resource_id
  http_method = aws_api_gateway_method.get_awards.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  response_templates = {
    "application/xml" = <<EOF
      #set($inputRoot = $input.path('$'))
      [
        #foreach($elem in $inputRoot.Items) {
            "uid": "$elem.uid.S",
            "name": "$elem.name.S",
            "description": "$elem.description.S"
        }#if($foreach.hasNext),#end
	      #end
      ]
    EOF
  }
}


resource "aws_api_gateway_resource" "awards_by_id" {
  rest_api_id = aws_api_gateway_rest_api.awards.id
  parent_id   = aws_api_gateway_rest_api.awards.root_resource_id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "get_awards_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.awards.id
  resource_id   = aws_api_gateway_resource.awards_by_id.id
  authorization = "NONE"
  http_method   = "GET"
}

resource "aws_api_gateway_method_response" "get_awards_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.awards.id
  resource_id = aws_api_gateway_resource.awards_by_id.id
  http_method = aws_api_gateway_method.get_awards_by_id.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "get_awards_by_id" {
  rest_api_id             = aws_api_gateway_rest_api.awards.id
  resource_id             = aws_api_gateway_resource.awards_by_id.id
  http_method             = aws_api_gateway_method.get_awards_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:eu-west-1:dynamodb:action/Query"
  credentials             = "arn:aws:iam::770708881166:role/api-gateway-dynamodb"
  request_templates = {
    "application/json" = <<EOF
      {
        "TableName": "awards",
        "PartitionKey": "uid",
        "KeyConditionExpression": "uid = :v1",
        "ExpressionAttributeValues": {
            ":v1": {
                "S": "$input.params('id')"
            }
        }
    }
    EOF
  }
}

resource "aws_api_gateway_integration_response" "get_awards_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.awards.id
  resource_id = aws_api_gateway_resource.awards_by_id.id
  http_method = aws_api_gateway_method.get_awards_by_id.http_method
  status_code = aws_api_gateway_method_response.get_awards_by_id_200.status_code
  response_templates = {
    "application/xml" = <<EOF
      #set($inputRoot = $input.path('$'))
        #foreach($elem in $inputRoot.Items) {
            "uid": "$elem.uid.S",
            "name": "$elem.name.S",
            "description": "$elem.description.S"
        }#if($foreach.hasNext),#end
	      #end
    EOF
  }
}

resource "aws_api_gateway_deployment" "awards" {
  rest_api_id = aws_api_gateway_rest_api.awards.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get_awards.id,
      aws_api_gateway_resource.awards_by_id.id,
      aws_api_gateway_method.get_awards_by_id.id,
      aws_api_gateway_integration.get_awards_by_id.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


