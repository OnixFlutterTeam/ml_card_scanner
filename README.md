# ml_ card_scanner

The ml_ card_scanner plugin allows you to scan bank cards of different types: horizontal or vertical  

## Features


- Powered by Google's Machine Learning models
- Great performance and accuracy
- Fully OFFLINE scan makes it a completely secure scanner.
- Can scan expiration date, card type and card number 

## Prepare

IOS

info.list

<pre><code>&lt;key&gt;NSCameraUsageDescription&lt;/key&gt;
&lt;string&gt;Your Description&lt;/string&gt;

&lt;key&gt;io.flutter.embedded_views_preview&lt;/key&gt;
&lt;string&gt;YES&lt;/string&gt;
</code></pre>

## Usage

<p>Just import the package and call <code>ml_card_scanner</code>:</p>
<pre><code class="language-dart">import 'package:ml_card_scanner/ml_card_scanner.dart';
var cardInfo = await MlCardScanner.scanCard()

print(cardInfo)
</code></pre>
<p>Example Output:</p>
<pre><code class="language-dart">Number card: 5173949390587465
Type: Master Card
Expiry: 10/24
</code></pre>
<p>The above code opens the device camera, looks for a valid card and gets the required details and returns the <code> CardInfo </code> object.</p>
<hr />

<h3 class="hash-header" id="scan-options">Scan Options <a href="#scan-options" class="hash-link"></a></h3>
<p>If you wish to obtain the card holder name and card issuer, you can specify the options:</p>
<pre><code class="language-dart">import 'package:ml_card_scanner/ml_card_scanner.dart';
 CardInfo? cardInfo = await MlCardScanner.scanCard(context,
        cardOrientation: CardOrientation.landscape,
        overlayBorderRadius: 50,
        overlayColorFilter: Colors.cyan.withOpacity(0.4),
        overlayText: "Scanner card",
        scannerDelay: 600,
        routes: Routes.cupertinoPageRoute);
    print('Card Parsed: ${cardInfo.toString()}');

</code></pre>
<p>Example Output :</p>
<pre><code class="language-dart">Number card: 5173949390587465
Type: Master Card
Expiry: 10/24
</code></pre>
