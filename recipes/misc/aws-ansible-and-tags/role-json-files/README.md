Role creation commands:

```bash
aws iam create-role --role-name tigerlinux-01-s3-ro-ec2-ro --assume-role-policy-document file://~/role-json-files/role-instance-basic.json
aws iam put-role-policy --role-name tigerlinux-01-s3-ro-ec2-ro --policy-name s3-ro-access --policy-document file://~/role-json-files/s3-list-role.json
aws iam put-role-policy --role-name tigerlinux-01-s3-ro-ec2-ro --policy-name ec2-ro-access --policy-document file://~/role-json-files/ec2-describe.json
aws iam create-instance-profile --instance-profile-name tigerlinux-01-s3-ro-ec2-ro-profile
aws iam add-role-to-instance-profile --instance-profile-name tigerlinux-01-s3-ro-ec2-ro-profile --role-name tigerlinux-01-s3-ro-ec2-ro
```
