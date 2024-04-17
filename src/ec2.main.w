bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;

let userData = "#!/bin/bash
sudo apt update
sudo apt install -y build-essential cmake git
git clone https://github.com/coilhq/tigerbeetle.git tigerbeetle-src
./tigerbeetle-src/bootstrap.sh

./tigerbeetle-src/tigerbeetle format --cluster=0 --replica=0 --replica-count=1 0_0.tigerbeetle

./tigerbeetle-src/tigerbeetle start --addresses=3000 0_0.tigerbeetle
";

let vpc = new aws.vpc.Vpc(
   cidrBlock: "10.0.0.0/16",
   enableDnsSupport: true,
   enableDnsHostnames: true,
);

let subnet = new aws.subnet.Subnet(
   vpcId: vpc.id,
   cidrBlock: "10.0.1.0/24",
   mapPublicIpOnLaunch: true,
);

// let internetGateway = new aws.internetGateway.InternetGateway(
//    vpcId: vpc.id,
// );

// let routeTable = new aws.routeTable.RouteTable(
//    vpcId: vpc.id,
// );

// new aws.routeTableAssociation.RouteTableAssociation(
//    subnetId: subnet.id,
//    routeTableId: routeTable.id,
// );

// routeTable.putRoute({
//    cidrBlock: "0.0.0.0/0",
//    gatewayId: internetGateway.id,
// });

let securityGroup = new aws.securityGroup.SecurityGroup(
   vpcId: vpc.id,
   ingress: [
     {
       fromPort: 3000,
       toPort: 3000,
       protocol: "tcp",
       cidrBlocks: ["0.0.0.0/0"],
     },
   ],
   egress: [
     {
       fromPort: 0,
       toPort: 0,
       protocol: "-1", // Allow all outbound traffic
       cidrBlocks: ["0.0.0.0/0"],
     },
   ],
);

let instance = new aws.instance.Instance(
   ami: "ami-0facbf2a36e11b9dd", // EC2 Amazon Linux AMI
   instanceType: "t2.nano",
   userData: userData,
   associatePublicIpAddress: true,
   subnetId: subnet.id,
   vpcSecurityGroupIds: [securityGroup.id],
);

new cdktf.TerraformOutput(
   value: instance.publicIp,
) as "InstancePublicIP";
