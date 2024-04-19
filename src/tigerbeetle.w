bring cloud;
bring util;
bring fs;
bring ui;
bring "./tigerbeetle.types.w" as types;
bring "./tigerbeetle.sim.w" as sim;

pub class TigerBeetle impl types.TigerBeetleClient {
   pub port: str;
   pub address: str;
   pub clusterId: str;
   pub replica: str;
   pub replicaCount: str;
   pub dataFilename: str;
   client: types.TigerBeetleClient;
   new() {
      let implementation = new sim.TigerBeetleSim();
      nodeof(implementation).hidden = true;
      this.port = implementation.port;
      this.address = implementation.address;
      this.clusterId = implementation.clusterId;
      this.replica = implementation.replica;
      this.replicaCount = implementation.replicaCount;
      this.dataFilename = implementation.dataFilename;
      this.client = implementation;

      new ui.Field(
         "Address",
         inflight () => {
            return this.address;
         },
      ) as "AddressField";

      new ui.Field(
         "Cluster ID",
         inflight () => {
            return this.clusterId;
         },
      ) as "ClusterField";

      new ui.Field(
         "Replica",
         inflight () => {
            return this.replica;
         },
      ) as "ReplicaField";

      new ui.Field(
         "Replica Count",
         inflight () => {
            return this.replicaCount;
         },
      ) as "ReplicaCountField";

      new ui.Field(
         "Data File",
         inflight () => {
            return "data/{this.dataFilename}";
         },
      ) as "DataFileField";
   }

   pub inflight createAccounts(batch: Array<types.Account>): Array<types.CreateAccountsError> {
      return this.client.createAccounts(batch);
   }

   pub inflight createTransfers(batch: Array<types.Transfer>): Array<types.CreateTransfersError> {
      return this.client.createTransfers(batch);
   }

   pub inflight lookupAccounts(batch: Array<str>): Array<types.Account> {
      return this.client.lookupAccounts(batch);
   }
}
