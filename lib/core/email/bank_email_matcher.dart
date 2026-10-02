/// Known transaction-alert sending domains for major Indian banks. Like
/// the SMS DLT sender check, this is a starting point — banks sometimes
/// send from several different subdomains.
const _knownBankEmailDomains = [
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
  return _knownBankEmailDomains.any(lower.contains);
}
