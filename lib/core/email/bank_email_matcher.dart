/// Known transaction-alert sending domains for major Indian banks. Like
/// the SMS DLT sender check, this is a starting point — banks sometimes
/// send from several different subdomains.
const knownBankEmailDomains = [
  'hdfcbank.net',
  'hdfcbank.com',
  'icicibank.com',
  'sbi.co.in',
  'alerts.axisbank.com',
  'axisbank.com',
  'kotak.com',
  'pnbindia.in',
  'idfcfirstbank.com',
  'yesbank.in',
];

bool looksLikeBankEmail(String fromHeader) {
  final lower = fromHeader.toLowerCase();
  return knownBankEmailDomains.any(lower.contains);
}

/// The Gmail search that selects bank alerts: only mail *from* a known bank
/// domain, from [afterDate] (`YYYY/MM/DD`) onwards, containing a
/// debit/credit word. Filtering by sender in the query means other mail is
/// never downloaded, not merely discarded afterwards.
String bankEmailSearchQuery(String afterDate) =>
    'after:$afterDate from:(${knownBankEmailDomains.join(' OR ')}) (debited OR credited OR spent)';
