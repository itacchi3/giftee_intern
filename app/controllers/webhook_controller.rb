require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = Rails.application.credentials.linebot[:LINE_CHANNEL_SECRET]
      config.channel_token = Rails.application.credentials.linebot[:LINE_CHANNEL_TOKEN]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message_text = event.message['text']
          group = Group.find_or_create_by!(group_id: event['source']['groupId'])

          if message_text === "/スタート"
            group.is_measurement_period = true
            group.save!
            message = {
              type: 'text',
              text: "計測開始"
            }
            client.reply_message(event['replyToken'], message)
          elsif message_text === "/ストップ"
            group.is_measurement_period = false
            group.save!
            message = {
              type: 'text',
              text: "計測停止"
            }
            client.reply_message(event['replyToken'], message)
          else
            if group.is_measurement_period
              google_cloud_language_client = GoogleCloudLanguageClient.new
              response = google_cloud_language_client.analyze_sentiment(text: message_text)
              score = response.document_sentiment.score.to_f.round(1)
              message = {
                type: 'text',
                text: "ポジティブ度: #{score}"
              }
              client.reply_message(event['replyToken'], message)
            end
          end

        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    head :ok
  end
end
