import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

/// How a recognised merchant looks in the transaction list: its brand colour
/// and either its logo glyph or, where no logo is bundled, an initial.
class MerchantBadgeData {
  const MerchantBadgeData(
    this.initial,
    this.color, {
    this.icon,
    this.name,
    this.asset,
    this.wordmark = false,
  });

  /// Bundled logo image (see `assets/logos/`), when there is one.
  final String? asset;

  /// The image is a wide logo rather than a square app icon, so it is shown
  /// whole on white instead of filling the circle.
  final bool wordmark;

  final String initial;
  final Color color;
  final IconData? icon;

  /// The brand's display name ("HDFC Bank"), for tooltips and accessibility.
  final String? name;

  /// Text/glyph colour that stays readable on [color].
  Color get foreground =>
      color.computeLuminance() > 0.6 ? const Color(0xFF111111) : Colors.white;
}

class MerchantBrand {
  const MerchantBrand(
    this.name,
    this.keywords,
    this.icon,
    this.color,
    this.initial,
  );

  final String name;
  final List<String> keywords;
  final IconData? icon;
  final Color color;
  final String initial;
}

/// Brands recognised by name, grouped by the app's own categories. The list
/// is ordered most-specific first (Swiggy Instamart before Swiggy, Amazon Pay
/// and Prime Video before Amazon), because the first match wins.
///
/// Logos come from the bundled Simple Icons set (CC0 artwork; the marks
/// themselves remain their owners' trademarks), drawn on-device — nothing is
/// fetched from the network, which would defeat the app's local-only design.
/// Brands that set doesn't carry get their brand colour and initial instead.
const _brands = <MerchantBrand>[
  MerchantBrand(
    'Swiggy Instamart',
    ['instamart', 'swiggy instamart'],
    SimpleIcons.swiggy,
    SimpleIconColors.swiggy,
    'S',
  ),
  MerchantBrand(
    'Swiggy',
    ['swiggy'],
    SimpleIcons.swiggy,
    SimpleIconColors.swiggy,
    'S',
  ),
  MerchantBrand(
    'Zomato',
    ['zomato', 'blinkit hyperpure'],
    SimpleIcons.zomato,
    SimpleIconColors.zomato,
    'Z',
  ),
  MerchantBrand(
    'EatSure',
    ['eatsure', 'faasos', 'behrouz biryani', 'oven story'],
    null,
    Color(0xFFE5173F),
    'E',
  ),
  MerchantBrand(
    'Domino\'s',
    ['dominos', 'domino\'s', 'domino'],
    null,
    Color(0xFF006491),
    'D',
  ),
  MerchantBrand(
    'Pizza Hut',
    ['pizza hut', 'pizzahut'],
    null,
    Color(0xFFEE3124),
    'P',
  ),
  MerchantBrand('KFC', ['kfc'], SimpleIcons.kfc, SimpleIconColors.kfc, 'K'),
  MerchantBrand(
    'McDonald\'s',
    ['mcdonalds', 'mcdonald\'s', 'mcdonald'],
    SimpleIcons.mcdonalds,
    SimpleIconColors.mcdonalds,
    'M',
  ),
  MerchantBrand(
    'Burger King',
    ['burger king'],
    SimpleIcons.burgerking,
    SimpleIconColors.burgerking,
    'B',
  ),
  MerchantBrand('Subway', ['subway'], null, Color(0xFF009743), 'S'),
  MerchantBrand(
    'Starbucks',
    ['starbucks'],
    SimpleIcons.starbucks,
    SimpleIconColors.starbucks,
    'S',
  ),
  MerchantBrand(
    'Cafe Coffee Day',
    ['cafe coffee day', 'ccd'],
    null,
    Color(0xFF8C1D2F),
    'C',
  ),
  MerchantBrand('Chaayos', ['chaayos'], null, Color(0xFF1E7B4B), 'C'),
  MerchantBrand(
    'Haldiram\'s',
    ['haldiram', 'haldiram\'s'],
    null,
    Color(0xFFE31E24),
    'H',
  ),
  MerchantBrand(
    'Barista',
    ['barista', 'third wave coffee', 'blue tokai', 'theobroma'],
    null,
    Color(0xFF6F4E37),
    'B',
  ),
  MerchantBrand('Zepto', ['zepto'], null, Color(0xFF8025FB), 'Z'),
  MerchantBrand('Blinkit', ['blinkit'], null, Color(0xFFF8CB46), 'B'),
  MerchantBrand(
    'BigBasket',
    ['bigbasket'],
    SimpleIcons.bigbasket,
    SimpleIconColors.bigbasket,
    'B',
  ),
  MerchantBrand(
    'Dunzo',
    ['dunzo'],
    SimpleIcons.dunzo,
    SimpleIconColors.dunzo,
    'D',
  ),
  MerchantBrand('JioMart', ['jiomart'], null, Color(0xFF0078AD), 'J'),
  MerchantBrand(
    'DMart',
    ['dmart', 'avenue supermarts'],
    null,
    Color(0xFF2E8B3E),
    'D',
  ),
  MerchantBrand(
    'Reliance Fresh',
    ['reliance fresh', 'reliance smart', 'more retail', 'nature basket'],
    null,
    Color(0xFFE42529),
    'R',
  ),
  MerchantBrand('Uber', ['uber'], SimpleIcons.uber, SimpleIconColors.uber, 'U'),
  MerchantBrand(
    'Ola',
    ['ola', 'ola cabs', 'ola electric'],
    null,
    Color(0xFF1C1C1C),
    'O',
  ),
  MerchantBrand('Rapido', ['rapido'], null, Color(0xFFFFC82C), 'R'),
  MerchantBrand('redBus', ['redbus'], null, Color(0xFFD63941), 'r'),
  MerchantBrand('IRCTC', ['irctc'], null, Color(0xFF1B4F9C), 'I'),
  MerchantBrand(
    'MakeMyTrip',
    ['makemytrip', 'mmt'],
    null,
    Color(0xFFEB2226),
    'M',
  ),
  MerchantBrand('Goibibo', ['goibibo'], null, Color(0xFFEC6E2B), 'G'),
  MerchantBrand('ixigo', ['ixigo'], null, Color(0xFFE8573F), 'i'),
  MerchantBrand('Cleartrip', ['cleartrip'], null, Color(0xFFFF4F17), 'C'),
  MerchantBrand(
    'IndiGo',
    ['indigo', '6e'],
    SimpleIcons.indigo,
    SimpleIconColors.indigo,
    'I',
  ),
  MerchantBrand(
    'Air India',
    ['air india', 'airindia'],
    SimpleIcons.airindia,
    SimpleIconColors.airindia,
    'A',
  ),
  MerchantBrand('Vistara', ['vistara'], null, Color(0xFF4B2A5E), 'V'),
  MerchantBrand('SpiceJet', ['spicejet'], null, Color(0xFFE41F26), 'S'),
  MerchantBrand('Akasa Air', ['akasa'], null, Color(0xFFFF6A00), 'A'),
  MerchantBrand('FASTag', ['fastag'], null, Color(0xFF1F6FB5), 'F'),
  MerchantBrand(
    'Airbnb',
    ['airbnb'],
    SimpleIcons.airbnb,
    SimpleIconColors.airbnb,
    'A',
  ),
  MerchantBrand('OYO', ['oyo'], SimpleIcons.oyo, SimpleIconColors.oyo, 'O'),
  MerchantBrand('Amazon Pay', ['amazon pay'], null, Color(0xFFFF9900), 'a'),
  MerchantBrand(
    'Prime Video',
    ['prime video', 'primevideo', 'amazon prime'],
    null,
    Color(0xFF00A8E1),
    'P',
  ),
  MerchantBrand('Amazon', ['amazon', 'amzn'], null, Color(0xFFFF9900), 'a'),
  MerchantBrand('Flipkart', ['flipkart'], null, Color(0xFF2874F0), 'F'),
  MerchantBrand('Myntra', ['myntra'], null, Color(0xFFFF3F6C), 'M'),
  MerchantBrand('Ajio', ['ajio'], null, Color(0xFF2C4152), 'A'),
  MerchantBrand('Nykaa', ['nykaa'], null, Color(0xFFFC2779), 'N'),
  MerchantBrand('Meesho', ['meesho'], null, Color(0xFFF43397), 'M'),
  MerchantBrand(
    'Tata CLiQ',
    ['tata cliq', 'tatacliq'],
    null,
    Color(0xFFDA1C5C),
    'T',
  ),
  MerchantBrand('Croma', ['croma'], null, Color(0xFF00A99D), 'C'),
  MerchantBrand('Lenskart', ['lenskart'], null, Color(0xFF00BAC6), 'L'),
  MerchantBrand('FirstCry', ['firstcry'], null, Color(0xFFF9A01B), 'F'),
  MerchantBrand('IKEA', ['ikea'], SimpleIcons.ikea, SimpleIconColors.ikea, 'I'),
  MerchantBrand('Nike', ['nike'], SimpleIcons.nike, SimpleIconColors.nike, 'N'),
  MerchantBrand(
    'Adidas',
    ['adidas'],
    SimpleIcons.adidas,
    SimpleIconColors.adidas,
    'A',
  ),
  MerchantBrand('Puma', ['puma'], SimpleIcons.puma, SimpleIconColors.puma, 'P'),
  MerchantBrand('Decathlon', ['decathlon'], null, Color(0xFF0082C3), 'D'),
  MerchantBrand(
    'Apple Music',
    ['apple music'],
    SimpleIcons.applemusic,
    SimpleIconColors.applemusic,
    'A',
  ),
  MerchantBrand(
    'Apple',
    ['apple', 'itunes', 'icloud'],
    SimpleIcons.apple,
    SimpleIconColors.apple,
    'A',
  ),
  MerchantBrand(
    'Google Play',
    ['google play', 'googleplay'],
    SimpleIcons.googleplay,
    SimpleIconColors.googleplay,
    'G',
  ),
  MerchantBrand(
    'Netflix',
    ['netflix'],
    SimpleIcons.netflix,
    SimpleIconColors.netflix,
    'N',
  ),
  MerchantBrand(
    'JioHotstar',
    ['hotstar', 'jiohotstar', 'disney'],
    null,
    Color(0xFF1F3C88),
    'H',
  ),
  MerchantBrand(
    'Spotify',
    ['spotify'],
    SimpleIcons.spotify,
    SimpleIconColors.spotify,
    'S',
  ),
  MerchantBrand(
    'YouTube Music',
    ['youtube music'],
    SimpleIcons.youtubemusic,
    SimpleIconColors.youtubemusic,
    'Y',
  ),
  MerchantBrand(
    'YouTube',
    ['youtube'],
    SimpleIcons.youtube,
    SimpleIconColors.youtube,
    'Y',
  ),
  MerchantBrand(
    'SonyLIV',
    ['sonyliv', 'sony liv'],
    null,
    Color(0xFF1A1A1A),
    'S',
  ),
  MerchantBrand('ZEE5', ['zee5'], null, Color(0xFF8230C6), 'Z'),
  MerchantBrand('JioCinema', ['jiocinema'], null, Color(0xFFD6247A), 'J'),
  MerchantBrand(
    'BookMyShow',
    ['bookmyshow'],
    SimpleIcons.bookmyshow,
    SimpleIconColors.bookmyshow,
    'B',
  ),
  MerchantBrand('PVR INOX', ['pvr', 'inox'], null, Color(0xFFB8860B), 'P'),
  MerchantBrand('Gaana', ['gaana'], null, Color(0xFFE72C30), 'G'),
  MerchantBrand(
    'Airtel',
    ['airtel'],
    SimpleIcons.airtel,
    SimpleIconColors.airtel,
    'A',
  ),
  MerchantBrand(
    'Jio',
    ['jio', 'reliance jio'],
    SimpleIcons.jio,
    SimpleIconColors.jio,
    'J',
  ),
  MerchantBrand(
    'Vi',
    [
      'vodafone idea',
      'vodafone',
      'vi prepaid',
      'vi postpaid',
      'vi recharge',
      '=vi',
    ],
    SimpleIcons.vodafone,
    SimpleIconColors.vodafone,
    'V',
  ),
  MerchantBrand('BSNL', ['bsnl'], null, Color(0xFF1565A8), 'B'),
  MerchantBrand(
    'Tata Play',
    ['tata play', 'tataplay', 'tata sky', 'tatasky'],
    null,
    Color(0xFFE5007D),
    'T',
  ),
  MerchantBrand('Dish TV', ['dish tv', 'dishtv'], null, Color(0xFFE5460F), 'D'),
  MerchantBrand(
    'ACT Fibernet',
    ['act fibernet', 'actfibernet'],
    null,
    Color(0xFF00A3E0),
    'A',
  ),
  MerchantBrand('Hathway', ['hathway'], null, Color(0xFFEC1C24), 'H'),
  MerchantBrand('BESCOM', ['bescom'], null, Color(0xFFF2B33D), 'B'),
  MerchantBrand('Tata Power', ['tata power'], null, Color(0xFF005DAA), 'T'),
  MerchantBrand(
    'Adani Electricity',
    ['adani electricity', 'adani'],
    null,
    Color(0xFF0B74B8),
    'A',
  ),
  MerchantBrand(
    'PhonePe',
    ['phonepe'],
    SimpleIcons.phonepe,
    SimpleIconColors.phonepe,
    'P',
  ),
  MerchantBrand(
    'Google Pay',
    ['google pay', 'gpay'],
    SimpleIcons.googlepay,
    SimpleIconColors.googlepay,
    'G',
  ),
  MerchantBrand(
    'Paytm',
    ['paytm'],
    SimpleIcons.paytm,
    SimpleIconColors.paytm,
    'P',
  ),
  MerchantBrand('CRED', ['cred'], null, Color(0xFF0D0D0D), 'C'),
  MerchantBrand('BHIM', ['bhim'], null, Color(0xFF00A859), 'B'),
  MerchantBrand('MobiKwik', ['mobikwik'], null, Color(0xFF2E6BE6), 'M'),
  MerchantBrand('Freecharge', ['freecharge'], null, Color(0xFFF36F21), 'F'),
  MerchantBrand(
    'Razorpay',
    ['razorpay'],
    SimpleIcons.razorpay,
    SimpleIconColors.razorpay,
    'R',
  ),
  MerchantBrand(
    'PayPal',
    ['paypal'],
    SimpleIcons.paypal,
    SimpleIconColors.paypal,
    'P',
  ),
  MerchantBrand(
    'HDFC Bank',
    ['hdfc'],
    SimpleIcons.hdfcbank,
    SimpleIconColors.hdfcbank,
    'H',
  ),
  MerchantBrand(
    'ICICI Bank',
    ['icici'],
    SimpleIcons.icicibank,
    SimpleIconColors.icicibank,
    'I',
  ),
  MerchantBrand(
    'Axis Bank',
    ['axis bank', 'axis'],
    SimpleIcons.axisbank,
    SimpleIconColors.axisbank,
    'A',
  ),
  MerchantBrand('SBI', ['sbi', 'state bank'], null, Color(0xFF22409A), 'SBI'),
  MerchantBrand('Kotak', ['kotak'], null, Color(0xFFED1C24), 'K'),
  MerchantBrand(
    'Standard Chartered',
    ['standard chartered', 'stanchart', 'sc bank'],
    null,
    Color(0xFF0473EA),
    'SC',
  ),
  MerchantBrand('Yes Bank', ['yes bank'], null, Color(0xFF0A5AA3), 'Y'),
  MerchantBrand('IDFC FIRST', ['idfc'], null, Color(0xFF9C1D26), 'I'),
  MerchantBrand('IndusInd', ['indusind'], null, Color(0xFF8C1C2D), 'I'),
  MerchantBrand(
    'Bank of Baroda',
    ['bank of baroda', 'bob'],
    null,
    Color(0xFFF26B21),
    'B',
  ),
  MerchantBrand(
    'PNB',
    ['punjab national', 'pnb'],
    null,
    Color(0xFFA20E37),
    'P',
  ),
  MerchantBrand('Canara Bank', ['canara'], null, Color(0xFF00A3DA), 'C'),
  MerchantBrand('Union Bank', ['union bank'], null, Color(0xFFD81921), 'U'),
  MerchantBrand('HSBC', ['hsbc'], SimpleIcons.hsbc, SimpleIconColors.hsbc, 'H'),
  MerchantBrand(
    'Citi',
    ['citibank', 'citi bank', 'citi'],
    null,
    Color(0xFF056DAE),
    'C',
  ),
  MerchantBrand(
    'American Express',
    ['american express', 'amex'],
    SimpleIcons.americanexpress,
    SimpleIconColors.americanexpress,
    'A',
  ),
  MerchantBrand('Federal Bank', ['federal bank'], null, Color(0xFF005BAA), 'F'),
  MerchantBrand('RBL Bank', ['rbl'], null, Color(0xFF1B4DA1), 'R'),
  MerchantBrand(
    'AU Small Finance',
    ['au small finance', 'au bank'],
    null,
    Color(0xFF8B1538),
    'AU',
  ),
  MerchantBrand('Visa', ['visa'], SimpleIcons.visa, SimpleIconColors.visa, 'V'),
  MerchantBrand(
    'Mastercard',
    ['mastercard'],
    SimpleIcons.mastercard,
    SimpleIconColors.mastercard,
    'M',
  ),
  MerchantBrand('Apollo', ['apollo'], null, Color(0xFF0072BC), 'A'),
  MerchantBrand('PharmEasy', ['pharmeasy'], null, Color(0xFF10847E), 'P'),
  MerchantBrand('Tata 1mg', ['1mg'], null, Color(0xFFFF6F61), '1'),
  MerchantBrand('Netmeds', ['netmeds'], null, Color(0xFF24AEB1), 'N'),
  MerchantBrand('Practo', ['practo'], null, Color(0xFF1AA37A), 'P'),
  MerchantBrand(
    'cult.fit',
    ['cult.fit', 'cultfit', 'cult fit'],
    null,
    Color(0xFFFF3C46),
    'c',
  ),
  MerchantBrand('HealthKart', ['healthkart'], null, Color(0xFF8DC63F), 'H'),
  MerchantBrand(
    'Zerodha',
    ['zerodha', 'kite', 'coin by zerodha'],
    SimpleIcons.zerodha,
    SimpleIconColors.zerodha,
    'Z',
  ),
  MerchantBrand('Groww', ['groww'], null, Color(0xFF00D09C), 'G'),
  MerchantBrand('Upstox', ['upstox'], null, Color(0xFF5B2D90), 'U'),
  MerchantBrand('Kuvera', ['kuvera'], null, Color(0xFF0A8A8A), 'K'),
  MerchantBrand('INDmoney', ['indmoney'], null, Color(0xFF1A1A1A), 'I'),
  MerchantBrand(
    'LIC',
    ['lic', 'life insurance corporation'],
    null,
    Color(0xFF0A4C8A),
    'L',
  ),
];

