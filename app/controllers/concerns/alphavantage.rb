module Alphavantage extend ActiveSupport::Concern
  #
  # See the bottom of this file for sample data.
  #
  # Make data request(s) for symbols and return results in trades.
  def fillTrades(symbols, trades)
    begin
      # TODO put conn creation in session variable to cut overhead?
      conn = Faraday.new(url: 'https://www.alphavantage.co/query')
    rescue Faraday::ClientError => e  # Can't connect. Error out all symbols.
      puts "AA PRICE FETCH ERROR for: #{symbols.inspect}"
      errorMsg = "Faraday client error: #{e}"
      fetch_failure(symbols, trades, errorMsg)
    end

    api_key = ENV['ALPHA_VANTAGE_API_KEY']
    fetchTime = DateTime.now

    symbols.each_with_index { |symbol, i|
      begin
        puts "AA PRICE FETCH BEGIN for: #{symbol}"
        resp = conn.get do |req|
          req.params['function'] = 'TIME_SERIES_DAILY'
          req.params['symbol']   = symbol
          req.params['apikey']   = api_key
        end
        puts "AA PRICE FETCH END   for: #{symbol}"
        response = JSON.parse(resp.body)
      rescue Faraday::ClientError => e
        puts "AA PRICE FETCH ERROR for: #{symbolList}: Faraday client error: #{e}"
        fetch_failure(symbols, trades, 'The feed is down.')
      rescue JSON::ParserError => e
        puts "AA PRICE FETCH ERROR for: #{symbolList}: JSON parse error: #{e}"
        fetch_failure(symbols, trades, 'The feed is down.')
      else
        #
        # Error example:
        #   {"Error Message"=>"Invalid API call. Please retry or visit the documentation (https://www.alphavantage.co/documentation/) for TIME_SERIES_INTRADAY."}
        #
        if response.key?('Error Message') || response.length == 0
          puts "AA PRICE FETCH ERROR for: #{symbol}: #{response['Error Message']}"
          trade = error_trade(symbol, 'Price is not available.')
        else
          header = response['Meta Data']
          ticks = response['Time Series (Daily)']
          current_trade_price = ticks.values[0]['4. close'].to_f.round(4)
          prior_trade_price = ticks.values[1]['4. close'].to_f.round(4)

          # TODO Get timezone from Meta Data.
          trade = Trade.new do |t|
            t.stock_symbol = StockSymbol.find_by(name: symbol)
            t.trade_date   = Date.new(missing_trade_date).to_f/1000.0).round(4).to_datetime
            t.trade_price  = current_trade_price
            t.price_change = (current_trade_price - prior_trade_price).round(4)
            t.created_at   = fetchTime
          end
          trades[i] = trade
        end
      end
    }
  end

  # Return the feed's list if valid symbols.
  def getSymbology()
    puts 'AA SYMBOLOGY FETCH BEGIN'
    puts 'AA SYMBOLOGY FETCH END'
    return {}
  end
end

###################
##  SAMPLE DATA  ##
###################
#
# INTRADAY:
# https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=MSFT&interval=1min&apikey=demo
# {
#   "Meta Data"=>
#   {
#     "1. Information"=>"Intraday (1min) prices and volumes",
#     "2. Symbol"=>"MSFT",
#     "3. Last Refreshed"=>"2017-10-20 16:00:00",
#     "4. Interval"=>"1min",
#     "5. Output Size"=>"Compact",
#     "6. Time Zone"=>"US/Eastern"
#   },
#   "Time Series (1min)"=>
#   {
#     "2017-10-20 16:00:00"=>
#     {
#       "1. open"=>"78.7000",
#       "2. high"=>"78.8100",
#       "3. low"=>"78.6950",
#       "4. close"=>"78.8100",
#       "5. volume"=>"2663315"
#     },
#     "2017-10-20 15:59:00"=>
#     {
#       "1. open"=>"78.7000",
#       "2. high"=>"78.7200",
#       "3. low"=>"78.6900",
#       "4. close"=>"78.7000",
#       "5. volume"=>"320215"
#     },
#     .
#     .
#     .
#   }
# }
#
# DAILY:
# https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=MSFT&apikey=demo
# {
#   "Meta Data"=>
#   {
#    "1. Information	"Daily Prices (open, high, low, close) and Volumes"
#    "2. Symbol	"MSFT"
#    "3. Last Refreshed	"2017-11-02 11:46:00"
#    "4. Output Size	"Compact"
#    "5. Time Zone	"US/Eastern"
#   },
#   "Time Series (Daily)"=>
#   {
#    "2017-11-02"=>
#    {
#      "1. open	"83.3500"
#      "2. high	"84.0300"
#      "3. low	"83.1200"
#      "4. close	"83.5500"
#      "5. volume	"8642391"
#    },
#    "2017-11-01"=>
#    {
#     "1. open	"83.6800"
#     "2. high	"83.7600"
#     "3. low	"82.8800"
#     "4. close	"83.1800"
#     "5. volume	"22039635"
#    },
#     .
#     .
#     .
#   }
# }
