class Whatsapp::MentionConverterService
  MENTION_REGEX = %r{\[@([^\]]+)\]\(mention://contact/(\d+)/([^)]+)\)}
  ALL_MENTION_REGEX = %r{\[@[^\]]*\]\(mention://contact/0/all\)}
  INCOMING_ALL_PATTERNS = /@(all|todos|everyone)/i

  class << self
    def extract_mentions_for_whatsapp(content, account)
      return {} if content.blank?

      mentions = collect_mention_jids(content, account)
      result = {}
      result[:mentions] = mentions if mentions.present?
      result[:groupMentions] = [{ groupSubject: 'everyone' }] if ALL_MENTION_REGEX.match?(content)
      result
    end

    def convert_incoming_mentions(text, context_info, account, inbox)
      return text if text.blank? || context_info.blank?

      result = convert_jid_mentions(text.dup, context_info, account, inbox)
      convert_group_mentions(result, context_info)
    end

    private

    def collect_mention_jids(content, account)
      jids = content.scan(MENTION_REGEX).filter_map do |_name, id, _encoded_name|
        next if id == '0'

        contact = account.contacts.find_by(id: id)
        next if contact&.phone_number.blank?

        "#{contact.phone_number.delete('+')}@s.whatsapp.net"
      end

      jids.uniq
    end

    def convert_jid_mentions(text, context_info, account, inbox)
      mentioned_jids = context_info[:mentionedJid] || context_info['mentionedJid']
      return text if mentioned_jids.blank?

      inbox_phone = inbox.phone_number&.delete('+')
      mentioned_jids.each_with_object(text) do |jid, result|
        phone = jid.sub(/@s\.whatsapp\.net$/, '')
        next if inbox_phone.present? && phone == inbox_phone

        apply_jid_mention(result, phone, account)
      end
    end

    def apply_jid_mention(text, phone, account)
      contact = find_contact_by_phone(phone, account)
      return text unless contact

      display_name = contact.name.presence || phone
      encoded_name = ERB::Util.url_encode(display_name)
      mention_uri = "[@#{display_name}](mention://contact/#{contact.id}/#{encoded_name})"

      replace_mention_in_text(text, phone, display_name, mention_uri)
    end

    def convert_group_mentions(text, context_info)
      group_mentions = context_info[:groupMentions] || context_info['groupMentions']
      return text if group_mentions.blank?

      text.gsub(INCOMING_ALL_PATTERNS, '[@all](mention://contact/0/all)')
    end

    def find_contact_by_phone(phone, account)
      # Try exact match first
      contact = account.contacts.find_by(phone_number: phone)
      contact ||= account.contacts.find_by(phone_number: "+#{phone}")

      # Brazilian number fallback: try last 8 digits
      if contact.nil? && phone.length >= 8
        last_digits = phone[-8..]
        contact = account.contacts.where('phone_number LIKE ?', "%#{last_digits}").first
      end

      contact
    end

    def replace_mention_in_text(text, phone, display_name, mention_uri)
      # Try @phone first, then @DisplayName
      patterns = [
        /@#{Regexp.escape(phone)}/,
        /@#{Regexp.escape(display_name)}/i
      ]

      patterns.each do |pattern|
        return text.sub(pattern, mention_uri) if text.match?(pattern)
      end

      text
    end
  end
end
