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

class TigerBeetle impl TigerBeetleClient {
// class TigerBeetle {
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

      let isTest = util.tryEnv("WING_IS_TEST") == "true";
      let createDataService = new cloud.Service(inflight () => {
         if !isTest {
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

let tigerbeetle = new TigerBeetle();

new cloud.Function(inflight () => {
   log("Creating two accounts...");
   let accountErrors = tigerbeetle.createAccounts([
      {
         id: "1",
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
      {
         id: "2",
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
   for error in accountErrors {
      log("createAccounts error: {error.index} {error.result}");
   }
   assert(accountErrors.length == 0, "createAccounts failed");

   log("Creating a transfer...");
   let transferErrors = tigerbeetle.createTransfers([
      {
         id: "1",
         debit_account_id: "1",
         credit_account_id: "2",
         amount: "10",
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
   for error in transferErrors {
      log("Batch transfer at {error.index} failed to create: {error.result}");
   }
   assert(transferErrors.length == 0, "createTransfers failed");

   let accounts = tigerbeetle.lookupAccounts(["1", "2"]);
   assert(accounts.length == 2);
   for account in accounts {
      if (account.id == "1") {
         assert(account.debits_posted == "10");
         assert(account.credits_posted == "0");
      } elif (account.id == "2") {
         assert(account.debits_posted == "0");
         assert(account.credits_posted == "10");
      } else {
         throw "Unexpected account: {Json.stringify(account, indent: 2)}";
      }
   }

   log("ok");
});
