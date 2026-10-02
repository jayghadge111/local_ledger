import 'bank_sms_parser.dart';

const _bankNamePrefixes = <String, String>{
  'HDFC': 'HDFC Bank',
  'ICICI': 'ICICI Bank',
  'ICIBNK': 'ICICI Bank',
  'SBMIND': 'SBM Bank India',
  'SBI': 'SBI',
  'AXIS': 'Axis Bank',
  'KOTAK': 'Kotak Bank',
  'KBANK': 'Kotak Bank',
  'SCBANK': 'Standard Chartered',
  'EQUTAS': 'Equitas SFB',
  'EQBANK': 'Equitas SFB',
  'YESB': 'Yes Bank',
  'IDFC': 'IDFC First Bank',
  'PNB': 'PNB',
  'BOB': 'Bank of Baroda',
  'BOI': 'Bank of India',
  'CANBNK': 'Canara Bank',
  'UNIONB': 'Union Bank',
  'INDUSB': 'IndusInd Bank',
  'FEDBNK': 'Federal Bank',
  'RBL': 'RBL Bank',
  'JJSBNK': 'Jalgaon Janata Sahakari Bank',
  'JPCBNK': 'Jalgaon Peoples Co-op Bank',
  'PAYTMB': 'Paytm Payments Bank',
};

/// A readable bank name for an SMS sender ID (`VM-HDFCBK-S` -> "HDFC Bank")
/// or an email address (`alerts@hdfcbank.net`), falling back to the raw code.
String bankDisplayName(String sender) {
  if (sender.contains('@')) {
    final domain = sender.split('@').last.toUpperCase();
    for (final segment in domain.split('.')) {
      for (final e in _bankNamePrefixes.entries) {
        if (segment.startsWith(e.key)) return e.value;
      }
    }
    return domain;
  }
  final code = bankCodeOf(sender);
  for (final e in _bankNamePrefixes.entries) {
    if (code.startsWith(e.key)) return e.value;
  }
  return code;
}
