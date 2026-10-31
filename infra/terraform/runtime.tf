# --- The AgentCore Runtime itself ---------------------------------------------
#
# This is the managed, serverless host for our agent container. It pulls the
# :latest image from our ECR repo and runs it, speaking the HTTP contract
# (GET /ping + POST /invocations) our board/runtime.py implements.
#
# NOTE on apply ordering: the runtime points at an image tag that only exists
# after CI builds and pushes it. So the deploy sequence is: apply with
# deploy_runtime=false (ECR + roles), push the image, then apply with
# deploy_runtime=true to create this runtime. The var.deploy_runtime count below
# makes that a clean one-flag toggle instead of a failed partial apply — and the
# same flag is the up/down lever (drop just the memory-billed runtime).

resource "aws_bedrockagentcore_agent_runtime" "board" {
  # See the note above: false = ECR + roles only; true = full stack.
  count = var.deploy_runtime ? 1 : 0

  agent_runtime_name = local.runtime_name
  role_arn           = aws_iam_role.runtime.arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.board.repository_url}:latest"
    }
  }

  # PUBLIC = AWS gives the runtime egress to reach Bedrock without us running a VPC.
  network_configuration {
    network_mode = "PUBLIC"
  }

  # Our container serves plain HTTP (not MCP/A2A).
  protocol_configuration {
    server_protocol = "HTTP"
  }

  # Cost lever: reclaim an idle session's memory after 3 minutes so we stop
  # paying for it between demo invocations.
  lifecycle_configuration {
    idle_runtime_session_timeout = 180
    # AWS defaults max_lifetime to 28800s (8h). Set it explicitly so Terraform's
    # plan matches what the API returns (otherwise: "inconsistent result" error).
    max_lifetime = 28800
  }

  # Make the dependency on the policy explicit: the role must have its
  # permissions before the runtime tries to use it.
  depends_on = [aws_iam_role_policy.runtime]
}
