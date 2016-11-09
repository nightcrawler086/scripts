#!/usr/bin/python
import os
import boto3
import pandas as pd
import argparse

__author__ = 'nightcrawler'

# Define our IAM client to talk to the API
client = boto3.client('iam')

# Define arguments
# Add argument for username list
parser = argparse.ArgumentParser(description='Create AWS Users from input file')
parser.add_argument('-i','--input-file',help='input file',required=True)
parser.add_argument('-g','--group',help='group to add users to',required=False)
parser.add_argument('-u','--users',help='list of usernames',required=False)
args = parser.parse_args()

# Get file extension to detect input file type
input_file, input_file_ext = os.path.splitext(args.input_file)

if input_file_ext == '.csv':
    print("Input file is CSV")
    csv = pd.read_csv(args.input_file)
else:
    print("Expected a CSV file, exiting...")
    quit()

#for index, row in csv.iterrows():
#    print row['FirstName'], row['LastName']

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

# Get current users, so we don't create duplicates
current_users = []

eusers = client.list_users()
for euser in eusers.get('Users', []):
    euname = euser['UserName']
    current_users.append(euname)

# Empty list to store responses
responses = {}

# Loop through the usernames we've created and create the 
# user account in AWS and add the users to the proper groups
print("Creating users...")
for user in new_users:
    # Check if user exists 
    if user in current_users:
        print("%r already exists") % user
    else:
        # If not, create the user
        response = client.create_user(
            UserName=user
        )
        # Save response
        responses.append(response)
        # Add user to group
        grp_rspnse = client.add_user_to_group(
            GroupName='NoBilling',
            UserName=user
        )

# all the code above works.
# want to add validation step (response code 200?)
# and add argument to take list of users to create
