pub struct Account {
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

pub struct CreateAccountsError {
   index: num;
   result: num; // CreateAccountError;
}

pub struct Transfer {
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

pub struct CreateTransfersError {
   index: num;
   result: num; // CreateTransferError;
}

// struct AccountID {}

// struct TransferID {}

pub struct AccountFilter {
   account_id: str; // bigint;
   timestamp_min: str; // bigint;
   timestamp_max: str; // bigint;
   limit: num;
   flags: num;
}

pub struct AccountBalance {
   debits_pending: str; // bigint;
   debits_posted: str; // bigint;
   credits_pending: str; // bigint;
   credits_posted: str; // bigint;
   timestamp: str; // bigint;
}

pub inflight interface TigerBeetleClient {
   createAccounts(batch: Array<Account>): Array<CreateAccountsError>;
   createTransfers(batch: Array<Transfer>): Array<CreateTransfersError>;
   lookupAccounts(batch: Array<str>): Array<Account>;
   // lookupTransfers(batch: Array<str>): Array<Transfer>;
   // getAccountTransfers(filter: AccountFilter): Array<Transfer>;
   // getAccountBalances(filter: AccountFilter): Array<AccountBalance>;
   // destroy(): void;
}

pub struct TigerBeetleClientOptions {
   cluster_id: str; // bigint;
   concurrency_max: num?;
   replica_addresses: Array<str>;
}

pub struct TigerBeetleProps {
   clusterId: str; // bigint;
   vpcId: str?;
   subnetId: str?;
}
