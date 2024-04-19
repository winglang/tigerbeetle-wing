bring cloud;
bring sim;
bring util;
bring fs;
bring ui;
bring "./tigerbeetle.w" as tigerbeetle;

let var subnetId: str? = nil;
let var vpcSecurityGroupIds: Array<str>? = nil;
if util.env("WING_TARGET") == "tf-aws" {
   bring "@cdktf/provider-aws" as aws;

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

   subnetId = publicSubnet.id;
   vpcSecurityGroupIds = [securityGroup.id];
}

let instance = new tigerbeetle.TigerBeetle(
   clusterId: "0",
   associatePublicIpAddress: true,
   subnetId: subnetId,
   vpcSecurityGroupIds: vpcSecurityGroupIds,
);

new cloud.Function(inflight (event) => {
   assert(event? && event != "");
   let accountId: str = unsafeCast(event);

   log("Creating account {accountId}...");
   let accountErrors = instance.createAccounts([
      {
         id: accountId,
         debits_pending: "0",
         debits_posted: "0",
         credits_pending: "0",
         credits_posted: "0",
         user_data_128: "0",
         user_data_64: "0",
         user_data_32: 0,
         reserved: 0,
         ledger: 1,
         code: 1,
         flags: 0,
         timestamp: "0",
      },
   ]);
   return unsafeCast(accountErrors);
}) as "CreateAccount";

new cloud.Function(inflight (event) => {
   assert(event? && event != "");
   let accountId: str = unsafeCast(event);

   log("Looking up account {accountId}...");
   let accounts = instance.lookupAccounts([accountId]);
   return unsafeCast(accounts);
}) as "LookupAccount";

new cloud.Function(inflight (event) => {
   assert(event? && event != "");
   let parts = event?.split(",")!;
   assert(parts.length == 4);
   let transferId: str = parts.at(0);
   let debitAccountId: str = parts.at(1);
   let creditAccountId: str = parts.at(2);
   let amount: str = parts.at(3);

   log("Creating a transfer (id {transferId}, debit account id {debitAccountId}, credit account id {creditAccountId}, amount {amount})...");
   let transferErrors = instance.createTransfers([
      {
         id: transferId,
         debit_account_id: debitAccountId,
         credit_account_id: creditAccountId,
         amount: amount,
         pending_id: "0",
         user_data_128: "0",
         user_data_64: "0",
         user_data_32: 0,
         timeout: 0,
         ledger: 1,
         code: 1,
         flags: 0,
         timestamp: "0",
      },
   ]);
   return unsafeCast(transferErrors);
}) as "CreateTransfer";