class _Logo {
  const _Logo(this.asset, this.wordmark);
  final String asset;
  final bool wordmark;
}

/// Bundled logo images for brands the icon set doesn't cover, keyed by brand
/// name. Credits and sources: `assets/logos/CREDITS.md`.
const _logoAssets = <String, _Logo>{
  'ACT Fibernet': _Logo('assets/logos/act_fibernet.png', false),
  'AU Small Finance': _Logo('assets/logos/au_small_finance.png', false),
  'Adani Electricity': _Logo('assets/logos/adani_electricity.png', false),
  'Ajio': _Logo('assets/logos/ajio.png', false),
  'Akasa Air': _Logo('assets/logos/akasa_air.png', true),
  'Amazon': _Logo('assets/logos/amazon.png', true),
  'Amazon Pay': _Logo('assets/logos/amazon_pay.png', true),
  'Apollo': _Logo('assets/logos/apollo.png', true),
  'BESCOM': _Logo('assets/logos/bescom.png', false),
  'BHIM': _Logo('assets/logos/bhim.png', true),
  'BSNL': _Logo('assets/logos/bsnl.png', true),
  'Bank of Baroda': _Logo('assets/logos/bank_of_baroda.png', false),
  'Barista': _Logo('assets/logos/barista.png', false),
  'Blinkit': _Logo('assets/logos/blinkit.png', false),
  'CRED': _Logo('assets/logos/cred.png', false),
  'Cafe Coffee Day': _Logo('assets/logos/cafe_coffee_day.png', false),
  'Canara Bank': _Logo('assets/logos/canara_bank.png', false),
  'Chaayos': _Logo('assets/logos/chaayos.png', false),
  'Citi': _Logo('assets/logos/citi.png', true),
  'Cleartrip': _Logo('assets/logos/cleartrip.png', false),
  'Croma': _Logo('assets/logos/croma.png', false),
  'DMart': _Logo('assets/logos/dmart.png', false),
  'Decathlon': _Logo('assets/logos/decathlon.png', false),
  'Dish TV': _Logo('assets/logos/dish_tv.png', true),
  'Domino\'s': _Logo('assets/logos/domino_s.png', true),
  'EatSure': _Logo('assets/logos/eatsure.png', false),
  'FASTag': _Logo('assets/logos/fastag.png', true),
  'Federal Bank': _Logo('assets/logos/federal_bank.png', false),
  'FirstCry': _Logo('assets/logos/firstcry.png', false),
  'Flipkart': _Logo('assets/logos/flipkart.png', false),
  'Freecharge': _Logo('assets/logos/freecharge.png', false),
  'Gaana': _Logo('assets/logos/gaana.png', false),
  'Goibibo': _Logo('assets/logos/goibibo.png', false),
  'Groww': _Logo('assets/logos/groww.png', true),
  'Haldiram\'s': _Logo('assets/logos/haldiram_s.png', false),
  'Hathway': _Logo('assets/logos/hathway.png', true),
  'HealthKart': _Logo('assets/logos/healthkart.png', false),
  'IDFC FIRST': _Logo('assets/logos/idfc_first.png', true),
  'INDmoney': _Logo('assets/logos/indmoney.png', false),
  'IRCTC': _Logo('assets/logos/irctc.png', false),
  'IndusInd': _Logo('assets/logos/indusind.png', false),
  'JioCinema': _Logo('assets/logos/jiocinema.png', true),
  'JioHotstar': _Logo('assets/logos/jiohotstar.png', false),
  'JioMart': _Logo('assets/logos/jiomart.png', true),
  'Kotak': _Logo('assets/logos/kotak.png', false),
  'Kuvera': _Logo('assets/logos/kuvera.png', false),
  'LIC': _Logo('assets/logos/lic.png', true),
  'Lenskart': _Logo('assets/logos/lenskart.png', false),
  'MakeMyTrip': _Logo('assets/logos/makemytrip.png', false),
  'Meesho': _Logo('assets/logos/meesho.png', true),
  'MobiKwik': _Logo('assets/logos/mobikwik.png', false),
  'Myntra': _Logo('assets/logos/myntra.png', true),
  'Netmeds': _Logo('assets/logos/netmeds.png', false),
  'Nykaa': _Logo('assets/logos/nykaa.png', false),
  'Ola': _Logo('assets/logos/ola.png', true),
  'PNB': _Logo('assets/logos/pnb.png', true),
  'PVR INOX': _Logo('assets/logos/pvr_inox.png', false),
  'PharmEasy': _Logo('assets/logos/pharmeasy.png', true),
  'Pizza Hut': _Logo('assets/logos/pizza_hut.png', false),
  'Practo': _Logo('assets/logos/practo.png', false),
  'Prime Video': _Logo('assets/logos/prime_video.png', false),
  'RBL Bank': _Logo('assets/logos/rbl_bank.png', true),
  'Rapido': _Logo('assets/logos/rapido.png', false),
  'Reliance Fresh': _Logo('assets/logos/reliance_fresh.png', false),
  'SBI': _Logo('assets/logos/sbi.png', true),
  'SonyLIV': _Logo('assets/logos/sonyliv.png', false),
  'SpiceJet': _Logo('assets/logos/spicejet.png', false),
  'Standard Chartered': _Logo('assets/logos/standard_chartered.png', false),
  'Subway': _Logo('assets/logos/subway.png', true),
  'Tata 1mg': _Logo('assets/logos/tata_1mg.png', false),
  'Tata CLiQ': _Logo('assets/logos/tata_cliq.png', false),
  'Tata Play': _Logo('assets/logos/tata_play.png', true),
  'Tata Power': _Logo('assets/logos/tata_power.png', true),
  'Union Bank': _Logo('assets/logos/union_bank.png', true),
  'Upstox': _Logo('assets/logos/upstox.png', false),
  'Vistara': _Logo('assets/logos/vistara.png', false),
  'Yes Bank': _Logo('assets/logos/yes_bank.png', true),
  'ZEE5': _Logo('assets/logos/zee5.png', true),
  'Zepto': _Logo('assets/logos/zepto.png', false),
  'cult.fit': _Logo('assets/logos/cult_fit.png', false),
  'ixigo': _Logo('assets/logos/ixigo.png', false),
  'redBus': _Logo('assets/logos/redbus.png', true),
};

