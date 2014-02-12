# Irclog

これは、 [tiarra](http://www.clovery.jp/tiarra/)
で取ったログを web 上で見るための cgi です。
kick や op を剥奪したのを見れるのが特徴です。
ruby1.9 以降がインストールされていれば動くと思います。

自分の発言したログを見るためには、 tiarra の Log::Channel の
distinguish-myself を 0 にしておく必要があります。
（簡単に直せますが、面倒臭いので放置しています。）

検索機能は安全ではないので、信頼できる限られた人しか見れない
場所に cgi を設置することをおすすめします。
