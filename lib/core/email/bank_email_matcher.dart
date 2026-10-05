import '../rules/parser_rules.dart';

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
String get bankInSuffix => ParserRules.current.emailSuffix;

/// Bank sender domains known to the app (from the rules in force).
List<String> get knownBankEmailDomains => ParserRules.current.emailDomains;

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
/// debit/credit word — or the wording of an auto-debit notice (mandate set-up,
/// pre-debit advice, EMI or card bill), which the app keeps as upcoming debits. Filtering by sender in the query means other mail is
/// never downloaded. Gmail's `from:` matches by substring, so it can let a
/// few look-alikes through; [looksLikeBankEmail] is the exact check applied
/// to everything fetched.
String bankEmailSearchQuery(
  String afterDate, {
  List<String> extraDomains = const [],
}) =>
    'after:$afterDate from:($bankInSuffix OR ${[...knownBankEmailDomains, ...extraDomains].join(' OR ')}) '
    '(debited OR credited OR spent OR mandate OR UMRN OR "auto-debit" OR '
    '"auto debit" OR "amount due" OR "EMI due")';
