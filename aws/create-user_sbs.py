#!/usr/bin/python
import os
import boto3
import pandas as pd
import argparse

__author__ = 'nightcrawler'

# Define our IAM client to talk to the API
iam = boto3.client('iam')

# Define arguments
parser = argparse.ArgumentParser(description='Create AWS Users from input file')
parser.add_argument('-i','--input-file',help='input file',required=True)
args = parser.parse_args()

# Get file extension to detect input file type
input_file, input_file_ext = os.path.splitext(args.input_file)

if input_file_ext == '.csv':
    csv = pd.read_csv(args.input_file)
else:
    print("Expected a CSV file, exiting...")
    quit()

# Empty list to fill with usernames
new_users = []

# Loop through the rows in the data frame
# First character of the field labeled 'FirstName' plus
# the field labeled 'LastName' equals the user_name
# Then add to our empty list above
for index, row in csv.iterrows():
    first_init = row['FirstName'][:1]
    last_name = row['LastName']
    user_name = first_init.lower() + last_name.lower()
    new_users.append(user_name)

# Empty list to store current users
current_users = []

# Get current users, so we don't try to create duplicates
eusers = iam.list_users()
for euser in eusers.get('Users', []):
    euname = euser['UserName']
    current_users.append(euname)

# Empty list to store responses from user creation
responses = []

# Loop through the usernames we've created and create the 
# user account in AWS and add the users to the proper groups
for user in new_users:
    # Check if user exists 
    if user in current_users:
        print("%r already exists") % user
    else:
        # If not, create the user
        response = iam.create_user(
            UserName=user
        )
        # Save response
        responses.append(response)
        # Add user to group
        grp_rspnse = iam.add_user_to_group(
            GroupName='NoBilling',
            UserName=user
        )
        # Save response
        grp_responses.append(grp_rspnse)

for response in responses:
    if (response.get('ResponseMetadata'))['HTTPStatusCode'] == 200:
        uname = (response.get('User')['UserName'])
        print("Create user %r - OK") % uname
    else:
        code = (response.get('ResponseMetadata')['HTTPStatusCode'])
        uname = (response.get('User')['UserName'])
        print("Create user %r failed with status code %r") % (uname,code)
