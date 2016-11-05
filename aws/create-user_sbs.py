#!/usr/bin/python
import os
import boto3
import pandas as pd
import argparse

__author__ = 'nightcrawler'

client = boto3.client('iam')

# Define arguments
parser = argparse.ArgumentParser(description='Create AWS Users from input file')
parser.add_argument('-i','--input-file',help='input file',required=True)
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
user_names = []

# Loop through the rows in the data frame
# First character of the field labeled 'FirstName' plus
# the field labeld 'LastName' equals the user_name
# Then add to our empty list above
for index, row in csv.iterrows():
    first_init = row['FirstName'][:1]
    last_name = row['LastName']
    user_name = first_init.lower() + last_name.lower()
    user_names.append(user_name)

# Empty list to store responses
responses = {}

# Loop through the usernames we've created and create the 
# user account in AWS and add the users to the proper groups
print("Creating users...")
for user in user_names:
    #print(user)
    response = client.create_user(
            UserName=user
    )
    responses.append(response)
    grp_rspnse = client.add_user_to_group(
            GroupName='NoBilling',
            UserName=user
    )

print("Performing validation...")
# Loop through responses, validate status codes
