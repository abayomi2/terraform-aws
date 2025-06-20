# # # create an ec2 instance using boto3
# import boto3
# ec2 = boto3.resource('ec2')
# instance = ec2.create_instances(
# 	ImageId='ami-020cba7c55df1f615',  # Example AMI ID, replace with a valid one
# 	MinCount=1, MaxCount=1, # Create one instance
# 	InstanceType='t2.micro',  # Instance type
# 	KeyName='prod-kp'  # Replace with your key pair name
# )
# # Print the instance ID
# if instance:
# 	print("Instance created with ID:", instance[0].id)

# # create security group
# security_group = ec2.create_security_group(
# 	GroupName='my-security-group',
# 	Description='My security group for EC2 instance'
# )
# # Add inbound rule to allow SSH access
# security_group.authorize_ingress(
# 	CidrIp='0.0.0.0/0',
# 	IpProtocol='tcp',
# 	FromPort=22,
# 	ToPort=22
# )
# # Print the security group ID
# print("Security group created with ID:", security_group.id) 
# # Attach the security group to the instance
# instance[0].modify_attribute(Groups=[security_group.id])    
# # Print the instance public IP address
# instance[0].wait_until_running()    
# instance[0].reload()
# print("Instance public IP address:", instance[0].public_ip_address) 
# # Print the security group ID
# print("Security group ID:", security_group.id)  

# # Destroy the instance
# instance[0].terminate() 
# # Wait for the instance to be terminated
# instance[0].wait_until_terminated()
# # Print confirmation of termination
# print("Instance terminated with ID:", instance[0].id)   
# # Delete the security group
# security_group.delete()
# # Print confirmation of security group deletion
# print("Security group deleted with ID:", security_group.id)
# # Note: Ensure you have the necessary permissions and configurations set up in AWS to run this code.

# Delete all resources created by this script
import boto3

ec2 = boto3.resource('ec2')

# Locate the instance
instance_id = 'i-01bb66ab685cf1de9'  # Replace with your actual instance ID
instance = ec2.Instance(instance_id)

# Terminate the instance
instance.terminate()
instance.wait_until_terminated()
print(f"Instance {instance_id} has been terminated.")

# Locate the security group
security_group_id = 'sg-0dd90905a88989c70'  # Replace with your actual security group ID
security_group = ec2.SecurityGroup(security_group_id)

# Delete the security group
security_group.delete()
print(f"Security group {security_group_id} has been deleted.")