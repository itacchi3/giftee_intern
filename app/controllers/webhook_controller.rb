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
          if event['source']['groupId']
            group = Group.find_or_create_by!(group_id: event['source']['groupId'])
            group_score_calc_set = GroupScoreCalcSet.find_or_create_by!(group_id: group.group_id )

            if message_text == "/スタート" && !group.is_measurement_period
              group.is_measurement_period = true
              group.save!
              group_score_calc_set.set_id += 1
              group_score_calc_set.save
              message = {
                type: 'text',
                text: "計測開始"
              }
              client.reply_message(event['replyToken'], message)
            elsif message_text == "/ストップ" && group.is_measurement_period
              group.is_measurement_period = false
              group.save!
              user_id_list = UserScore.where(group_id: group.group_id, set_id: group_score_calc_set.set_id).pluck(:user_id).uniq

              reply_text = "結果発表"
              max_score = 0
              user_id_list.each { |user_id|
                user_name = JSON.parse(client.get_group_member_profile(group.group_id, user_id).body)["displayName"]
                scores = UserScore.where(group_id: group.group_id, set_id: group_score_calc_set.set_id, user_id: user_id).pluck(:score)
                score_ave = scores.sum.fdiv(scores.length).to_i

                reply_text += "\n#{user_name}さん: #{score_ave}点"
              }

              message = {
                type: 'text',
                text: reply_text
              }
              client.reply_message(event['replyToken'], message)
            else
              if group.is_measurement_period
                google_cloud_language_client = GoogleCloudLanguageClient.new
                response = google_cloud_language_client.analyze_sentiment(text: event.message['text'])
                score = response.document_sentiment.score.to_f.round(1) * 100
                UserScore.create!(group_id: event['source']['groupId'], set_id: group_score_calc_set.set_id, user_id: event['source']['userId'], score: score)
              end
            end
          else
            google_cloud_language_client = GoogleCloudLanguageClient.new
            response = google_cloud_language_client.analyze_sentiment(text: message_text)
            score = response.document_sentiment.score.to_f.round(1) * 100
            message = {
              type: 'text',
              text: "ポジティブ度: #{score.to_i}点"
            }
            client.reply_message(event['replyToken'], message)
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
