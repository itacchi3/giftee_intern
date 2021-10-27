require 'line/bot'
require 'google/cloud/language'

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
          if event.message['text'].start_with?("/")
            message = {
              type: 'text',
              text: 'コマンド'
            }
          else
            Google::Cloud::Language.configure do |config|
              config.credentials = {
                "type": Rails.application.credentials.gcp[:type],
                "project_id": Rails.application.credentials.gcp[:project_id],
                "private_key_id": Rails.application.credentials.gcp[:private_key_id],
                "private_key": Rails.application.credentials.gcp[:private_key],
                "client_email": Rails.application.credentials.gcp[:client_email],
                "client_id": Rails.application.credentials.gcp[:client_id],
                "auth_uri": Rails.application.credentials.gcp[:auth_uri],
                "token_uri": Rails.application.credentials.gcp[:token_uri],
                "auth_provider_x509_cert_url": Rails.application.credentials.gcp[:auth_provider_x509_cert_url],
                "client_x509_cert_url": Rails.application.credentials.gcp[:client_x509_cert_url]
              }
            end

            language = Google::Cloud::Language.language_service
            document = {
              content: event.message['text'],
              type: Google::Cloud::Language::V1::Document::Type::PLAIN_TEXT
            }
            response = language.analyze_sentiment document: document
            sentiment = response.document_sentiment

            score = sentiment.score.to_f.round(1)

            message = {
              type: 'text',
              text: "ポジティブ度: #{score}"
            }
          end

          client.reply_message(event['replyToken'], message)

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
