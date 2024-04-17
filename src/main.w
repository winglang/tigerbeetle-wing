bring cloud;
bring sim;
bring util;
bring fs;
bring ui;
bring "./tigerbeetle.w" as tigerbeetle;

let instance = new tigerbeetle.TigerBeetle();

bring math;
let randomBigInt = inflight () => {
   return "{math.round(math.random() * 1000)}";
};

new cloud.Function(inflight () => {
   let accountId1 = randomBigInt();
   let accountId2 = randomBigInt();
   log("Creating two accounts (ids {accountId1} and {accountId2})...");
   let accountErrors = instance.createAccounts([
      {
         id: accountId1,
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
         id: accountId2,
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
}) as "CreateAccountsExample";

test "Create accounts and transfer" {
   let accountId1 = randomBigInt();
   let accountId2 = randomBigInt();
   log("Creating two accounts (ids {accountId1} and {accountId2})...");
   let accountErrors = instance.createAccounts([
      {
         id: accountId1,
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
         id: accountId2,
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

   let transferId = randomBigInt();
   log("Creating a transfer (id {transferId})...");
   let transferErrors = instance.createTransfers([
      {
         id: transferId,
         debit_account_id: accountId1,
         credit_account_id: accountId2,
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

   log("Looking up accounts...");
   let accounts = instance.lookupAccounts([accountId1, accountId2]);
   assert(accounts.length == 2);
   for account in accounts {
      if (account.id == accountId1) {
         assert(account.debits_posted == "10");
         assert(account.credits_posted == "0");
      } elif (account.id == accountId2) {
         assert(account.debits_posted == "0");
         assert(account.credits_posted == "10");
      } else {
         throw "Unexpected account: {Json.stringify(account, indent: 2)}";
      }
   }

   log("Ok");
}
