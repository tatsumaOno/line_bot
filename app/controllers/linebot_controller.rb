class LinebotController < ApplicationController
  require 'line/bot' #gem 'line-bot-api'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new {|config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
    #@clientが未定義なら右の値を代入する
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|
      if event.message['text'] != nil
        place = event.message['text']
        result = `curl -X GET http://api.gnavi.co.jp/RestSearchAPI/v3/?keyid=cfd5d3e8f916854a281f3a186a0f23c6
'&'address=#{place}`
      else
        latitude = event.message['latitude']
        longitude = event.message['longitude']
        result = `curl -X GET http://api.gnavi.co.jp/RestSearchAPI/v3/?keyid=cfd5d3e8f916854a281f3a186a0f23c6
'&'format=json'&'latitude=#{latitude}'&'longitude=#{longitude}`
      end

      hash_result = JSON.parse result
      shops = hash_result["rest"]
      shop = shops.sample
      url = shop["url_mobile"]
      shop_name = shop["name"]
      category = shop["category"]

      response = "[店名]"+shop_name + "\n"+"[カテゴリー]"+category+"\n"+url
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text,Line::Bot::Event::MessageType::Location

          message = {
            type: 'text',
            text: response
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }

    head :ok
  end
end
