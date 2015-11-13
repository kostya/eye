require 'slack-notifier'

class Eye::Notify::Slack < Eye::Notify

  # Eye.config do
  #   slack :webhook_url => "http://...", :channel => "#default", :username => "eye"
  #   contact :channel, :slack, "@channel"
  # end

  param :webhook_url, String, true
  param :channel,     String, nil, '#default'
  param :username,    String, nil, 'eye'

  param :icon, String

  def execute
    debug { "send slack #{[channel, username]} - #{[contact, message_body]}" }

    options = {
      channel:  channel,
      username: username
    }

    options[:icon_emoji] = icon if icon && icon.start_with?(':')
    options[:icon_url]   = icon if icon && icon.start_with?('http')

    notifier = ::Slack::Notifier.new webhook_url, options

    notifier.ping message_body
  end

  def message_body
    payload = ''
    payload << "#{contact}: *#{msg_host}* _#{msg_full_name}_ at #{Eye::Utils.human_time2(msg_at)}\n"
    payload << "> #{msg_message}"
    payload
  end

end
