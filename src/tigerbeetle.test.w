bring math;
bring expect;
bring "./tigerbeetle.w" as tigerbeetle;

let instance = new tigerbeetle.TigerBeetle(
   clusterId: "1",
);

test "Create accounts and transfer" {
   let randomBigInt = inflight () => {
      return "{math.round(math.random() * 1000)}";
   };
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
   expect.equal(accountErrors.length, 0);

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
   expect.equal(transferErrors.length, 0);

   log("Looking up accounts...");
   let accounts = instance.lookupAccounts([accountId1, accountId2]);
   expect.equal(accounts.length, 2);
   for account in accounts {
      if (account.id == accountId1) {
         expect.equal(account.debits_posted, "10");
         expect.equal(account.credits_posted, "0");
      } elif (account.id == accountId2) {
         expect.equal(account.debits_posted, "0");
         expect.equal(account.credits_posted, "10");
      } else {
         throw "Unexpected account: {Json.stringify(account, indent: 2)}";
      }
   }
}
