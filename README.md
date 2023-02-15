# hashitalks-2023-boundary
Demo code for HashiTalks 2023 Boundary Presentation

Set the environment variables for the demo:

```bash
export BOUNDARY_ADDR="https://HCP_BOUNDARY_ADDR"

# Log into Boundary and get the token value
boundary authenticate password -auth-method-id=METHOD_ID -login-name=LOGIN_NAME

# Set the token value if it's not exported
export BOUNDARY_TOKEN="TOKEN_VALUE"
```
