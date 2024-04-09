 ## Step-by-Step Guide: Setting Up Azure Application

1. **Create Azure Application**

   - Go to the [Azure Portal](https://portal.azure.com).
   - Navigate to Azure Active Directory > App Registrations > New Registration.
   - Fill in the registration details as follows:
     - Name: choose a name that fits. e.g. macOS Photo Sync
     - Supported Account Types: Accounts in this organizational directory only
   - Click on "Register" to complete the process.

2. **Configure API Permissions**

   - Remove the User.Read permission.
   - Add New > Microsoft Graph > Application permission > User.Read.All.
   - Save the permission changes.

3. **Manage Client Credentials**

   - In the Overview section, navigate to Client Credentials > Add a certificate or secret.
   - Generate a new client secret with the following details:
     - Description: MacPhotoDownload
     - Expiry: Choose 3, 12, 18, or 24 months.
   - Save the secret value securely. Note that it cannot be retrieved after creation.



4. **Retrieve Application Details**

   - Go back to the Azure Portal and navigate to Azure Active Directory > App Registrations.
   - Select Mac Profile Photo Download to access its details.
   - Note down the following information from the overview page:
     - Application (client) ID
     - Directory (tenant) ID
     - Secret value generated in step 3.
