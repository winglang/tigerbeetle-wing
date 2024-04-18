bring cloud;
bring sim;
bring util;
bring fs;
bring ui;
bring "./tigerbeetle.w" as tigerbeetle;

let instance = new tigerbeetle.TigerBeetle();

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
