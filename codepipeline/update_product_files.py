'''
Update the respective SC product file when a source file changes.
'''
import json
import base64
import argparse
from datetime import datetime
from github import Github
from github import InputGitTreeElement

import boto3
from botocore.exceptions import ClientError

def update_sc_product_version(file_name):
    '''
    Update the file name with latest version
    Increment last digit and add new provisioning artifact.
    '''

    try:
        print('Reading from:', file_name)
        with open(file_name, 'r') as content:
            data = json.load(content)
            content.close()
        prod_obj = data['Resources']['SCProduct']
        artifacts = prod_obj['Properties']['ProvisioningArtifactParameters']
        latest_artifact = artifacts[-1]
        latest_version = latest_artifact['Name']
        temp_list = latest_version.split('.')
        temp_list[-1] = str(int(latest_version.split('.').pop())+1)
        updated_version = ".".join(temp_list)

        new_artifact=latest_artifact.copy()
        new_artifact['Name'] = updated_version
        artifacts.append(new_artifact)
        print('Writing to:', file_name)
        with open(file_name, 'w') as new_content:
            json.dump(data, new_content)
            new_content.close()

        print('File updated')
    except ClientError as exe:
        raise exe


def get_secret(secret_name):
    '''
    Get the value of secret stored in secrets manager
    '''
    session = boto3.session.Session()
    client = session.client('secretsmanager')
    get_secret_value_response = None

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )

    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for
            # the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        else:
            # Decrypts secret using the associated KMS key.
            # Depending on whether the secret is a string or binary,
            # one of these fields will be populated.
            if 'SecretString' in get_secret_value_response:
                secret = get_secret_value_response['SecretString']
            else:
                decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])

    return(get_secret_value_response)

def checkin_to_git_repo(access_key, repo_name, file_path):
    '''
    Checkin the updated files to Git Repository
    '''

    git = Github(access_key)
    repo = git.get_user().get_repo(repo_name)
    file_list = [ file_path ]
    file_name = file_path.split('/')[-1]
    file_names = [ file_name ]

    time_stamp = datetime.now().strftime("%m%d%y-%H%M%S")
    commit_message = 'Commit for ' + file_name + ' at ' + time_stamp

    main_ref = repo.get_git_ref('heads/main')
    main_sha = main_ref.object.sha
    base_tree = repo.get_git_tree(main_sha)

    element_list = list()
    for i, entry in enumerate(file_list):
        with open(entry) as input_file:
            data = input_file.read()
        print('Filename:', file_names[i])
        element = InputGitTreeElement(file_names[i], '100644', 'blob', data)
        element_list.append(element)

    print('Element List:', element_list)
    print('Base Tree:', base_tree)
    tree = repo.create_git_tree(element_list, base_tree)
    parent = repo.get_git_commit(main_sha)
    commit = repo.create_git_commit(commit_message, tree, [parent])
    main_ref.edit(commit.sha)
    print('Code check in complete')

if __name__ == '__main__':
    PARSER = argparse.ArgumentParser(prog='update_product_files.py', usage='%(prog)s -p -s', \
                                    description='Add a new version to the product.')

    #PARSER.add_argument("-a", "--artifact", type=str, required=True, help="Artifact file")
    PARSER.add_argument("-p", "--port_file", type=str, required=True, help="Portfolio name")
    PARSER.add_argument("-s", "--secret_name", type=str, default='github/kkvinjam', \
                        help="secrets manager secret name")
    PARSER.add_argument("-r", "--repo", type=str, default='aws-custom-sc-pipeline', \
                        help="repository name in GitHub repo")

    ARGS = PARSER.parse_args()
    #ARTIFACT = ARGS.artifact
    PORT_FILE = ARGS.port_file
    SECRET = ARGS.secret_name
    REPO = ARGS.repo
    # FILE = 'templates/dev-portfolio/sc-dev-product-ec2-linux.json'

    print('PORT File:', PORT_FILE)
    update_sc_product_version(PORT_FILE)
    pers_access_key = get_secret(SECRET)
    print(pers_access_key)
    if pers_access_key:
        secret_key = json.loads(pers_access_key['SecretString'])['Token']
    checkin_to_git_repo(secret_key, REPO, PORT_FILE)
