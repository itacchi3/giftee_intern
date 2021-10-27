require "google/cloud/language"

class GoogleCloudLanguageClient
  def initialize
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

    @client = Google::Cloud::Language.language_service
  end

  def analyze_sentiment(text:)
    document = {
      content: text,
      type: Google::Cloud::Language::V1::Document::Type::PLAIN_TEXT
    }
    @client.analyze_sentiment document: document
  end
end