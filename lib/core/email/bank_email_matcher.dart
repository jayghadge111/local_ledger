/// Which email senders count as a bank.
///
/// Since RBI's 31 Oct 2025 deadline, Indian banks are moving to the
/// `.bank.in` domain, which the registrar (IDRBT) issues to banks only —
/// so *any* `@something.bank.in` sender is treated as a bank, covering
/// every bank that has migrated or will (hdfc.bank.in, icici.bank.in,
/// sbi.bank.in, axis.bank.in, pnb.bank.in, bankofbaroda.bank.in,
/// canarabank.bank.in, unionbankofindia.bank.in, kotak.bank.in, …).
///
/// Many alert systems still send from the older domains, so those are
/// listed too. Confirmed from bank/customer-care sources: hdfcbank.net
/// (InstaAlerts: alerts@hdfcbank.net), alerts.sbi.co.in
/// (cbssbi.info@alerts.sbi.co.in), axis.bank.in (alerts@axis.bank.in). The
/// rest are the banks' long-standing primary domains. A domain missing
/// here can be added without touching any other code.
const bankInSuffix = 'bank.in';

const knownBankEmailDomains = [
  // Public sector banks.
  'sbi.co.in',
  'alerts.sbi.co.in',
  'pnb.co.in',
  'pnbindia.in',
  'bankofbaroda.in',
  'bankofbaroda.co.in',
  'canarabank.com',
  'unionbankofindia.co.in',
  'bankofindia.co.in',
  'centralbank.co.in',
  'centralbankofindia.co.in',
  'cboi.in',
  'iob.in',
  'iobnet.co.in',
  'ucobank.com',
  'ucobank.co.in',
  'mahabank.co.in',
  'bankofmaharashtra.in',
  'psb.co.in',
  'psbindia.com',
  'punjabandsindbank.co.in',
  'indianbank.co.in',
  'indianbank.in',
  'idbi.co.in', 'idbibank.in',

  // Private banks.
  'hdfcbank.net', 'hdfcbank.com', 'icicibank.com', 'axisbank.com', 'kotak.com',
  'idfcfirstbank.com',
  'yesbank.in',
  'indusind.com',
  'federalbank.co.in',
  'rblbank.com',
  'kvb.co.in',
  'kvbmail.com',
  'cityunionbank.com',
  'cityunionbank.in',
  'southindianbank.com',
  'ktkbank.com',
  'tmb.in',
  'tmbank.in',
  'dcbbank.com',
  'bandhanbank.com',
  'dhanbank.com',
  'dhanbank.co.in',
  'jkbank.com',
  'jkbmail.com',
  'nainitalbank.co.in',
  'csb.co.in',

  // Small finance banks.
  'aubank.in',
  'equitasbank.com',
  'equitas.in',
  'ujjivan.com',
  'ujjivansfb.in',
  'janabank.com',
  'esafbank.com',
  'utkarsh.bank',
  'suryodaybank.com',
  'fincarebank.com',
  'capitalbank.co.in',
  'sbmbank.co.in',

  // Foreign banks in India and card issuers.
  'sc.com',
  'hsbc.co.in',
  'citibank.com',
  'citibank.co.in',
  'citi.com',
  'aexp.com',
  'americanexpress.com', 'dbs.com', 'sbicard.com', 'bobcard.co.in',

  // Payments banks.
  'paytmbank.com', 'airtelbank.com', 'ippbonline.com', 'finobank.com',

  // Urban co-operative banks. Most have moved to .bank.in (Jalgaon Janata
  // jjsbl.bank.in, Jalgaon Peoples jpc.bank.in, Saraswat, Cosmos, TJSB,
  // Abhyudaya, Kalupur, Mehsana…), which is matched above; these are their
  // older domains. Any co-operative bank missing here can be added in the app.
  'jjsbl.com',
  'jjsbl.co.in',
  'jpcbank.com',
  'saraswatbank.com',
  'cosmosbank.com',
  'svcbank.com',
  'nkgsb-bank.com',
  'apnabank.co.in',
  'dnsb.co.in',
  'mucbank.com',
  'rnsbindia.com', 'amcbank.in',
];

final _senderDomain = RegExp(r'@([a-z0-9.\-]+)', caseSensitive: false);

/// The domain of the address in a `From` header, lowercased — taken from the
/// address itself, never the display name, which anyone can set to anything.
String? senderDomain(String fromHeader) {
  final matches = _senderDomain.allMatches(fromHeader);
  return matches.isEmpty ? null : matches.last.group(1)!.toLowerCase();
}

/// [extraDomains] are sender domains the user added themselves in the app —
/// the escape hatch for any bank this list doesn't know.
bool looksLikeBankEmail(
  String fromHeader, {
  List<String> extraDomains = const [],
}) {
  final domain = senderDomain(fromHeader);
  if (domain == null) return false;
  if (domain == bankInSuffix || domain.endsWith('.$bankInSuffix')) return true;
  return [
    ...knownBankEmailDomains,
    ...extraDomains,
  ].any((d) => domain == d || domain.endsWith('.$d'));
}

/// Normalises what a user typed ("Alerts@MyBank.co.in ", "@mybank.co.in",
/// "https://mybank.co.in/x") to a bare domain, or null if it isn't one.
String? normalizeSenderDomain(String input) {
  var text = input.trim().toLowerCase();
  if (text.contains('@')) text = text.split('@').last;
  text = text.replaceFirst(RegExp(r'^[a-z]+://'), '').split('/').first.trim();
  return RegExp(r'^[a-z0-9\-]+(\.[a-z0-9\-]+)+$').hasMatch(text) ? text : null;
}

/// The Gmail search that selects bank alerts: only mail *from* a bank
/// domain, from [afterDate] (`YYYY/MM/DD`) onwards, containing a
/// debit/credit word. Filtering by sender in the query means other mail is
/// never downloaded. Gmail's `from:` matches by substring, so it can let a
/// few look-alikes through; [looksLikeBankEmail] is the exact check applied
/// to everything fetched.
String bankEmailSearchQuery(
  String afterDate, {
  List<String> extraDomains = const [],
}) =>
    'after:$afterDate from:($bankInSuffix OR ${[...knownBankEmailDomains, ...extraDomains].join(' OR ')}) '
    '(debited OR credited OR spent)';
