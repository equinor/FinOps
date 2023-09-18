# FinOps CI/CD

## Github Actions service principal

Authenticating service principals using service principal `clientId`, `clientSecret`, `subscriptionId` and `tenantId`. These are encapsulated in the `AZURE_CREDENTIALS` Github secret, which is based on the following json format:

```json
{
    "clientId": "<GUID>",
    "clientSecret": "<string>",
    "subscriptionId": "<GUID>",
    "tenantId": "<GUID>"
}
```

Using the `S926-FinOps Testing` subscription for dev and test deployments. wheras the `S037-Cost-Management-reservations` is used for production deployment. The service principal used for deployment actions is called `S037-FinOps-SP` and can be found in Azure AD.