class Api::V1::Accounts::Contacts::GroupSettingsController < Api::V1::Accounts::Contacts::BaseController
  def leave
    authorize @contact, :update?
    channel.group_leave(@contact.identifier)
    resolve_group_conversations
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    authorize @contact, :update?
    setting = setting_params[:setting]
    valid_settings = %w[announcement not_announcement locked unlocked]
    return render json: { error: 'invalid_setting' }, status: :unprocessable_entity unless setting.in?(valid_settings)

    channel.group_setting_update(@contact.identifier, setting)
    update_contact_setting(setting)
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def toggle_join_approval
    authorize @contact, :update?
    mode = join_approval_params[:mode]
    return render json: { error: 'invalid_mode' }, status: :unprocessable_entity unless mode.in?(%w[on off])

    channel.group_join_approval_mode(@contact.identifier, mode)
    update_contact_attribute('join_approval_mode', mode == 'on')
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def setting_params
    params.permit(:setting)
  end

  def join_approval_params
    params.permit(:mode)
  end

  def channel
    @channel ||= @contact.group_channel
  end

  def resolve_group_conversations
    Current.account.conversations
           .where(contact_id: @contact.id, group_type: :group, status: %i[open pending])
           .find_each { |c| c.update!(status: :resolved) }
  end

  def update_contact_setting(setting)
    case setting
    when 'announcement'
      update_contact_attribute('announce', true)
    when 'not_announcement'
      update_contact_attribute('announce', false)
    when 'locked'
      update_contact_attribute('restrict', true)
    when 'unlocked'
      update_contact_attribute('restrict', false)
    end
  end

  def update_contact_attribute(key, value)
    new_attrs = (@contact.additional_attributes || {}).merge(key => value)
    @contact.update!(additional_attributes: new_attrs)
  end
end
