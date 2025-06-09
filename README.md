# pre-assessment

# Part I
1. Compose the Dockerfile with multistages and alpine image to ensure minimal image size. Also make sure the container is run with non-root user to ensure security best practices. Refer to the [Dockerfile](./Dockerfile)
2. Run commands with [makefile](./Makefile) for ease with debugging and running
3. In the golang program provided, I found out the server is specifically bound to 127.0.0.1. This also fails the container with port-forwarding too. The code is modified to listen to all traffic by removing the specific IP address. Refer to [main.go](./main.go)
4. Test and run container locally and verify the connectivity by running `curl http://localhost:8080`

# Part 2
## Assumptions:
- For demonstration purpose, VM A and VM B are AWS EC2 instances within the same VPC using the same account. Multi AZ are not considered for this assessment.
- Performance is not a consideration in this project and hence t2.micro EC2 type is selected for demo purpose.
- VM A sits in public subnet while VM B sits in private subnet. VM a will be able to connect to VM B web servers via private IP address.
- Assign static IP address to VM B for the simplicity purpose. However, in production, better use DNS-based strategies for VM B to ensure scalabiilty and IP management. 
- Terraform is leveraged to automate and manage the infrastructure provisions. However, versioning and regular backup of Terraform statefile is not enabled.
- The infrastructure auotmation is simplified for demonstration purposes. There is only one single environment (Dev) for this project.
- Currently use the github repo as the image repository. But for security consideraiton, in production, the EC2 instance within the private subnet could use ECR VPC endpoints (AWS privatelink) to avoid internet exposure.


## Pre-Requisites
- In the bootstrap folder, run `terraform apply` to create the statefile s3 bucket.

## Provision
```bash
terraform fmt
terraform validate
t plan -out plan.tfplan -var-file=dev.tfvars
t apply -auto-approve plan.tfplan
```

## output
curl command from VM A
```bash
[ec2-user@ip-10-0-1-127 (VMA) ~]$ curl -vvv http://10.0.2.77:8080
*   Trying 10.0.2.77:8080...
* Connected to 10.0.2.77 (10.0.2.77) port 8080
> GET / HTTP/1.1
> Host: 10.0.2.77:8080
> User-Agent: curl/8.3.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Date: Mon, 09 Jun 2025 07:23:42 GMT
< Content-Length: 14
< Content-Type: text/plain; charset=utf-8
< 
Hello, World!
* Connection #0 to host 10.0.2.77 left intact
```

Container logs from curl command:
```bash
[ec2-user@ip-10-0-2-77 ~]$ sudo docker logs web_server -f
2025/06/09 07:23:03 Server listening on http://:8080
```

# Part 3
