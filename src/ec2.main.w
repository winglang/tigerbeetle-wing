bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;

// let iamInstanceProfile = "SSM"; // Role name used to allow SSM to manage the instance.

let ami = "ami-0e8a62bd8368b0881"; // Amazon Linux 2 LTS Arm64 Kernel 5.10 AMI 2.0.20240329.0 arm64 HVM gp2.
let instanceType = "t4g.medium"; // Minimum size that worked for the AMI.
let userData = "#!/bin/bash
yum update -y
yum install git unzip -y
mkdir /app
cd /app
git clone https://github.com/coilhq/tigerbeetle.git tigerbeetle-src --no-depth
./tigerbeetle-src/bootstrap.sh
./tigerbeetle-src/tigerbeetle format --cluster=0 --replica=0 --replica-count=1 0_0.tigerbeetle
./tigerbeetle-src/tigerbeetle start --addresses=0.0.0.0:3000 0_0.tigerbeetle
";

let vpc = new aws.vpc.Vpc(
   cidrBlock: "10.0.0.0/16",
   enableDnsSupport: true,
   enableDnsHostnames: true,
);

let publicSubnet = new aws.subnet.Subnet(
   vpcId: vpc.id,
   cidrBlock: "10.0.0.0/24", // 10.0.0.0 - 10.0.0.255
   availabilityZone: "eu-west-3a",
) as "PublicSubnet";

let privateSubnet = new aws.subnet.Subnet(
   vpcId: vpc.id,
   cidrBlock: "10.0.4.0/22", // 10.0.4.0 - 10.0.7.255
   availabilityZone: "eu-west-3a",
) as "PrivateSubnet";

let internetGateway = new aws.internetGateway.InternetGateway(
   vpcId: vpc.id,
);

let publicIp = new aws.eip.Eip({
   domain: "vpc",
});

let natGateway = new aws.natGateway.NatGateway(
   allocationId: publicIp.id,
   subnetId: publicSubnet.id,
);

let publicRouteTable = new aws.routeTable.RouteTable(
   vpcId: vpc.id,
   route: [
      {
         // This will route all traffic to the internet gateway
         cidrBlock: "0.0.0.0/0",
         gatewayId: internetGateway.id,
      },
   ],
) as "PublicRouteTable";

let privateRouteTable = new aws.routeTable.RouteTable(
   vpcId: vpc.id,
   route: [
     {
       // This will route all traffic to the NAT gateway
       cidrBlock: "0.0.0.0/0",
       natGatewayId: natGateway.id,
     },
   ],
) as "PrivateRouteTable";

new aws.routeTableAssociation.RouteTableAssociation(
   subnetId: publicSubnet.id,
   routeTableId: publicRouteTable.id,
) as "PublicRouteTableAssociation";

new aws.routeTableAssociation.RouteTableAssociation(
   subnetId: privateSubnet.id,
   routeTableId: privateRouteTable.id,
) as "PrivateRouteTableAssociation";

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
   ami: ami,
   instanceType: instanceType,
   userData: userData,
   associatePublicIpAddress: true,
   // subnetId: privateSubnet.id,
   subnetId: publicSubnet.id, // Just for demo purposes.
   vpcSecurityGroupIds: [securityGroup.id],
   // rootBlockDevice: {
   //    volumeType: "gp3",
   //    volumeSize: 16, // Specifies the volume size in GB
   //    deleteOnTermination: true,
   // },
);

new cdktf.TerraformOutput(
   value: instance.publicIp,
) as "InstancePublicIP";

// let bastion = new aws.instance.Instance(
//    // ami: "ami-0e8a62bd8368b0881",
//    ami: "ami-00232bbfe70330a10", // Canonical, Ubuntu, 22.04 LTS, arm64 jammy image build on 2024-03-01
//    instanceType: "t4g.nano",
//    subnetId: privateSubnet.id,
//    vpcSecurityGroupIds: [securityGroup.id],
//    userData: "#!/bin/bash
// apt update
// apt install curl -y
//    ",
//    iamInstanceProfile: iamInstanceProfile,
// ) as "Bastion";

// new cdktf.TerraformOutput(
//    value: bastion.arn,
// ) as "BastionARN";
