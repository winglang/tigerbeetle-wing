bring cloud;
bring sim;
bring util;
bring fs;
bring ui;

// EC2 Amazon Linux AMI: ami-0facbf2a36e11b9dd

// inflight class TigerBeetleClient {
//    new() {

//    }
// }

struct Account {
   id: str; // bigint
   debits_pending: str; // bigint
   debits_posted: str; // bigint
   credits_pending: str; // bigint
   credits_posted: str; // bigint
   user_data_128: str; // bigint
   user_data_64: str; // bigint
   user_data_32: num;
   reserved: num;
   ledger: num;
   code: num;
   flags: num;
   timestamp: str; // bigint
}
struct CreateAccountsError {
   index: num;
   result: num; // CreateAccountError;
}
struct Transfer {
   id: str; // bigint;
   debit_account_id: str; // bigint;
   credit_account_id: str; // bigint;
   amount: str; // bigint;
   pending_id: str; // bigint;
   user_data_128: str; // bigint;
   user_data_64: str; // bigint;
   user_data_32: num;
   timeout: num;
   ledger: num;
   code: num;
   flags: num;
   timestamp: str; // bigint;
}
struct CreateTransfersError {
   index: num;
   result: num; // CreateTransferError;
}
// struct AccountID {}
// struct TransferID {}
struct AccountFilter {
   account_id: str; // bigint;
   timestamp_min: str; // bigint;
   timestamp_max: str; // bigint;
   limit: num;
   flags: num;
}
struct AccountBalance {
   debits_pending: str; // bigint;
   debits_posted: str; // bigint;
   credits_pending: str; // bigint;
   credits_posted: str; // bigint;
   timestamp: str; // bigint;
}

inflight interface TigerBeetleClient {
   createAccounts(batch: Array<Account>): Array<CreateAccountsError>;
   createTransfers(batch: Array<Transfer>): Array<CreateTransfersError>;
   lookupAccounts(batch: Array<str>): Array<Account>;
   // lookupTransfers(batch: Array<str>): Array<Transfer>;
   // getAccountTransfers(filter: AccountFilter): Array<Transfer>;
   // getAccountBalances(filter: AccountFilter): Array<AccountBalance>;
   // destroy(): void;
}

struct TigerBeetleClientOptions {
   cluster_id: str; // bigint;
   concurrency_max: num;
   replica_addresses: Array<str>;
}

pub class TigerBeetle impl TigerBeetleClient {
   port: str;
   url: str;
   new() {
      let state = new sim.State();
      nodeof(state).hidden = true;

      let resolvePwdService = new cloud.Service(inflight () => {
         let pwd = util.shell("echo $(pwd)").trim();
         state.set("pwd", pwd);
      }) as "ResolvePwdService";
      nodeof(resolvePwdService).hidden = true;
      let pwd = state.token("pwd");

      let dataFilename = "{this.node.addr.substring(0, 8)}.tigerbeetle";

      let createDataService = new cloud.Service(inflight () => {
         if !fs.exists("{pwd}/data/{dataFilename}") {
            util.shell(
               "docker run -v {pwd}/data:/data ghcr.io/tigerbeetle/tigerbeetle format --cluster=0 --replica=0 --replica-count=1 /data/{dataFilename}",
            );
         }
      }) as "CreateDataService";
      nodeof(createDataService).hidden = true;

      let container = new sim.Container(
         name: "tigerbeetle",
         image: "ghcr.io/tigerbeetle/tigerbeetle",
         containerPort: 3000,
         volumes: [
            "{pwd}/data:/data",
         ],
         args: [
            "start",
            "--cache-grid=256MiB",
             "--addresses=0.0.0.0:3000",
             "/data/{dataFilename}",
         ],
      );
      container.node.addDependency(createDataService);
      nodeof(container).hidden = true;

      this.port = state.token("port");
      this.url = state.token("url");
      let resolveUrlService = new cloud.Service(inflight () => {
         state.set("port", container.hostPort);
         state.set("url", "http://127.0.0.1:{container.hostPort!}");
      }) as "ResolveUrlService";
      nodeof(resolveUrlService).hidden = true;

      new ui.Field(
         "Port",
         inflight () => {
            return this.port;
         },
      ) as "PortUI";
      new ui.Field(
         "URL",
         inflight () => {
            return this.url;
         },
      ) as "UrlUI";
      new ui.Field(
         "Data File",
         inflight () => {
            return "data/{dataFilename}";
         },
      ) as "DataFileUI";
   }

   extern "./tigerbeetle.inflight.ts" inflight static createClient(options: TigerBeetleClientOptions): TigerBeetleClient;

   inflight client: TigerBeetleClient;

   inflight new() {
      this.client = TigerBeetle.createClient(
         cluster_id: "0",
         concurrency_max: 100,
         replica_addresses: [
            this.port,
         ],
      );
   }

   pub inflight createAccounts(batch: Array<Account>): Array<CreateAccountsError> {
      return this.client.createAccounts(batch);
   }

   pub inflight createTransfers(batch: Array<Transfer>): Array<CreateTransfersError> {
      return this.client.createTransfers(batch);
   }

   pub inflight lookupAccounts(batch: Array<str>): Array<Account> {
      return this.client.lookupAccounts(batch);
   }
}