/// Keywords match as whole words; one starting with `=` must be the whole
/// merchant name ("=vi" matches "Vi" but not "Vi Cafe").
String _patternFor(List<String> keywords) {
  final loose = [
    for (final k in keywords)
      if (!k.startsWith('=')) RegExp.escape(k),
  ];
  final exact = [
    for (final k in keywords)
      if (k.startsWith('=')) RegExp.escape(k.substring(1)),
  ];
  return [
    if (loose.isNotEmpty) '(?<![a-z0-9])(?:${loose.join('|')})(?![a-z0-9])',
    if (exact.isNotEmpty) '^\\s*(?:${exact.join('|')})\\s*\$',
  ].join('|');
}

final _compiled = [
  for (final brand in _brands)
    (RegExp(_patternFor(brand.keywords), caseSensitive: false), brand),
];

/// The recognised brand in [merchantName], or null.
MerchantBrand? brandFor(String merchantName) {
  for (final (pattern, brand) in _compiled) {
    if (pattern.hasMatch(merchantName)) return brand;
  }
  return null;
}

/// Badge for [merchantName] (e.g. "Swiggy Instamart" → Swiggy's logo on its
/// orange). Null for anything unrecognised, so callers can fall back to the
/// category icon.
MerchantBadgeData? merchantBadgeFor(String merchantName) {
  final brand = brandFor(merchantName);
  if (brand == null) return null;
  final logo = brand.icon == null ? _logoAssets[brand.name] : null;
  return MerchantBadgeData(
    brand.initial,
    brand.color,
    icon: brand.icon,
    name: brand.name,
    asset: logo?.asset,
    wordmark: logo?.wordmark ?? false,
  );
}
